import 'dart:convert';
import 'dart:io';

/// Test response wrapper for HTTP responses with convenient assertion methods.
///
/// Provides a comprehensive interface for examining and asserting on HTTP
/// responses in tests. Includes helpers for common response patterns,
/// content type checking, and cookie handling.
///
/// Example:
/// ```dart
/// void main() {
///   test('API returns user data', () async {
///     final response = await testApp.get('/api/users/123').send();
///
///     expect(response.isSuccess, true);
///     expect(response.statusCode, 200);
///     expect(response.isJson, true);
///
///     final user = response.json;
///     expect(user['id'], 123);
///     expect(user['name'], 'John Doe');
///   });
///
///   test('Error handling', () async {
///     final response = await testApp.get('/api/users/999').send();
///
///     expect(response.isClientError, true);
///     expect(response.statusCode, 404);
///     expect(response.json['error'], 'User not found');
///   });
///
///   test('Cookie handling', () async {
///     final response = await testApp.post('/api/login')
///       .form({'username': 'user', 'password': 'pass'})
///       .send();
///
///     expect(response.isSuccess, true);
///     final sessionCookie = response.cookie('session_id');
///     expect(sessionCookie, isNotNull);
///   });
/// }
/// ```
///
/// Features:
/// - Status code classification (success, error, redirect)
/// - Content type detection and helpers
/// - JSON parsing with error handling
/// - Cookie extraction and management
/// - Header access methods
/// - Response body content access
class TestResponse {
  /// The underlying HTTP client response.
  final HttpClientResponse _response;

  /// The complete response body as a string.
  final String body;

  /// Creates a test response wrapper around an HTTP response.
  ///
  /// [_response] The HTTP client response object.
  /// [body] The response body content as a string.
  TestResponse(this._response, this.body);

  /// HTTP status code of the response.
  ///
  /// Example:
  /// ```dart
  /// expect(response.statusCode, 200);
  /// expect(response.statusCode, 404);
  /// ```
  int get statusCode => _response.statusCode;

  /// All HTTP headers from the response.
  ///
  /// Provides access to the raw headers object for advanced use cases.
  /// For simple header access, use [header] method instead.
  HttpHeaders get headers => _response.headers;

  /// Get the value of a specific response header.
  ///
  /// Header names are case-insensitive. Returns the first value if multiple
  /// values exist for the same header.
  ///
  /// Example:
  /// ```dart
  /// expect(response.header('content-type'), 'application/json');
  /// expect(response.header('X-RateLimit-Remaining'), '99');
  /// ```
  ///
  /// [name] Header name (case-insensitive).
  /// Returns the header value or null if not present.
  String? header(String name) {
    return _response.headers.value(name.toLowerCase());
  }

  /// Get all values for a response header that may have multiple values.
  ///
  /// Some headers like 'Set-Cookie' can appear multiple times. This method
  /// returns all values for such headers.
  ///
  /// Example:
  /// ```dart
  /// final cookies = response.headerValues('set-cookie');
  /// expect(cookies?.length, 2);
  /// ```
  ///
  /// [name] Header name (case-insensitive).
  /// Returns list of header values or null if header not present.
  List<String>? headerValues(String name) {
    return _response.headers[name.toLowerCase()];
  }

  /// Parse response body as JSON.
  ///
  /// Automatically decodes the response body as JSON. Can return Maps,
  /// Lists, or primitive values depending on the JSON structure.
  ///
  /// Example:
  /// ```dart
  /// final data = response.json;
  /// expect(data['id'], 123);
  /// expect(data['items'], isList);
  /// ```
  ///
  /// Throws [FormatException] if the response body is not valid JSON.
  dynamic get json {
    try {
      return jsonDecode(body);
    } catch (e) {
      throw FormatException('Response body is not valid JSON: $e');
    }
  }

  /// Get response body as raw text.
  ///
  /// Returns the complete response body as a string without any parsing.
  /// Useful for plain text responses or when you need the raw content.
  ///
  /// Example:
  /// ```dart
  /// expect(response.text, 'Hello, World!');
  /// expect(response.text.contains('error'), false);
  /// ```
  String get text => body;

  /// Check if response has a specific status code.
  ///
  /// Convenience method for status code assertions in tests.
  ///
  /// Example:
  /// ```dart
  /// expect(response.hasStatus(200), true);
  /// expect(response.hasStatus(404), false);
  /// ```
  ///
  /// [expectedStatusCode] The status code to check for.
  /// Returns true if status codes match, false otherwise.
  bool hasStatus(int expectedStatusCode) {
    return statusCode == expectedStatusCode;
  }

