import 'supafast_exception.dart';

/// HTTP-specific exception that includes an HTTP status code.
///
/// This exception is used throughout the Supafast framework to represent
/// HTTP errors that should be returned to clients with specific status codes.
/// It extends [SupafastException] to maintain consistency with the framework's
/// error handling approach.
///
/// ## Usage
///
/// Throw HTTP exceptions in route handlers or middleware:
///
/// ```dart
/// app.get('/users/:id', (req, res) async {
///   final userId = req.params['id'];
///   if (userId == null) {
///     throw HttpException.badRequest('User ID is required');
///   }
///
///   final user = await userService.findById(userId);
///   if (user == null) {
///     throw HttpException.notFound('User not found');
///   }
///
///   await res.json(user);
/// });
/// ```
///
/// ## Error Handling
///
/// HTTP exceptions are automatically caught by error handling middleware
/// and converted to appropriate HTTP responses:
///
/// ```dart
/// app.use(errorHandler()); // Handles HttpException automatically
/// ```
class HttpException extends SupafastException {
  /// The HTTP status code associated with this exception.
  ///
  /// This status code will be used when sending the error response
  /// to the client.
  final int statusCode;

  /// Creates a new HttpException.
  ///
  /// [statusCode] The HTTP status code (e.g., 400, 404, 500)
  /// [message] A descriptive error message
  /// [details] Optional additional error details
  const HttpException(this.statusCode, String message, [dynamic details])
      : super(message, details);

  /// Create a 400 Bad Request exception.
  ///
  /// Used when the client sends an invalid request.
  ///
  /// [message] Custom error message (default: 'Bad Request')
  ///
  /// Example:
  /// ```dart
  /// throw HttpException.badRequest('Missing required field: email');
  /// ```
  factory HttpException.badRequest([String message = 'Bad Request']) =>
      HttpException(400, message);

  /// Create a 401 Unauthorized exception.
  ///
  /// Used when authentication is required but not provided or invalid.
  ///
  /// [message] Custom error message (default: 'Unauthorized')
  ///
  /// Example:
  /// ```dart
  /// throw HttpException.unauthorized('Invalid or expired token');
  /// ```
  factory HttpException.unauthorized([String message = 'Unauthorized']) =>
      HttpException(401, message);

  /// Create a 403 Forbidden exception.
  ///
  /// Used when the client is authenticated but doesn't have permission.
  ///
  /// [message] Custom error message (default: 'Forbidden')
  ///
  /// Example:
  /// ```dart
  /// throw HttpException.forbidden('Insufficient permissions to access this resource');
  /// ```
  factory HttpException.forbidden([String message = 'Forbidden']) =>
      HttpException(403, message);

  /// Create a 404 Not Found exception.
  ///
  /// Used when the requested resource doesn't exist.
  ///
  /// [message] Custom error message (default: 'Not Found')
  ///
  /// Example:
  /// ```dart
  /// throw HttpException.notFound('User with ID $userId not found');
  /// ```
  factory HttpException.notFound([String message = 'Not Found']) =>
      HttpException(404, message);

  /// Create a 409 Conflict exception.
  ///
  /// Used when the request conflicts with the current state of the server.
  ///
  /// [message] Custom error message (default: 'Conflict')
  ///
  /// Example:
  /// ```dart
  /// throw HttpException.conflict('Email address already in use');
  /// ```
  factory HttpException.conflict([String message = 'Conflict']) =>
      HttpException(409, message);

  /// Create a 422 Unprocessable Entity exception.
  ///
  /// Used when the request is well-formed but contains semantic errors.
  ///
  /// [message] Custom error message (default: 'Unprocessable Entity')
  ///
  /// Example:
  /// ```dart
  /// throw HttpException.unprocessableEntity('Validation failed: age must be positive');
  /// ```
  factory HttpException.unprocessableEntity(
          [String message = 'Unprocessable Entity']) =>
      HttpException(422, message);

  /// Create a 500 Internal Server Error exception.
  ///
  /// Used when an unexpected server error occurs.
  ///
  /// [message] Custom error message (default: 'Internal Server Error')
  ///
  /// Example:
  /// ```dart
  /// throw HttpException.internalServerError('Database connection failed');
  /// ```
  factory HttpException.internalServerError(
          [String message = 'Internal Server Error']) =>
      HttpException(500, message);

  /// Returns a string representation of this HTTP exception.
  ///
  /// Format: 'HttpException(statusCode): message'
  ///
  /// Example: 'HttpException(404): User not found'
  @override
  String toString() {
    return 'HttpException($statusCode): $message';
  }
}
