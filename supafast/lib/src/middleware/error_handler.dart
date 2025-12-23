import '../core/middleware.dart';
import '../exceptions/http_exception.dart';
import '../exceptions/supafast_exception.dart';

/// Configuration options for the error handler middleware.
///
/// Controls how errors are processed, logged, and returned to clients.
/// Provides flexibility for different environments and security requirements.
///
/// Example:
/// ```dart
/// // Development configuration with detailed errors
/// final devOptions = ErrorHandlerOptions(
///   stackTrace: true,
///   log: true,
///   formatter: (error, stackTrace) => {
///     'error': error.toString(),
///     'stack': stackTrace.toString(),
///     'timestamp': DateTime.now().toIso8601String(),
///   },
/// );
///
/// // Production configuration with minimal error exposure
/// final prodOptions = ErrorHandlerOptions(
///   stackTrace: false,
///   log: true,
///   statusCodes: {
///     CustomBusinessException: 422,
///     RateLimitException: 429,
///   },
/// );
/// ```
class ErrorHandlerOptions {
  /// Whether to include stack traces in error responses.
  ///
  /// Stack traces can be useful for debugging but should be disabled
  /// in production to avoid exposing internal implementation details.
  final bool stackTrace;

  /// Whether to log errors to console.
  ///
  /// Error logging is generally recommended for monitoring and debugging,
  /// even in production environments.
  final bool log;

  /// Custom status codes for specific exception types.
  ///
  /// Allows mapping custom exception classes to specific HTTP status codes.
  /// Useful for business logic exceptions that should return specific errors.
  ///
  /// Example: `{ValidationException: 422, RateLimitException: 429}`
  final Map<Type, int> statusCodes;

  /// Custom error response formatter.
  ///
  /// Function that takes an error and optional stack trace and returns
  /// a custom response structure. If null, uses the default formatter.
  ///
  /// The function signature is:
  /// `Map<String, dynamic> Function(dynamic error, StackTrace? stackTrace)?`
  final Map<String, dynamic> Function(dynamic error, StackTrace? stackTrace)?
      formatter;

  /// Creates error handler options with the specified configuration.
  ///
  /// [stackTrace] Whether to include stack traces in responses (default: false).
  /// [log] Whether to log errors to console (default: true).
  /// [statusCodes] Custom status code mappings for exception types.
  /// [formatter] Custom error response formatter function.
  const ErrorHandlerOptions({
    this.stackTrace = false,
    this.log = true,
    this.statusCodes = const {},
    this.formatter,
  });
}

/// Error handler middleware that catches and formats errors with customizable options.
///
/// Provides comprehensive error handling for Supafast applications, including
/// automatic status code mapping, error logging, stack trace handling, and
/// customizable error response formatting.
///
/// This middleware should typically be added early in the middleware stack
/// to catch errors from all subsequent middleware and route handlers.
///
/// Example:
/// ```dart
/// // Basic error handling
/// app.use(errorHandler());
///
/// // Development setup with detailed errors
/// app.use(devErrorHandler());
///
/// // Production setup with minimal error exposure
/// app.use(prodErrorHandler());
///
/// // Custom error handling
/// app.use(errorHandler(ErrorHandlerOptions(
///   stackTrace: false,
///   log: true,
///   statusCodes: {
///     ValidationException: 422,
///     AuthenticationException: 401,
///   },
///   formatter: (error, stackTrace) => {
///     'success': false,
///     'message': error.toString(),
///     'code': _getErrorCode(error),
///   },
/// )));
/// ```
///
/// Error type handling:
/// - [HttpException]: Uses the exception's status code and message
/// - [SupafastException]: Returns 500 with the exception's message
/// - [FormatException]: Returns 400 (Bad Request)
/// - [ArgumentError]: Returns 400 (Bad Request)
/// - Custom exceptions: Uses statusCodes mapping or defaults to 500
///
/// Response format (default):
/// ```json
/// {
///   "error": "Bad Request",
///   "message": "Invalid JSON format",
///   "statusCode": 400,
///   "stackTrace": [...] // Only if stackTrace is enabled
/// }
/// ```
///
/// Features:
/// - Automatic status code determination based on error type
/// - Optional stack trace inclusion for debugging
/// - Customizable error response formatting
/// - Graceful handling when response is already sent
/// - Fallback mechanisms for edge cases
///
/// [options] Configuration options for error handling behavior.
///
/// Returns a [Middleware] function that handles errors.
///
/// Note: This middleware catches all errors and prevents them from
/// propagating further up the stack.
Middleware errorHandler([ErrorHandlerOptions? options]) {
  final opts = options ?? const ErrorHandlerOptions();

  return (req, res, next) async {
    try {
      await next();
    } catch (error, stackTrace) {
      // Log error if enabled
      if (opts.log) {
        print('Error in ${req.method} ${req.path}: $error');
        if (opts.stackTrace) {
          print('Stack trace: $stackTrace');
        }
      }

      // Don't send error response if already sent
      if (res.sent) {
        return;
      }

      // Determine status code
      int statusCode = 500;
      String message = 'Internal Server Error';

      if (error is HttpException) {
        statusCode = error.statusCode;
        message = error.message;
      } else if (error is SupafastException) {
        statusCode = 500;
        message = error.message;
      } else if (error is FormatException) {
        statusCode = 400;
        message = 'Bad Request: ${error.message}';
      } else if (error is ArgumentError) {
        statusCode = 400;
        message = 'Bad Request: ${error.message}';
      } else {
        // Check custom status codes
        final customStatusCode = opts.statusCodes[error.runtimeType];
        if (customStatusCode != null) {
          statusCode = customStatusCode;
          message = error.toString();
        } else {
          message = 'Internal Server Error';
        }
      }

      // Build error response
      Map<String, dynamic> errorResponse;

      if (opts.formatter != null) {
        errorResponse = opts.formatter!(error, stackTrace);
      } else {
        errorResponse = {
          'error': _getErrorType(statusCode),
          'message': message,
          'statusCode': statusCode,
        };

        // Add stack trace if enabled
        if (opts.stackTrace) {
          errorResponse['stackTrace'] = stackTrace.toString().split('\n');
        }

        // Add error details for HttpException
        if (error is HttpException && error.details != null) {
          errorResponse['details'] = error.details;
        }
      }

      // Send error response
      try {
        await res.status(statusCode).json(errorResponse);
      } catch (e) {
        // Fallback if JSON response fails
        try {
          await res.status(statusCode).send(message);
        } catch (_) {
          // Last resort - just close the response
          await res.close();
        }
      }
    }
  };
}