  /// Check if response indicates success (2xx status codes).
  ///
  /// Returns true for status codes 200-299, which indicate successful
  /// request processing.
  ///
  /// Example:
  /// ```dart
  /// expect(response.isSuccess, true); // 200, 201, 204, etc.
  /// ```
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Check if response indicates a client error (4xx status codes).
  ///
  /// Returns true for status codes 400-499, which indicate client-side
  /// errors like bad requests, authentication failures, etc.
  ///
  /// Example:
  /// ```dart
  /// expect(response.isClientError, true); // 400, 401, 404, etc.
  /// ```
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// Check if response indicates a server error (5xx status codes).
  ///
  /// Returns true for status codes 500-599, which indicate server-side
  /// errors like internal server errors, service unavailable, etc.
  ///
  /// Example:
  /// ```dart
  /// expect(response.isServerError, true); // 500, 502, 503, etc.
  /// ```
  bool get isServerError => statusCode >= 500 && statusCode < 600;

  /// Check if response indicates a redirect (3xx status codes).
  ///
  /// Returns true for status codes 300-399, which indicate redirection
  /// responses that require further action.
  ///
  /// Example:
  /// ```dart
  /// expect(response.isRedirect, true); // 301, 302, 304, etc.
  /// ```
  bool get isRedirect => statusCode >= 300 && statusCode < 400;

  /// Get the parsed Content-Type header.
  ///
  /// Returns a [ContentType] object with parsed MIME type and parameters,
  /// or null if no Content-Type header is present.
  ///
  /// Example:
  /// ```dart
  /// final ct = response.contentType;
  /// expect(ct?.mimeType, 'application/json');
  /// expect(ct?.charset, 'utf-8');
  /// ```
  ContentType? get contentType => _response.headers.contentType;

  /// Check if response Content-Type is JSON.
  ///
  /// Returns true if the response has Content-Type 'application/json'.
  /// Useful for verifying API responses return JSON.
  ///
  /// Example:
  /// ```dart
  /// expect(response.isJson, true);
  /// final data = response.json; // Safe to parse
  /// ```
  bool get isJson {
    final ct = contentType;
    return ct != null && ct.mimeType == 'application/json';
  }

  /// Check if response Content-Type is HTML.
  ///
  /// Returns true if the response has Content-Type 'text/html'.
  /// Useful for testing web pages or HTML responses.
  ///
  /// Example:
  /// ```dart
  /// expect(response.isHtml, true);
  /// expect(response.body.contains('<html>'), true);
  /// ```
  bool get isHtml {
    final ct = contentType;
    return ct != null && ct.mimeType == 'text/html';
  }

  /// Check if response Content-Type is any text type.
  ///
  /// Returns true for any Content-Type with primary type 'text'
  /// (text/plain, text/html, text/css, etc.).
  ///
  /// Example:
  /// ```dart
  /// expect(response.isText, true); // text/plain, text/html, etc.
  /// ```
  bool get isText {
    final ct = contentType;
    return ct != null && ct.primaryType == 'text';
  }

  /// Get all cookies from Set-Cookie headers.
  ///
  /// Parses all Set-Cookie headers and returns a list of Cookie objects.
  /// Invalid cookie headers are silently skipped.
  ///
  /// Example:
  /// ```dart
  /// final cookies = response.cookies;
  /// expect(cookies.length, 2);
  /// expect(cookies.first.name, 'session_id');
  /// ```
  ///
  /// Returns a list of parsed [Cookie] objects.
  List<Cookie> get cookies {
    final cookies = <Cookie>[];
    final setCookieHeaders = headerValues('set-cookie');

    if (setCookieHeaders != null) {
      for (final cookieHeader in setCookieHeaders) {
        try {
          cookies.add(Cookie.fromSetCookieValue(cookieHeader));
        } catch (e) {
          // Skip invalid cookie headers
        }
      }
    }

    return cookies;
  }

  /// Get a specific cookie by name from the response.
  ///
  /// Searches through all Set-Cookie headers for a cookie with the given name.
  /// Returns the first matching cookie or null if not found.
  ///
  /// Example:
  /// ```dart
  /// final sessionCookie = response.cookie('session_id');
  /// expect(sessionCookie?.value, 'abc123');
  /// expect(sessionCookie?.httpOnly, true);
  /// ```
  ///
  /// [name] The name of the cookie to find.
  /// Returns the [Cookie] object or null if not found.
  Cookie? cookie(String name) {
    return cookies.where((c) => c.name == name).firstOrNull;
  }

  /// Get response Content-Length in bytes.
  ///
  /// Returns the value of the Content-Length header as an integer,
  /// or null if the header is not present or invalid.
  ///
  /// Example:
  /// ```dart
  /// expect(response.contentLength, 1234);
  /// expect(response.body.length, response.contentLength);
  /// ```
  ///
  /// Returns the content length in bytes or null.
  int? get contentLength {
    final lengthHeader = header('content-length');
    return lengthHeader != null ? int.tryParse(lengthHeader) : null;
  }

  /// String representation of the test response.
  ///
  /// Provides a concise summary of the response status and body size
  /// for debugging and logging purposes.
  ///
  /// Example output: 'TestResponse(200, 1024 bytes)'
  @override
  String toString() {
    return 'TestResponse($statusCode, ${body.length} bytes)';
  }
}
