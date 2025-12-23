import '../core/middleware.dart';

/// Log levels for the logger middleware.
///
/// Controls the verbosity of logging output. Higher levels include all lower levels.
/// - [debug]: Most verbose, includes all request/response details
/// - [info]: Standard logging with request method, path, status, and timing
/// - [warn]: Only warning and error messages
/// - [error]: Only error messages
enum LogLevel {
  debug,
  info,
  warn,
  error,
}

/// Logger middleware that logs HTTP requests and responses with configurable detail levels.
///
/// Provides comprehensive logging capabilities for debugging and monitoring HTTP traffic.
/// Supports different log levels, optional request/response body logging, header logging,
/// and path-based filtering.
///
/// Example:
/// ```dart
/// // Basic request logging
/// app.use(logger());
///
/// // Detailed logging for development
/// app.use(logger(
///   level: LogLevel.debug,
///   logBody: true,
///   logHeaders: true,
/// ));
///
/// // Production logging with path filtering
/// app.use(logger(
///   level: LogLevel.info,
///   skipPaths: ['/health', '/favicon.ico'],
/// ));
///
/// // Use predefined loggers
/// app.use(devLogger()); // Development with full details
/// app.use(compactLogger()); // Minimal production logging
/// ```
///
/// Output format:
/// ```
/// [12:34:56.789] --> GET /api/users
/// [12:34:56.823] <-- GET /api/users 200 34ms
/// ```
///
/// Features:
/// - Color-coded status codes (green=2xx, cyan=3xx, yellow=4xx, red=5xx)
/// - Request timing measurement
/// - Optional request/response body logging
/// - Optional header logging with sanitization
/// - Path-based filtering to skip uninteresting requests
/// - Graceful error handling that doesn't break request processing
///
/// [level] Minimum log level to output. Defaults to [LogLevel.info].
/// [logBody] Whether to log request bodies. Only for non-GET/HEAD methods.
/// [logHeaders] Whether to log request headers.
/// [skipPaths] List of paths to skip logging for (useful for health checks).
///
/// Returns a [Middleware] function that logs requests and responses.
///
/// Note: Body logging is automatically skipped for GET and HEAD requests.
/// Large request bodies are truncated to prevent console spam.
Middleware logger({
  LogLevel level = LogLevel.info,
  bool logBody = false,
  bool logHeaders = false,
  List<String>? skipPaths,
}) {
  return (req, res, next) async {
    final startTime = DateTime.now();

    // Check if we should skip logging for this path
    if (skipPaths != null && skipPaths.contains(req.path)) {
      await next();
      return;
    }

    // Log request start
    if (level.index <= LogLevel.info.index) {
      final timestamp = _formatTimestamp(startTime);
      print('[$timestamp] --> ${req.method} ${req.path}');

      if (logHeaders) {
        print('    Headers: ${_formatHeaders(req.headers)}');
      }

      if (logBody && req.method != 'GET' && req.method != 'HEAD') {
        try {
          final body = await req.rawBody;
          if (body.isNotEmpty) {
            print('    Body: ${_truncateBody(body)}');
          }
        } catch (e) {
          print('    Body: [Error reading body: $e]');
        }
      }
    }

    // Store original response status for logging
    int? responseStatus;

    try {
      await next();
      responseStatus = res.statusCode;
    } catch (e) {
      responseStatus = 500;
      rethrow;
    } finally {
      // Log response
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      if (level.index <= LogLevel.info.index) {
        final timestamp = _formatTimestamp(endTime);
        final statusColor = _getStatusColor(responseStatus ?? 500);

        print('[$timestamp] <-- ${req.method} ${req.path} '
            '$statusColor${responseStatus ?? 500}\x1b[0m '
            '${duration.inMilliseconds}ms');
      }
    }
  };
}

/// Compact logger that only logs method, path, status, and timing.
///
/// Provides minimal logging output suitable for production environments
/// where you need basic request monitoring without verbose details.
///
/// Output format:
/// ```
/// GET /api/users - 200 34ms
/// POST /api/login - 401 12ms
/// ```
///
/// Example:
/// ```dart
/// // Production logging
/// app.use(compactLogger());
/// ```
///
/// Returns a [Middleware] function with minimal logging output.
Middleware compactLogger() {
  return (req, res, next) async {
    final startTime = DateTime.now();

    try {
      await next();

      final duration = DateTime.now().difference(startTime);
      final statusColor = _getStatusColor(res.statusCode);

      print('${req.method} ${req.path} - '
          '$statusColor${res.statusCode}\x1b[0m '
          '${duration.inMilliseconds}ms');
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      print('${req.method} ${req.path} - '
          '\x1b[91m500\x1b[0m '
          '${duration.inMilliseconds}ms');
      rethrow;
    }
  };
}

/// Development logger with detailed information including bodies and headers.
///
/// Convenience function that enables comprehensive logging for development
/// environments. Includes request bodies, headers, and skips common
/// development noise like favicon requests.
///
/// Example:
/// ```dart
/// // Development setup
/// if (isDevelopment) {
///   app.use(devLogger());
/// }
/// ```
///
/// This is equivalent to:
/// ```dart
/// logger(
///   level: LogLevel.debug,
///   logBody: true,
///   logHeaders: true,
///   skipPaths: ['/favicon.ico'],
/// )
/// ```
///
/// Returns a [Middleware] function configured for development debugging.
Middleware devLogger() {
  return logger(
    level: LogLevel.debug,
    logBody: true,
    logHeaders: true,
    skipPaths: ['/favicon.ico'],
  );
}

/// Format timestamp for logging to HH:mm:ss.SSS format.
///
/// [time] The DateTime to format.
/// Returns a string in HH:mm:ss.SSS format suitable for log output.
String _formatTimestamp(DateTime time) {
  return time.toIso8601String().substring(11, 23); // HH:mm:ss.SSS
}

/// Get ANSI color code for HTTP status codes.
///
/// Provides color-coded output for better visual parsing of logs:
/// - Green (2xx): Successful responses
/// - Cyan (3xx): Redirection responses
/// - Yellow (4xx): Client error responses
/// - Red (5xx): Server error responses
///
/// [status] The HTTP status code.
/// Returns an ANSI escape code string for terminal colors.
String _getStatusColor(int status) {
  if (status >= 200 && status < 300) {
    return '\x1b[92m'; // Green
  } else if (status >= 300 && status < 400) {
    return '\x1b[96m'; // Cyan
  } else if (status >= 400 && status < 500) {
    return '\x1b[93m'; // Yellow
  } else {
    return '\x1b[91m'; // Red
  }
}

/// Format headers for logging output.
///
/// Converts HTTP headers to a readable string format for debugging.
/// Multiple values for the same header are joined with commas.
///
/// [headers] The HTTP headers object from the request.
/// Returns a string representation of all headers.
String _formatHeaders(headers) {
  final headerMap = <String, String>{};
  headers.forEach((name, values) {
    headerMap[name] = values.join(', ');
  });
  return headerMap.toString();
}

/// Truncate request body for logging to prevent console spam.
///
/// Large request bodies can overwhelm log output, so this function
/// truncates them to a reasonable size for debugging purposes.
///
/// [body] The request body string to potentially truncate.
/// [maxLength] Maximum length before truncation. Defaults to 500 characters.
/// Returns the original body if under limit, or truncated version with indicator.
String _truncateBody(String body, {int maxLength = 500}) {
  if (body.length <= maxLength) return body;
  return '${body.substring(0, maxLength)}... [truncated]';
}
