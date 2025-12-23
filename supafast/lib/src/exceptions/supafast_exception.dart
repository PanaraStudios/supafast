/// Base exception class for all Supafast framework-related errors.
///
/// This class serves as the foundation for all custom exceptions thrown
/// by the Supafast framework. It provides a consistent structure for
/// error handling with support for error messages and additional details.
///
/// ## Usage
///
/// Create custom exceptions by extending this class:
///
/// ```dart
/// class DatabaseException extends SupafastException {
///   const DatabaseException(String message, [dynamic details])
///       : super(message, details);
/// }
///
/// throw DatabaseException('Connection failed', {'host': 'localhost', 'port': 5432});
/// ```
///
/// ## Error Handling
///
/// ```dart
/// try {
///   // Some Supafast operation
/// } on SupafastException catch (e) {
///   print('Supafast error: ${e.message}');
///   if (e.details != null) {
///     print('Details: ${e.details}');
///   }
/// }
/// ```
class SupafastException implements Exception {
  /// The primary error message describing what went wrong.
  final String message;

  /// Optional additional details about the error.
  ///
  /// This can contain any type of data that provides more context
  /// about the error, such as validation errors, stack traces,
  /// or structured error information.
  final dynamic details;

  /// Creates a new SupafastException.
  ///
  /// [message] A descriptive error message
  /// [details] Optional additional error details
  const SupafastException(this.message, [this.details]);

  /// Returns a string representation of this exception.
  ///
  /// If details are provided, they will be included in the output.
  /// Otherwise, only the message is shown.
  ///
  /// Format:
  /// - With details: 'SupafastException: {message}\nDetails: {details}'
  /// - Without details: 'SupafastException: {message}'
  @override
  String toString() {
    if (details != null) {
      return 'SupafastException: $message\nDetails: $details';
    }
    return 'SupafastException: $message';
  }
}
