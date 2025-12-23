import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../utils/content_type.dart';
import '../exceptions/http_exception.dart';

/// A comprehensive wrapper around Dart's HttpResponse that provides a clean,
/// Express.js-like fluent API for building and sending HTTP responses.
///
/// The Response class abstracts away the complexity of working with raw HTTP responses
/// and provides convenient methods for setting headers, status codes, and sending
/// different types of response data including JSON, HTML, files, and more.
///
/// ## Basic Usage
///
/// ```dart
/// app.get('/users/:id', (req, res) async {
///   final userId = req.params['id'];
///
///   if (userId == null) {
///     return res.badRequest('User ID is required');
///   }
///
///   final user = await getUserById(userId);
///   if (user == null) {
///     return res.notFound('User not found');
///   }
///
///   await res.json(user);
/// });
/// ```
///
/// ## Fluent API
///
/// Most methods return the Response instance, allowing for method chaining:
///
/// ```dart
/// app.get('/api/data', (req, res) async {
///   await res
///     .status(200)
///     .header('X-API-Version', '1.0')
///     .header('Cache-Control', 'max-age=3600')
///     .json({'message': 'Success', 'data': data});
/// });
/// ```
///
/// ## Different Response Types
///
/// ```dart
/// // JSON response
/// await res.json({'name': 'John', 'age': 30});
///
/// // HTML response
/// await res.html('<h1>Welcome</h1>');
///
/// // File download
/// await res.file('/path/to/document.pdf');
///
/// // Plain text
/// await res.send('Hello World');
///
/// // Redirect
/// await res.redirect('/login');
///
/// // Status-only response
/// await res.sendStatus(204); // No Content
/// ```
///
/// ## Cookie Management
///
/// ```dart
/// // Set cookies
/// res.cookie('session_id', sessionId, maxAge: 3600)
///    .cookie('user_pref', 'dark_theme');
///
/// // Clear cookies
/// res.clearCookie('session_id');
/// ```
class Response {
  /// The underlying Dart HttpResponse object
  final HttpResponse _response;

  /// Flag to track if the response has been sent to prevent double-sending
  bool _sent = false;

  /// Creates a new Response wrapper around the given HttpResponse.
  ///
  /// [_response] The underlying Dart HttpResponse to wrap
  Response(this._response);

  /// Check if the response has been sent.
  ///
  /// Returns `true` if the response has been sent and the connection closed,
  /// `false` otherwise. Once a response is sent, no further modifications
  /// can be made.
  ///
  /// Example:
  /// ```dart
  /// if (!res.sent) {
  ///   await res.json({'error': 'Something went wrong'});
  /// }
  /// ```
  bool get sent => _sent;

  /// Get the current HTTP status code.
  ///
  /// Returns the status code that will be sent with the response.
  /// Default is 200 (OK) unless explicitly set.
  ///
  /// Example:
  /// ```dart
  /// print('Current status: ${res.statusCode}'); // 200
  /// res.status(404);
  /// print('New status: ${res.statusCode}'); // 404
  /// ```
  int get statusCode => _response.statusCode;

  /// Set the HTTP status code for this response.
  ///
  /// This method uses a fluent API, returning the Response instance
  /// to allow method chaining.
  ///
  /// [code] The HTTP status code to set (e.g., 200, 404, 500)
  ///
  /// Returns this Response instance for method chaining.
  ///
  /// Throws [StateError] if the response has already been sent.
  ///
  /// Example:
  /// ```dart
  /// await res.status(201).json({'message': 'Created successfully'});
  /// await res.status(404).send('Page not found');
  /// ```
  Response status(int code) {
    _checkNotSent();
    _response.statusCode = code;
    return this;
  }

  /// Set an HTTP response header.
  ///
  /// This method uses a fluent API, returning the Response instance
  /// to allow method chaining.
  ///
  /// [name] The header name
  /// [value] The header value
  ///
  /// Returns this Response instance for method chaining.
  ///
  /// Throws [StateError] if the response has already been sent.
  ///
  /// Example:
  /// ```dart
  /// res.header('X-API-Version', '1.0')
  ///    .header('Cache-Control', 'no-cache')
  ///    .header('X-Request-ID', requestId);
  /// ```
  Response header(String name, Object value) {
    _checkNotSent();
    _response.headers.set(name, value);
    return this;
  }

