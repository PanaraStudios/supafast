import 'dart:io';
import 'dart:math';

import '../core/supafast_app.dart';
import 'test_request.dart';

/// Test application wrapper for testing Supafast applications.
///
/// Provides a convenient interface for testing HTTP endpoints by automatically
/// managing server lifecycle, port allocation, and HTTP client creation.
/// Designed for use in unit and integration tests.
///
/// Example:
/// ```dart
/// void main() {
///   group('API Tests', () {
///     late TestApp testApp;
///
///     setUp(() async {
///       final app = Supafast();
///       app.get('/hello', (req, res) => res.send('Hello World'));
///
///       testApp = TestApp(app);
///       await testApp.start();
///     });
///
///     tearDown(() async {
///       await testApp.close();
///     });
///
///     test('GET /hello returns greeting', () async {
///       final response = await testApp.get('/hello').send();
///       expect(response.statusCode, 200);
///       expect(response.body, 'Hello World');
///     });
///   });
/// }
/// ```
///
/// Features:
/// - Automatic port allocation to avoid conflicts
/// - HTTP client management with proper timeouts
/// - Convenience methods for all HTTP verbs
/// - Clean lifecycle management
/// - Support for both localhost and custom hostnames
class TestApp {
  /// The Supafast application instance being tested.
  final Supafast app;

  /// HTTP client for making requests to the test server.
  late HttpClient _client;

  /// Port number assigned to the test server.
  int? _port;

  /// Hostname the test server is bound to.
  String? _hostname;

  /// Creates a test wrapper for the given Supafast application.
  ///
  /// [app] The Supafast application instance to test.
  TestApp(this.app);

  /// Start the test server on a random available port.
  ///
  /// Automatically finds an available port in the ephemeral range and starts
  /// the Supafast application. Creates an HTTP client with appropriate timeouts
  /// for testing scenarios.
  ///
  /// Example:
  /// ```dart
  /// final testApp = TestApp(app);
  /// await testApp.start(); // Uses localhost
  /// // or
  /// await testApp.start(hostname: '127.0.0.1');
  /// ```
  ///
  /// [hostname] The hostname to bind the server to (default: 'localhost').
  ///
  /// Throws [SocketException] if no available port can be found.
  Future<void> start({String hostname = 'localhost'}) async {
    _port = await _findAvailablePort();
    _hostname = hostname;

    // Start the app on the test port
    await app.listen(_port!, hostname: hostname);

    // Create HTTP client for making requests
    _client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5)
      ..idleTimeout = const Duration(seconds: 30);
  }

  /// Stop the test server and clean up resources.
  ///
  /// Closes the HTTP client and stops the Supafast application server.
  /// Should be called in test tearDown methods to prevent resource leaks.
  ///
  /// Example:
  /// ```dart
  /// tearDown(() async {
  ///   await testApp.close();
  /// });
  /// ```
  Future<void> close() async {
    _client.close();
    await app.close();
    _port = null;
    _hostname = null;
  }

  /// Get the base URL for the test server.
  ///
  /// Returns the complete base URL (http://hostname:port) for making
  /// requests to the test server. Useful for constructing full URLs
  /// when needed.
  ///
  /// Example:
  /// ```dart
  /// print(testApp.baseUrl); // http://localhost:54321
  /// final fullUrl = '${testApp.baseUrl}/api/users';
  /// ```
  ///
  /// Throws [StateError] if the server has not been started yet.
  String get baseUrl {
    if (_port == null || _hostname == null) {
      throw StateError('TestApp is not started. Call start() first.');
    }
    return 'http://$_hostname:$_port';
  }

  /// Create a GET request for testing.
  ///
  /// [path] The path to request (e.g., '/api/users').
  /// Returns a [TestRequest] builder for the GET request.
  TestRequest get(String path) {
    return TestRequest(_client, 'GET', path, baseUrl);
  }

  /// Create a POST request for testing.
  ///
  /// [path] The path to request (e.g., '/api/users').
  /// Returns a [TestRequest] builder for the POST request.
  TestRequest post(String path) {
    return TestRequest(_client, 'POST', path, baseUrl);
  }

  /// Create a PUT request for testing.
  ///
  /// [path] The path to request (e.g., '/api/users/123').
  /// Returns a [TestRequest] builder for the PUT request.
  TestRequest put(String path) {
    return TestRequest(_client, 'PUT', path, baseUrl);
  }

  /// Create a DELETE request for testing.
  ///
  /// [path] The path to request (e.g., '/api/users/123').
  /// Returns a [TestRequest] builder for the DELETE request.
  TestRequest delete(String path) {
    return TestRequest(_client, 'DELETE', path, baseUrl);
  }

  /// Create a PATCH request for testing.
  ///
  /// [path] The path to request (e.g., '/api/users/123').
  /// Returns a [TestRequest] builder for the PATCH request.
  TestRequest patch(String path) {
    return TestRequest(_client, 'PATCH', path, baseUrl);
  }

  /// Create an OPTIONS request for testing.
  ///
  /// [path] The path to request (e.g., '/api/users').
  /// Returns a [TestRequest] builder for the OPTIONS request.
  TestRequest options(String path) {
    return TestRequest(_client, 'OPTIONS', path, baseUrl);
  }

  /// Create a HEAD request for testing.
  ///
  /// [path] The path to request (e.g., '/api/users').
  /// Returns a [TestRequest] builder for the HEAD request.
  TestRequest head(String path) {
    return TestRequest(_client, 'HEAD', path, baseUrl);
  }

  /// Create a request with a custom HTTP method.
  ///
  /// For testing custom HTTP methods or verbs not covered by
  /// the standard convenience methods.
  ///
  /// [method] The HTTP method (e.g., 'TRACE', 'CONNECT').
  /// [path] The path to request.
  /// Returns a [TestRequest] builder for the custom request.
  TestRequest request(String method, String path) {
    return TestRequest(_client, method, path, baseUrl);
  }

  /// Find an available port for testing.
  ///
  /// Attempts to find a free port in the ephemeral port range (49152-65535)
  /// to avoid conflicts with other services. Falls back to letting the
  /// system choose a port if no random port is available.
  ///
  /// Returns an available port number.
  /// Throws [SocketException] if no port can be bound.
  Future<int> _findAvailablePort() async {
    final random = Random();
    int port;

    // Try random ports in the ephemeral range
    for (var i = 0; i < 10; i++) {
      port = 49152 + random.nextInt(16384);

      try {
        final server = await HttpServer.bind('localhost', port);
        await server.close();
        return port;
      } catch (e) {
        // Port is in use, try another
        continue;
      }
    }

    // Fallback to port 0 (system will choose)
    final server = await HttpServer.bind('localhost', 0);
    port = server.port;
    await server.close();
    return port;
  }
}
