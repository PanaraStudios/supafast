import 'dart:convert';
import 'dart:io';

import 'test_response.dart';

/// Test request builder for constructing and sending HTTP requests in tests.
///
/// Provides a fluent interface for building HTTP requests with headers, body,
/// authentication, and other options. Supports common content types and
/// authentication schemes with convenient helper methods.
///
/// Example:
/// ```dart
/// // Simple GET request
/// final response = await testApp.get('/api/users').send();
///
/// // POST with JSON body
/// final response = await testApp.post('/api/users')
///   .json({'name': 'John', 'email': 'john@example.com'})
///   .send();
///
/// // Request with authentication
/// final response = await testApp.get('/api/profile')
///   .bearer('jwt-token-here')
///   .send();
///
/// // Form data submission
/// final response = await testApp.post('/api/login')
///   .form({'username': 'user', 'password': 'pass'})
///   .send();
///
/// // Custom headers
/// final response = await testApp.get('/api/data')
///   .header('X-API-Version', '2.0')
///   .header('Accept', 'application/json')
///   .send();
///
/// // Expect specific response
/// await testApp.get('/api/users/123')
///   .expect(200);
///
/// // Expect JSON response
/// await testApp.get('/api/users/123')
///   .expectJson({'id': 123, 'name': 'John'});
/// ```
///
/// Features:
/// - Fluent interface for request building
/// - Built-in support for JSON, form data, and text content
/// - Authentication helpers (Basic Auth, Bearer tokens)
/// - Cookie management
/// - Response assertions
/// - Automatic content-type handling
class TestRequest {
  /// HTTP client for making requests.
  final HttpClient _client;

  /// HTTP method for the request.
  final String method;

  /// Request path (relative to base URL).
  final String path;

  /// Base URL of the test server.
  final String baseUrl;

  /// Headers to include in the request.
  final Map<String, String> _headers = {};

  /// Request body content.
  dynamic _body;

  /// Content-Type header value.
  String? _contentType;

  /// Creates a test request builder for the given parameters.
  ///
  /// [_client] HTTP client for sending requests.
  /// [method] HTTP method (GET, POST, etc.).
  /// [path] Request path relative to base URL.
  /// [baseUrl] Base URL of the test server.
  TestRequest(this._client, this.method, this.path, this.baseUrl);

  /// Set a single HTTP header for the request.
  ///
  /// Example:
  /// ```dart
  /// testApp.get('/api/data')
  ///   .header('Accept', 'application/json')
  ///   .header('X-API-Key', 'secret-key');
  /// ```
  ///
  /// [name] Header name (case-insensitive).
  /// [value] Header value.
  /// Returns this request builder for method chaining.
  TestRequest header(String name, String value) {
    _headers[name] = value;
    return this;
  }

  /// Set multiple HTTP headers at once.
  ///
  /// Example:
  /// ```dart
  /// testApp.get('/api/data')
  ///   .headers({
  ///     'Accept': 'application/json',
  ///     'X-API-Version': '2.0',
  ///     'User-Agent': 'TestClient/1.0',
  ///   });
  /// ```
  ///
  /// [headers] Map of header names to values.
  /// Returns this request builder for method chaining.
  TestRequest headers(Map<String, String> headers) {
    _headers.addAll(headers);
    return this;
  }

  /// Set the Content-Type header for the request.
  ///
  /// Example:
  /// ```dart
  /// testApp.post('/api/data')
  ///   .contentType('application/xml')
  ///   .body(xmlData);
  /// ```
  ///
  /// [type] MIME type for the content (e.g., 'application/json').
  /// Returns this request builder for method chaining.
  TestRequest contentType(String type) {
    _contentType = type;
    return this;
  }

  /// Set raw request body content.
  ///
  /// For custom body content that doesn't fit the JSON, form, or text helpers.
  /// The content-type should be set separately if needed.
  ///
  /// Example:
  /// ```dart
  /// testApp.post('/api/upload')
  ///   .contentType('application/octet-stream')
  ///   .body(binaryData);
  /// ```
  ///
  /// [data] Body content (will be converted to string).
  /// Returns this request builder for method chaining.
  TestRequest body(dynamic data) {
    _body = data;
    return this;
  }

  /// Set request body as JSON and automatically set Content-Type.
  ///
  /// Automatically serializes the data to JSON and sets the appropriate
  /// Content-Type header. Accepts Maps, Lists, or any JSON-serializable data.
  ///
  /// Example:
  /// ```dart
  /// // Object data
  /// testApp.post('/api/users')
  ///   .json({'name': 'John', 'age': 30});
  ///
  /// // Array data
  /// testApp.post('/api/bulk')
  ///   .json([{'id': 1}, {'id': 2}]);
  /// ```
  ///
  /// [data] Data to serialize as JSON (Map, List, or primitive).
  /// Returns this request builder for method chaining.
  TestRequest json(dynamic data) {
    _body = data;
    _contentType = 'application/json';
    return this;
  }