  /// Set multiple HTTP response headers at once.
  ///
  /// This method uses a fluent API, returning the Response instance
  /// to allow method chaining.
  ///
  /// [headerMap] A map of header names to values
  ///
  /// Returns this Response instance for method chaining.
  ///
  /// Throws [StateError] if the response has already been sent.
  ///
  /// Example:
  /// ```dart
  /// res.headers({
  ///   'X-API-Version': '1.0',
  ///   'Cache-Control': 'max-age=3600',
  ///   'X-Request-ID': requestId,
  /// });
  /// ```
  Response headers(Map<String, Object> headerMap) {
    _checkNotSent();
    headerMap.forEach((name, value) {
      _response.headers.set(name, value);
    });
    return this;
  }

  /// Set the Content-Type header.
  ///
  /// This is a convenience method for setting the Content-Type header.
  /// Uses a fluent API, returning the Response instance for method chaining.
  ///
  /// [type] The content type string (e.g., 'application/json', 'text/html')
  ///
  /// Returns this Response instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// res.contentType('application/json');
  /// res.contentType('text/html; charset=utf-8');
  /// ```
  Response contentType(String type) {
    return header('content-type', type);
  }

  /// Set an HTTP cookie.
  ///
  /// This method uses a fluent API, returning the Response instance
  /// to allow method chaining.
  ///
  /// [name] The cookie name
  /// [value] The cookie value
  /// [maxAge] Maximum age of the cookie in seconds
  /// [expires] Absolute expiration date
  /// [domain] Domain for which the cookie is valid
  /// [path] Path for which the cookie is valid
  /// [secure] Whether the cookie should only be sent over HTTPS
  /// [httpOnly] Whether the cookie should be inaccessible to JavaScript
  ///
  /// Returns this Response instance for method chaining.
  ///
  /// Throws [StateError] if the response has already been sent.
  ///
  /// Example:
  /// ```dart
  /// res.cookie('session_id', sessionId, maxAge: 3600, httpOnly: true)
  ///    .cookie('user_theme', 'dark', maxAge: 86400 * 30); // 30 days
  /// ```
  Response cookie(
    String name,
    String value, {
    int? maxAge,
    DateTime? expires,
    String? domain,
    String? path,
    bool? secure,
    bool? httpOnly,
  }) {
    _checkNotSent();
    final cookie = Cookie(name, value)
      ..maxAge = maxAge
      ..expires = expires
      ..domain = domain
      ..path = path
      ..secure = secure ?? false
      ..httpOnly = httpOnly ?? false;

    _response.cookies.add(cookie);
    return this;
  }

  /// Clear an HTTP cookie by setting it to expire immediately.
  ///
  /// This method uses a fluent API, returning the Response instance
  /// to allow method chaining.
  ///
  /// [name] The name of the cookie to clear
  /// [domain] Domain of the cookie (must match the original domain)
  /// [path] Path of the cookie (must match the original path)
  ///
  /// Returns this Response instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// res.clearCookie('session_id')
  ///    .clearCookie('user_preferences', path: '/app');
  /// ```
  Response clearCookie(String name, {String? domain, String? path}) {
    return cookie(
      name,
      '',
      maxAge: 0,
      expires: DateTime.fromMillisecondsSinceEpoch(0),
      domain: domain,
      path: path,
    );
  }

  /// Send a plain text response.
  ///
  /// This method sends a string response with appropriate Content-Type header.
  /// If no Content-Type is already set, it defaults to 'text/plain'.
  ///
  /// [body] The string content to send
  ///
  /// Throws [StateError] if the response has already been sent.
  ///
  /// Example:
  /// ```dart
  /// await res.send('Hello, World!');
  /// await res.status(404).send('Page not found');
  /// ```
  Future<void> send(String body) async {
    _checkNotSent();

    // Set content type if not already set
    if (_response.headers.contentType == null) {
      contentType(ContentTypeUtils.plain);
    }

    _response.write(body);
    await _response.close();
    _sent = true;
  }

  /// Send a JSON response.
  ///
  /// This method serializes the provided data to JSON and sends it with
  /// the appropriate Content-Type header ('application/json; charset=utf-8').
  ///
  /// [data] The data to serialize and send (Map, List, or any JSON-serializable object)
  ///
  /// Throws [StateError] if the response has already been sent.
  /// Throws [JsonUnsupportedObjectError] if the data cannot be serialized to JSON.
  ///
  /// Example:
  /// ```dart
  /// await res.json({'message': 'Success', 'data': userData});
  /// await res.status(201).json({'id': newUser.id, 'created': true});
  /// await res.json([user1, user2, user3]); // Array response
  /// ```
  Future<void> json(Object data) async {
    _checkNotSent();

    contentType('${ContentTypeUtils.json}; charset=utf-8');

    final jsonString = jsonEncode(data);
    _response.write(jsonString);
    await _response.close();
    _sent = true;
  }