/// Development error handler with stack traces and verbose logging.
///
/// Convenience function for development environments where detailed
/// error information is needed for debugging. Includes stack traces
/// and comprehensive error logging.
///
/// Example:
/// ```dart
/// // Development setup
/// if (isDevelopment) {
///   app.use(devErrorHandler());
/// }
/// ```
///
/// Equivalent to:
/// ```dart
/// errorHandler(ErrorHandlerOptions(
///   stackTrace: true,
///   log: true,
/// ))
/// ```
///
/// Returns a [Middleware] configured for development debugging.
Middleware devErrorHandler() {
  return errorHandler(const ErrorHandlerOptions(
    stackTrace: true,
    log: true,
  ));
}

/// Production error handler without stack traces but with error logging.
///
/// Convenience function for production environments where security
/// is important but error monitoring is still needed. Excludes stack
/// traces to prevent information leakage while maintaining error logs.
///
/// Example:
/// ```dart
/// // Production setup
/// if (isProduction) {
///   app.use(prodErrorHandler());
/// }
/// ```
///
/// Equivalent to:
/// ```dart
/// errorHandler(ErrorHandlerOptions(
///   stackTrace: false,
///   log: true,
/// ))
/// ```
///
/// Returns a [Middleware] configured for production use.
Middleware prodErrorHandler() {
  return errorHandler(const ErrorHandlerOptions(
    stackTrace: false,
    log: true,
  ));
}

/// Silent error handler that suppresses error logging.
///
/// Convenience function for scenarios where error logging is not
/// desired, such as testing or when using external error monitoring
/// systems that handle logging separately.
///
/// Example:
/// ```dart
/// // Testing setup
/// if (isTesting) {
///   app.use(silentErrorHandler());
/// }
/// ```
///
/// Equivalent to:
/// ```dart
/// errorHandler(ErrorHandlerOptions(
///   stackTrace: false,
///   log: false,
/// ))
/// ```
///
/// Returns a [Middleware] that handles errors silently.
Middleware silentErrorHandler() {
  return errorHandler(const ErrorHandlerOptions(
    stackTrace: false,
    log: false,
  ));
}

/// Get standard error type string based on HTTP status code.
///
/// Maps common HTTP status codes to their standard error type names
/// for use in error responses. This provides consistent error naming
/// across the application.
///
/// [statusCode] The HTTP status code to map.
/// Returns the standard error type name for the status code.
///
/// Supported status codes:
/// - 400: Bad Request
/// - 401: Unauthorized
/// - 403: Forbidden
/// - 404: Not Found
/// - 409: Conflict
/// - 422: Unprocessable Entity
/// - 429: Too Many Requests
/// - 500: Internal Server Error
/// - 501: Not Implemented
/// - 502: Bad Gateway
/// - 503: Service Unavailable
/// - Others: Generic "Error"
String _getErrorType(int statusCode) {
  switch (statusCode) {
    case 400:
      return 'Bad Request';
    case 401:
      return 'Unauthorized';
    case 403:
      return 'Forbidden';
    case 404:
      return 'Not Found';
    case 409:
      return 'Conflict';
    case 422:
      return 'Unprocessable Entity';
    case 429:
      return 'Too Many Requests';
    case 500:
      return 'Internal Server Error';
    case 501:
      return 'Not Implemented';
    case 502:
      return 'Bad Gateway';
    case 503:
      return 'Service Unavailable';
    default:
      return 'Error';
  }
}