  /// Set request body as URL-encoded form data.
  ///
  /// Automatically encodes the form data and sets the appropriate
  /// Content-Type header. Values are URL-encoded to handle special characters.
  ///
  /// Example:
  /// ```dart
  /// testApp.post('/api/login')
  ///   .form({
  ///     'username': 'user@example.com',
  ///     'password': 'secret123',
  ///     'remember_me': 'true',
  ///   });
  /// ```
  ///
  /// [data] Form field names and values.
  /// Returns this request builder for method chaining.
  TestRequest form(Map<String, String> data) {
    _body = data;
    _contentType = 'application/x-www-form-urlencoded';
    return this;
  }

  /// Set request body as plain text.
  ///
  /// Sets the body to the provided string and Content-Type to text/plain.
  /// Useful for sending raw text, XML, or other non-JSON content.
  ///
  /// Example:
  /// ```dart
  /// testApp.post('/api/notes')
  ///   .text('This is a plain text note.');
  /// ```
  ///
  /// [data] Text content for the request body.
  /// Returns this request builder for method chaining.
  TestRequest text(String data) {
    _body = data;
    _contentType = 'text/plain';
    return this;
  }

  /// Add a cookie to the request.
  ///
  /// Automatically formats cookies into the Cookie header. Multiple cookies
  /// are properly separated with semicolons.
  ///
  /// Example:
  /// ```dart
  /// testApp.get('/api/profile')
  ///   .cookie('session_id', 'abc123')
  ///   .cookie('preferences', 'dark_mode=true');
  /// ```
  ///
  /// [name] Cookie name.
  /// [value] Cookie value.
  /// Returns this request builder for method chaining.
  TestRequest cookie(String name, String value) {
    final existingCookies = _headers['cookie'] ?? '';
    final newCookie = '$name=$value';

    if (existingCookies.isEmpty) {
      _headers['cookie'] = newCookie;
    } else {
      _headers['cookie'] = '$existingCookies; $newCookie';
    }

    return this;
  }

  /// Set HTTP Basic Authentication header.
  ///
  /// Automatically encodes credentials in Base64 format and sets the
  /// Authorization header. Commonly used for API authentication.
  ///
  /// Example:
  /// ```dart
  /// testApp.get('/api/admin')
  ///   .auth('admin', 'secret123');
  /// ```
  ///
  /// [username] Username for authentication.
  /// [password] Password for authentication.
  /// Returns this request builder for method chaining.
  TestRequest auth(String username, String password) {
    final credentials = base64Encode(utf8.encode('$username:$password'));
    return header('authorization', 'Basic $credentials');
  }

  /// Set Bearer token authentication header.
  ///
  /// Sets the Authorization header with a Bearer token, commonly used
  /// for JWT or OAuth token authentication.
  ///
  /// Example:
  /// ```dart
  /// testApp.get('/api/profile')
  ///   .bearer('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...');
  /// ```
  ///
  /// [token] The bearer token (without 'Bearer ' prefix).
  /// Returns this request builder for method chaining.
  TestRequest bearer(String token) {
    return header('authorization', 'Bearer $token');
  }