  /// Send an HTML response.
  ///
  /// This method sends HTML content with the appropriate Content-Type header
  /// ('text/html; charset=utf-8').
  ///
  /// [html] The HTML content to send
  ///
  /// Throws [StateError] if the response has already been sent.
  ///
  /// Example:
  /// ```dart
  /// await res.html('<h1>Welcome</h1><p>Hello, World!</p>');
  /// await res.html(await renderTemplate('index.html', data));
  /// ```
  Future<void> html(String html) async {
    _checkNotSent();

    contentType('${ContentTypeUtils.html}; charset=utf-8');

    _response.write(html);
    await _response.close();
    _sent = true;
  }

  /// Send a file as the response.
  ///
  /// This method streams a file to the client with appropriate headers:
  /// - Content-Type based on file extension
  /// - Content-Length based on file size
  ///
  /// [filePath] The path to the file to send
  ///
  /// Throws [StateError] if the response has already been sent.
  /// Throws [HttpException] with status 404 if the file doesn't exist.
  ///
  /// Example:
  /// ```dart
  /// await res.file('/path/to/document.pdf');
  /// await res.file('/uploads/user-avatar.jpg');
  /// ```
  Future<void> file(String filePath) async {
    _checkNotSent();

    final file = File(filePath);

    if (!await file.exists()) {
      throw HttpException.notFound('File not found: $filePath');
    }

    // Set content type based on file extension
    final mimeType = ContentTypeUtils.fromFilePath(filePath);
    contentType(mimeType);

    // Set content length
    final fileSize = await file.length();
    header('content-length', fileSize.toString());

    // Stream the file
    await file.openRead().pipe(_response);
    _sent = true;
  }

  /// Send binary data as the response.
  ///
  /// This method sends raw binary data with appropriate headers.
  /// If no MIME type is provided, defaults to 'application/octet-stream'.
  ///
  /// [data] The binary data to send
  /// [mimeType] Optional MIME type for the data
  ///
  /// Throws [StateError] if the response has already been sent.
  ///
  /// Example:
  /// ```dart
  /// final imageBytes = await generateQrCode(data);
  /// await res.bytes(imageBytes, mimeType: 'image/png');
  ///
  /// final pdfBytes = await generateReport();
  /// await res.bytes(pdfBytes, mimeType: 'application/pdf');
  /// ```
  Future<void> bytes(Uint8List data, {String? mimeType}) async {
    _checkNotSent();

    if (mimeType != null) {
      contentType(mimeType);
    } else {
      contentType(ContentTypeUtils.octetStream);
    }

    header('content-length', data.length.toString());
    _response.add(data);
    await _response.close();
    _sent = true;
  }

  /// Redirect the client to a different URL.
  ///
  /// This method sets the Location header and sends an appropriate
  /// redirect status code.
  ///
  /// [url] The URL to redirect to (can be relative or absolute)
  /// [status] The HTTP status code for the redirect (default: 302 Found)
  ///
  /// Common redirect status codes:
  /// - 301: Moved Permanently
  /// - 302: Found (temporary redirect) - default
  /// - 303: See Other
  /// - 307: Temporary Redirect
  /// - 308: Permanent Redirect
  ///
  /// Throws [StateError] if the response has already been sent.
  ///
  /// Example:
  /// ```dart
  /// await res.redirect('/login'); // 302 redirect
  /// await res.redirect('/new-url', status: 301); // Permanent redirect
  /// await res.redirect('https://example.com/external'); // External redirect
  /// ```
  Future<void> redirect(String url, {int status = 302}) async {
    _checkNotSent();

    this.status(status);
    header('location', url);
    await send('Redirecting to $url');
  }

  /// Send a 404 Not Found response.
  ///
  /// This is a convenience method that sends a JSON error response
  /// with status code 404.
  ///
  /// [message] Optional custom error message
  ///
  /// Example:
  /// ```dart
  /// await res.notFound(); // Default message
  /// await res.notFound('User not found'); // Custom message
  /// ```
  Future<void> notFound([String? message]) async {
    await status(404).json({
      'error': 'Not Found',
      'message': message ?? 'The requested resource was not found',
      'statusCode': 404,
    });
  }

  /// Send a 401 Unauthorized response.
  ///
  /// This is a convenience method that sends a JSON error response
  /// with status code 401.
  ///
  /// [message] Optional custom error message
  ///
  /// Example:
  /// ```dart
  /// await res.unauthorized(); // Default message
  /// await res.unauthorized('Invalid token'); // Custom message
  /// ```
  Future<void> unauthorized([String? message]) async {
    await status(401).json({
      'error': 'Unauthorized',
      'message': message ?? 'Authentication required',
      'statusCode': 401,
    });
  }

  /// Send a 403 Forbidden response.
  ///
  /// This is a convenience method that sends a JSON error response
  /// with status code 403.
  ///
  /// [message] Optional custom error message
  ///
  /// Example:
  /// ```dart
  /// await res.forbidden(); // Default message
  /// await res.forbidden('Insufficient permissions'); // Custom message
  /// ```
  Future<void> forbidden([String? message]) async {
    await status(403).json({
      'error': 'Forbidden',
      'message': message ?? 'Access denied',
      'statusCode': 403,
    });
  }

  /// Send a 400 Bad Request response.
  ///
  /// This is a convenience method that sends a JSON error response
  /// with status code 400.
  ///
  /// [message] Optional custom error message
  ///
  /// Example:
  /// ```dart
  /// await res.badRequest(); // Default message
  /// await res.badRequest('Missing required field: email'); // Custom message
  /// ```
  Future<void> badRequest([String? message]) async {
    await status(400).json({
      'error': 'Bad Request',
      'message': message ?? 'Invalid request',
      'statusCode': 400,
    });
  }

  /// Send a 500 Internal Server Error response.
  ///
  /// This is a convenience method that sends a JSON error response
  /// with status code 500.
  ///
  /// [message] Optional custom error message
  ///
  /// Example:
  /// ```dart
  /// await res.serverError(); // Default message
  /// await res.serverError('Database connection failed'); // Custom message
  /// ```
  Future<void> serverError([String? message]) async {
    await status(500).json({
      'error': 'Internal Server Error',
      'message': message ?? 'An error occurred on the server',
      'statusCode': 500,
    });
  }

  /// Send an empty response with only a status code.
  ///
  /// This method is useful for responses that don't need a body,
  /// such as 204 No Content or 304 Not Modified.
  ///
  /// [statusCode] The HTTP status code to send
  ///
  /// Example:
  /// ```dart
  /// await res.sendStatus(204); // No Content
  /// await res.sendStatus(304); // Not Modified
  /// await res.sendStatus(202); // Accepted
  /// ```
  Future<void> sendStatus(int statusCode) async {
    await status(statusCode).send('');
  }

  /// Write string data to the response stream.
  ///
  /// This method allows you to send response data in chunks without
  /// immediately closing the connection. Use [close] to finish the response.
  ///
  /// [data] The string data to write to the response stream
  ///
  /// Throws [StateError] if the response has already been sent.
  ///
  /// Example:
  /// ```dart
  /// res.contentType('text/plain');
  /// res.write('Part 1\n');
  /// res.write('Part 2\n');
  /// await res.close();
  /// ```
  void write(String data) {
    _checkNotSent();
    _response.write(data);
  }

  /// Write binary data to the response stream.
  ///
  /// This method allows you to send binary response data in chunks without
  /// immediately closing the connection. Use [close] to finish the response.
  ///
  /// [data] The binary data to write to the response stream
  ///
  /// Throws [StateError] if the response has already been sent.
  ///
  /// Example:
  /// ```dart
  /// res.contentType('application/octet-stream');
  /// res.add([0x48, 0x65, 0x6C, 0x6C, 0x6F]); // "Hello" in bytes
  /// await res.close();
  /// ```
  void add(List<int> data) {
    _checkNotSent();
    _response.add(data);
  }

  /// Close the response stream and complete the response.
  ///
  /// This method should be called when you're done writing data to the response
  /// stream. It's automatically called by methods like [send], [json], [html], etc.
  ///
  /// Safe to call multiple times - subsequent calls will be ignored.
  ///
  /// Example:
  /// ```dart
  /// res.write('Streaming data...');
  /// // ... write more data ...
  /// await res.close(); // Finish the response
  /// ```
  Future<void> close() async {
    if (!_sent) {
      await _response.close();
      _sent = true;
    }
  }

  /// Internal method to check if the response has already been sent.
  ///
  /// This method is used internally to prevent modifications to a response
  /// that has already been sent to the client.
  ///
  /// Throws [StateError] if the response has been sent.
  void _checkNotSent() {
    if (_sent) {
      throw StateError('Response has already been sent');
    }
  }

  /// Returns a string representation of this response.
  ///
  /// Format: 'Response(statusCode)'
  ///
  /// Example: 'Response(200)', 'Response(404)'
  @override
  String toString() {
    return 'Response($_response.statusCode)';
  }
}