  /// Send the HTTP request and return the response.
  ///
  /// Constructs the complete HTTP request with all configured headers,
  /// body content, and authentication, then sends it to the server.
  ///
  /// Example:
  /// ```dart
  /// final response = await testApp.get('/api/users')
  ///   .header('Accept', 'application/json')
  ///   .send();
  ///
  /// print('Status: ${response.statusCode}');
  /// print('Body: ${response.body}');
  /// ```
  ///
  /// Returns a [TestResponse] with the server's response.
  /// Throws [TestException] if the request fails due to network issues.
  Future<TestResponse> send() async {
    final uri = Uri.parse('$baseUrl$path');

    try {
      final request = await _client.openUrl(method, uri);

      // Set headers
      _headers.forEach((key, value) {
        request.headers.add(key, value);
      });

      // Set content type if specified
      if (_contentType != null) {
        request.headers.contentType = ContentType.parse(_contentType!);
      }

      // Write body if present
      if (_body != null) {
        String bodyString;

        if (_body is Map || _body is List) {
          if (_contentType == 'application/x-www-form-urlencoded') {
            // Form encode
            final formData = _body as Map<String, String>;
            bodyString = formData.entries
                .map((e) =>
                    '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
                .join('&');
          } else {
            // JSON encode
            bodyString = jsonEncode(_body);
            if (_contentType == null) {
              request.headers.contentType = ContentType.json;
            }
          }
        } else {
          bodyString = _body.toString();
        }

        request.write(bodyString);
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      return TestResponse(response, responseBody);
    } catch (e) {
      throw TestException('Request failed: $e');
    }
  }

  /// Send request and assert the response has a specific status code.
  ///
  /// Convenience method that sends the request and automatically validates
  /// the response status code. Throws a [TestFailure] if the status doesn't match.
  ///
  /// Example:
  /// ```dart
  /// // Expect successful creation
  /// final response = await testApp.post('/api/users')
  ///   .json({'name': 'John'})
  ///   .expect(201);
  ///
  /// // Expect not found
  /// await testApp.get('/api/users/999').expect(404);
  /// ```
  ///
  /// [statusCode] Expected HTTP status code.
  /// Returns the [TestResponse] if status matches.
  /// Throws [TestFailure] if status code doesn't match expectation.
  Future<TestResponse> expect(int statusCode) async {
    final response = await send();
    if (response.statusCode != statusCode) {
      throw TestFailure(
        'Expected status $statusCode but got ${response.statusCode}\n'
        'Response body: ${response.body}',
      );
    }
    return response;
  }

  /// Send request and assert the response contains expected JSON.
  ///
  /// Convenience method that sends the request, parses the response as JSON,
  /// and validates it matches the expected structure using deep equality.
  ///
  /// Example:
  /// ```dart
  /// // Expect exact JSON match
  /// await testApp.get('/api/users/123')
  ///   .expectJson({
  ///     'id': 123,
  ///     'name': 'John Doe',
  ///     'email': 'john@example.com'
  ///   });
  /// ```
  ///
  /// [expected] Expected JSON structure as a Map.
  /// Returns the [TestResponse] if JSON matches.
  /// Throws [TestFailure] if JSON doesn't match or isn't valid JSON.
  Future<TestResponse> expectJson(Map<String, dynamic> expected) async {
    final response = await send();

    try {
      final actual = jsonDecode(response.body) as Map<String, dynamic>;
      if (!_deepEquals(actual, expected)) {
        throw TestFailure(
          'JSON mismatch:\nExpected: $expected\nActual: $actual',
        );
      }
    } catch (e) {
      if (e is TestFailure) rethrow;
      throw TestFailure('Failed to parse response as JSON: $e');
    }

    return response;
  }

  /// Send request and assert both status code and optional JSON content.
  ///
  /// Convenience method that combines status code and JSON validation.
  /// First checks the status code, then optionally validates JSON content.
  ///
  /// Example:
  /// ```dart
  /// // Just check status
  /// await testApp.get('/health').expectStatus(200);
  ///
  /// // Check status and JSON
  /// await testApp.post('/api/users')
  ///   .json({'name': 'John'})
  ///   .expectStatus(201, {
  ///     'id': 123,
  ///     'name': 'John',
  ///     'created': true
  ///   });
  /// ```
  ///
  /// [statusCode] Expected HTTP status code.
  /// [json] Optional expected JSON structure.
  /// Returns the [TestResponse] if all assertions pass.
  /// Throws [TestFailure] if status or JSON doesn't match.
  Future<TestResponse> expectStatus(int statusCode,
      [Map<String, dynamic>? json]) async {
    final response = await expect(statusCode);

    if (json != null) {
      try {
        final actual = jsonDecode(response.body) as Map<String, dynamic>;
        if (!_deepEquals(actual, json)) {
          throw TestFailure(
            'JSON mismatch:\nExpected: $json\nActual: $actual',
          );
        }
      } catch (e) {
        if (e is TestFailure) rethrow;
        throw TestFailure('Failed to parse response as JSON: $e');
      }
    }

    return response;
  }
}

/// Perform deep equality comparison for JSON objects.
///
/// Recursively compares Maps, Lists, and primitive values to determine
/// if two JSON structures are equivalent. Used for validating expected
/// vs actual JSON responses in tests.
///
/// [a] First object to compare.
/// [b] Second object to compare.
/// Returns true if objects are deeply equal, false otherwise.
bool _deepEquals(dynamic a, dynamic b) {
  if (a.runtimeType != b.runtimeType) return false;

  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) {
        return false;
      }
    }
    return true;
  }

  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }

  return a == b;
}

/// Exception thrown when a test assertion fails.
///
/// Used by expectation methods like [expect], [expectJson], and [expectStatus]
/// when the actual response doesn't match the expected values.
class TestFailure implements Exception {
  /// The failure message describing what went wrong.
  final String message;

  /// Creates a test failure with the given message.
  TestFailure(this.message);

  @override
  String toString() => 'TestFailure: $message';
}

/// Exception thrown when a test encounters a technical error.
///
/// Used for network issues, malformed requests, or other technical
/// problems that prevent the test from completing properly.
class TestException implements Exception {
  /// The exception message describing the technical error.
  final String message;

  /// Creates a test exception with the given message.
  TestException(this.message);

  @override
  String toString() => 'TestException: $message';
}
