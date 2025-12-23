import 'dart:convert';
import 'dart:io';

import '../utils/content_type.dart';
import '../utils/query_parser.dart';

/// A comprehensive wrapper around Dart's HttpRequest that provides a clean,
/// Express.js-like API for handling HTTP requests.
///
/// The Request class abstracts away the complexity of working with raw HTTP requests
/// and provides convenient methods for accessing headers, body data, query parameters,
/// path parameters, cookies, and other request information.
///
/// ## Basic Usage
///
/// ```dart
/// app.get('/users/:id', (req, res) async {
///   // Access path parameters
///   final userId = req.params['id'];
///
///   // Access query parameters
///   final includeProfile = req.query['include_profile'] == 'true';
///
///   // Access headers
///   final authHeader = req.header('authorization');
///
///   // Access request body (if parsed by middleware)
///   final requestData = req.body;
///
///   await res.json({'user_id': userId, 'include_profile': includeProfile});
/// });
/// ```
///
/// ## Body Parsing
///
/// Request bodies must be parsed before accessing via the `body` property:
///
/// ```dart
/// app.use(bodyParser()); // Global body parsing
///
/// app.post('/users', (req, res) async {
///   final userData = req.body; // Now safely accessible
///   // Process user creation...
/// });
/// ```
///
/// ## Custom Properties
///
/// Use the `locals` map to attach custom data to requests for use in middleware:
///
/// ```dart
/// app.use((req, res, next) async {
///   req.locals['user'] = await getUserFromToken(req.header('authorization'));
///   await next();
/// });
///
/// app.get('/profile', (req, res) async {
///   final user = req.locals['user']; // Access attached data
///   await res.json(user);
/// });
/// ```
class Request {
  /// The underlying Dart HttpRequest object
  final HttpRequest _request;

  /// Cached path parameters extracted from route matching
  Map<String, String>? _params;

  /// Cached query string parameters
  Map<String, String>? _query;

  /// Parsed request body (set by body parser middleware)
  dynamic _body;

  /// Raw request body as string (cached after first access)
  String? _rawBody;

  /// Raw request body as bytes (cached after first access)
  List<int>? _rawBytes;

  /// Flag indicating whether the request body has been parsed
  bool _bodyParsed = false;

  /// Custom properties map for middleware to attach data to requests.
  ///
  /// This provides a way for middleware to share data with route handlers
  /// and other middleware functions. Common uses include attaching user
  /// information, request metadata, or computed values.
  ///
  /// Example:
  /// ```dart
  /// // In authentication middleware
  /// req.locals['user'] = await getUserFromToken(req.header('authorization'));
  /// req.locals['isAuthenticated'] = true;
  ///
  /// // In route handler
  /// final user = req.locals['user'];
  /// final isAuth = req.locals['isAuthenticated'] ?? false;
  /// ```
  final Map<String, dynamic> locals = {};

  /// Creates a new Request wrapper around the given HttpRequest.
  ///
  /// [_request] The underlying Dart HttpRequest to wrap
  Request(this._request);

  /// The HTTP method of this request (GET, POST, PUT, DELETE, etc.).
  ///
  /// Always returned in uppercase for consistent comparison.
  ///
  /// Example:
  /// ```dart
  /// if (req.method == 'POST') {
  ///   // Handle POST request
  /// }
  /// ```
  String get method => _request.method.toUpperCase();

  /// The path portion of the request URL, without query string or fragment.
  ///
  /// For example, for the URL 'https://example.com/users/123?include=profile',
  /// this would return '/users/123'.
  ///
  /// Example:
  /// ```dart
  /// print(req.path); // '/users/123'
  /// ```
  String get path => _request.uri.path;

  /// The complete request URI including scheme, host, path, and query string.
  ///
  /// Example:
  /// ```dart
  /// print(req.uri); // https://example.com/users/123?include=profile
  /// print(req.uri.host); // example.com
  /// print(req.uri.scheme); // https
  /// ```
  Uri get uri => _request.uri;

  /// The request headers as an HttpHeaders object.
  ///
  /// Provides access to all HTTP headers sent with the request.
  ///
  /// Example:
  /// ```dart
  /// final contentType = req.headers.contentType;
  /// final userAgent = req.headers.value('user-agent');
  /// ```
  HttpHeaders get headers => _request.headers;

  /// Get the value of a specific HTTP header.
  ///
  /// Header names are case-insensitive. If the header has multiple values,
  /// only the first one is returned. Use [headers] for more complex header access.
  ///
  /// [name] The header name (case insensitive)
  ///
  /// Returns the header value or `null` if the header is not present.
  ///
  /// Example:
  /// ```dart
  /// final authHeader = req.header('Authorization');
  /// final contentType = req.header('content-type');
  /// final userAgent = req.header('User-Agent');
  /// ```
  String? header(String name) {
    return _request.headers.value(name.toLowerCase());
  }

  /// Path parameters extracted from the route pattern.
  ///
  /// These are parameters defined in the route pattern with ':' notation.
  /// For example, a route '/users/:id' matched against '/users/123' would
  /// result in params containing {'id': '123'}.
  ///
  /// Returns an empty map if no parameters were extracted.
  ///
  /// Example:
  /// ```dart
  /// // Route: '/users/:userId/posts/:postId'
  /// // Request: '/users/123/posts/456'
  /// final userId = req.params['userId'];   // '123'
  /// final postId = req.params['postId'];   // '456'
  /// ```
  Map<String, String> get params {
    return _params ?? {};
  }

  /// Set path parameters (used internally by the router during route matching).
  ///
  /// This method is called by the router when a route matches and path
  /// parameters are extracted from the URL.
  ///
  /// [params] The map of parameter names to values
  void setParams(Map<String, String> params) {
    _params = params;
  }

  /// Query string parameters parsed from the request URL.
  ///
  /// These are the parameters that appear after the '?' in the URL.
  /// The parsing is lazy and cached, so multiple accesses don't reparse.
  ///
  /// For example, the URL '/search?q=dart&type=package&sort=popularity'
  /// would result in query parameters:
  /// - 'q' -> 'dart'
  /// - 'type' -> 'package'
  /// - 'sort' -> 'popularity'
  ///
  /// Example:
  /// ```dart
  /// // URL: /search?q=dart&limit=10
  /// final searchQuery = req.query['q'];     // 'dart'
  /// final limit = req.query['limit'];       // '10'
  /// final page = req.query['page'] ?? '1';  // '1' (default)
  /// ```
  Map<String, String> get query {
    _query ??= QueryParser.parseFromUri(_request.uri);
    return _query!;
  }

  /// The parsed request body.
  ///
  /// This property provides access to the request body after it has been
  /// parsed by body parser middleware. The type of the returned value depends
  /// on the Content-Type of the request:
  ///
  /// - JSON requests: Map<String, dynamic> or List<dynamic>
  /// - Form-encoded requests: Map<String, String>
  /// - Text requests: String
  /// - Other types: String (raw body)
  ///
  /// Throws [StateError] if the body has not been parsed yet. Use body parser
  /// middleware or call [parseBody] manually before accessing this property.
  ///
  /// Example:
  /// ```dart
  /// app.use(bodyParser()); // Required for body parsing
  ///
  /// app.post('/users', (req, res) async {
  ///   final userData = req.body as Map<String, dynamic>;
  ///   final name = userData['name'];
  ///   final email = userData['email'];
  ///   // Process user creation...
  /// });
  /// ```
  dynamic get body {
    if (!_bodyParsed) {
      throw StateError(
        'Request body has not been parsed. Use body parser middleware or call parseBody() first.',
      );
    }
    return _body;
  }

  /// Get the raw request body as bytes.
  ///
  /// This property reads and caches the raw request body data as bytes.
  /// Subsequent calls return the cached value.
  ///
  /// Returns the complete request body as bytes.
  Future<List<int>> get rawBytes async {
    if (_rawBytes != null) return _rawBytes!;

    _rawBytes = await _request
        .fold<List<int>>([], (previous, element) => previous..addAll(element));
    return _rawBytes!;
  }

  /// Get the raw request body as a string.
  ///
  /// This property reads and caches the raw request body data. It reads
  /// all bytes from the request stream and decodes them as UTF-8 text.
  /// Subsequent calls return the cached value.
  ///
  /// This is useful when you need to access the raw body data or implement
  /// custom parsing logic.
  ///
  /// Returns the complete request body as a string.
  ///
  /// Example:
  /// ```dart
  /// app.post('/webhook', (req, res) async {
  ///   final rawData = await req.rawBody;
  ///   final signature = req.header('x-signature');
  ///
  ///   if (await verifySignature(rawData, signature)) {
  ///     // Process webhook...
  ///   }
  /// });
  /// ```
  Future<String> get rawBody async {
    if (_rawBody != null) return _rawBody!;

    final bytes = await rawBytes;
    _rawBody = utf8.decode(bytes);
    return _rawBody!;
  }

  /// Parse the request body based on its Content-Type header.
  ///
  /// This method reads the request body and parses it according to the
  /// Content-Type header. Supported content types:
  ///
  /// - `application/json`: Parses as JSON (Map or List)
  /// - `application/x-www-form-urlencoded`: Parses as form data (Map<String, String>)
  /// - `text/*`: Keeps as string
  /// - Other types: Keeps as string
  ///
  /// [maxBodySize] Maximum allowed body size in bytes (default: 1MB)
  ///
  /// Throws [Exception] if the body size exceeds [maxBodySize].
  /// Throws [FormatException] if JSON parsing fails.
  ///
  /// Example:
  /// ```dart
  /// app.post('/data', (req, res) async {
  ///   await req.parseBody(maxBodySize: 5 * 1024 * 1024); // 5MB limit
  ///   final data = req.body;
  ///   // Process parsed data...
  /// });
  /// ```
  Future<void> parseBody({int maxBodySize = 1024 * 1024}) async {
    if (_bodyParsed) return;

    final contentLength = _request.contentLength;
    if (contentLength > maxBodySize) {
      throw Exception('Request body too large: $contentLength bytes');
    }

    final contentType = _request.headers.contentType;

    if (ContentTypeUtils.isMultipart(contentType)) {
      // Handle multipart data with raw bytes to avoid UTF-8 decoding issues
      final rawBodyBytes = await rawBytes;
      _body = await _parseMultipartBodyFromBytes(rawBodyBytes, contentType);
    } else {
      // For other content types, decode as UTF-8 string first
      final rawBodyString = await rawBody;
      
      if (ContentTypeUtils.isJson(contentType)) {
        try {
          _body = jsonDecode(rawBodyString);
        } catch (e) {
          throw FormatException('Invalid JSON in request body: $e');
        }
      } else if (ContentTypeUtils.isFormData(contentType)) {
        _body = QueryParser.parse(rawBodyString);
      } else {
        _body = rawBodyString;
      }
    }

    _bodyParsed = true;
  }

  /// Get all cookies sent with this request.
  ///
  /// Returns a list of Cookie objects representing all cookies
  /// included in the request's Cookie header.
  ///
  /// Example:
  /// ```dart
  /// final allCookies = req.cookies;
  /// for (final cookie in allCookies) {
  ///   print('${cookie.name}=${cookie.value}');
  /// }
  /// ```
  List<Cookie> get cookies => _request.cookies;

  /// Get the value of a specific cookie by name.
  ///
  /// [name] The name of the cookie to retrieve
  ///
  /// Returns the cookie value or `null` if the cookie is not present.
  ///
  /// Example:
  /// ```dart
  /// final sessionId = req.cookie('session_id');
  /// final userPrefs = req.cookie('user_preferences');
  ///
  /// if (sessionId != null) {
  ///   // User has a session
  /// }
  /// ```
  String? cookie(String name) {
    for (final cookie in _request.cookies) {
      if (cookie.name == name) {
        return cookie.value;
      }
    }
    return null;
  }

  /// Get the client's IP address.
  ///
  /// This method attempts to determine the real client IP by checking
  /// proxy headers in the following order:
  /// 1. X-Forwarded-For header (takes the first IP)
  /// 2. X-Real-IP header
  /// 3. Direct connection IP from socket
  ///
  /// Returns the IP address as a string, or 'unknown' if it cannot be determined.
  ///
  /// Example:
  /// ```dart
  /// app.get('/client-info', (req, res) async {
  ///   await res.json({
  ///     'ip': req.ip,
  ///     'user_agent': req.userAgent,
  ///   });
  /// });
  /// ```
  String get ip {
    // Check for forwarded headers first
    final forwarded = header('x-forwarded-for');
    if (forwarded != null && forwarded.isNotEmpty) {
      return forwarded.split(',').first.trim();
    }

    final realIp = header('x-real-ip');
    if (realIp != null && realIp.isNotEmpty) {
      return realIp;
    }

    return _request.connectionInfo?.remoteAddress.address ?? 'unknown';
  }

  /// Get the hostname from the Host header.
  ///
  /// Returns the hostname portion of the Host header, or 'localhost'
  /// if no Host header is present.
  ///
  /// Example:
  /// ```dart
  /// print(req.hostname); // 'api.example.com'
  /// ```
  String get hostname => _request.headers.host ?? 'localhost';

  /// Check if the request Content-Type is JSON.
  ///
  /// Returns `true` if the Content-Type header indicates JSON data
  /// (application/json), `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// if (req.isJson) {
  ///   final jsonData = req.body as Map<String, dynamic>;
  ///   // Process JSON data...
  /// }
  /// ```
  bool get isJson => ContentTypeUtils.isJson(_request.headers.contentType);

  /// Check if the request Content-Type is form-encoded data.
  ///
  /// Returns `true` if the Content-Type header indicates form data
  /// (application/x-www-form-urlencoded), `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// if (req.isFormData) {
  ///   final formData = req.body as Map<String, String>;
  ///   // Process form data...
  /// }
  /// ```
  bool get isFormData =>
      ContentTypeUtils.isFormData(_request.headers.contentType);

  /// Check if the request Content-Type is multipart data.
  ///
  /// Returns `true` if the Content-Type header indicates multipart data
  /// (multipart/form-data), `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// if (req.isMultipart) {
  ///   // Handle file upload or multipart form
  /// }
  /// ```
  bool get isMultipart =>
      ContentTypeUtils.isMultipart(_request.headers.contentType);

  /// Get the Content-Type header as a ContentType object.
  ///
  /// Returns the parsed ContentType object from the request headers,
  /// or `null` if no Content-Type header is present.
  ///
  /// Example:
  /// ```dart
  /// final ct = req.contentType;
  /// if (ct != null) {
  ///   print('MIME type: ${ct.mimeType}');
  ///   print('Charset: ${ct.charset}');
  /// }
  /// ```
  ContentType? get contentType => _request.headers.contentType;

  /// Check if the request accepts a specific content type.
  ///
  /// This method checks the Accept header to determine if the client
  /// can handle responses with the specified content type.
  ///
  /// [contentType] The MIME type to check (e.g., 'application/json')
  ///
  /// Returns `true` if the client accepts the content type, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// if (req.accepts('application/json')) {
  ///   await res.json(data);
  /// } else {
  ///   await res.send(data.toString());
  /// }
  /// ```
  bool accepts(String contentType) {
    final acceptHeader = header('accept');
    if (acceptHeader == null) return false;
    return acceptHeader.contains(contentType) || acceptHeader.contains('*/*');
  }

  /// Get the User-Agent header value.
  ///
  /// Returns the User-Agent string sent by the client, or 'Unknown'
  /// if no User-Agent header is present.
  ///
  /// Example:
  /// ```dart
  /// final agent = req.userAgent;
  /// if (agent.contains('Mobile')) {
  ///   // Serve mobile-optimized content
  /// }
  /// ```
  String get userAgent => header('user-agent') ?? 'Unknown';

  /// Check if this is a secure (HTTPS) request.
  ///
  /// This method checks both direct HTTPS connections and proxied
  /// connections by examining:
  /// 1. The X-Forwarded-Proto header (for requests behind proxies)
  /// 2. The request URI scheme
  ///
  /// Returns `true` if the request is secure, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// if (!req.isSecure) {
  ///   // Redirect to HTTPS
  ///   await res.redirect('https://${req.hostname}${req.path}');
  ///   return;
  /// }
  /// ```
  bool get isSecure {
    return header('x-forwarded-proto') == 'https' ||
        _request.uri.scheme == 'https';
  }

  /// Get the request protocol (http or https).
  ///
  /// Returns 'https' for secure requests and 'http' for insecure requests.
  /// Uses the same logic as [isSecure] to determine security.
  ///
  /// Example:
  /// ```dart
  /// final fullUrl = '${req.protocol}://${req.hostname}${req.path}';
  /// ```
  String get protocol => isSecure ? 'https' : 'http';

  /// Returns a string representation of this request.
  ///
  /// Format: 'Request(METHOD path)'
  ///
  /// Example: 'Request(GET /users/123)'
  @override
  String toString() {
    return 'Request($method $path)';
  }

  /// Parse multipart/form-data body into a map with form fields and files.
  ///
  /// This method parses multipart request bodies, which are commonly used 
  /// for file uploads and forms with mixed content types.
  ///
  /// Returns a Map with:
  /// - String keys for form field names
  /// - Values can be either String (for text fields) or Map (for files)
  /// - File entries contain: {name, filename, contentType, data}
  ///
  /// Example:
  /// ```dart
  /// app.post('/upload', (req, res) async {
  ///   await req.parseBody();
  ///   final body = req.body as Map<String, dynamic>;
  ///   
  ///   final textField = body['description'] as String?;
  ///   final fileField = body['file'] as Map<String, dynamic>?;
  ///   
  ///   if (fileField != null) {
  ///     final filename = fileField['filename'] as String;
  ///     final data = fileField['data'] as List<int>;
  ///     // Process uploaded file...
  ///   }
  /// });
  /// ```
  Future<Map<String, dynamic>> _parseMultipartBodyFromBytes(List<int> bodyBytes, ContentType? contentType) async {
    if (contentType == null) {
      throw FormatException('Missing content type for multipart data');
    }

    // Extract boundary from content type
    final boundary = contentType.parameters['boundary'];
    if (boundary == null) {
      throw FormatException('Missing boundary in multipart content type');
    }

    final result = <String, dynamic>{};
    final boundaryBytes = utf8.encode('--$boundary');
    
    // Find parts separated by boundaries
    final parts = <List<int>>[];
    int start = 0;
    
    while (true) {
      final boundaryIndex = _indexOfBytes(bodyBytes, boundaryBytes, start);
      if (boundaryIndex == -1) break;
      
      if (start > 0) {
        // Extract part data (skip boundary and CRLF)
        final partEnd = boundaryIndex - 2; // Remove trailing CRLF
        if (partEnd > start) {
          parts.add(bodyBytes.sublist(start, partEnd));
        }
      }
      
      start = boundaryIndex + boundaryBytes.length + 2; // Skip boundary and CRLF
      
      // Check for final boundary (ends with --)
      if (start < bodyBytes.length - 1 && 
          bodyBytes[start] == 45 && bodyBytes[start + 1] == 45) {
        break;
      }
    }

    // Parse each part
    for (final partBytes in parts) {
      // First, find the header/body boundary by looking for double CRLF
      int headerEndIndex = -1;
      for (int i = 0; i < partBytes.length - 3; i++) {
        if (partBytes[i] == 13 && partBytes[i + 1] == 10 && // \r\n
            partBytes[i + 2] == 13 && partBytes[i + 3] == 10) { // \r\n
          headerEndIndex = i + 4; // Start of body
          break;
        }
      }
      
      if (headerEndIndex == -1) continue;
      
      // Decode only the headers portion as UTF-8
      final headerBytes = partBytes.sublist(0, headerEndIndex - 4);
      final headerString = utf8.decode(headerBytes);
      final lines = headerString.split('\r\n');
      
      // Parse headers
      final headers = <String, String>{};
      
      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty) break;
        
        final colonIndex = trimmedLine.indexOf(':');
        if (colonIndex > 0) {
          final key = trimmedLine.substring(0, colonIndex).trim().toLowerCase();
          final value = trimmedLine.substring(colonIndex + 1).trim();
          headers[key] = value;
        }
      }
      
      // Extract content disposition
      final disposition = headers['content-disposition'];
      if (disposition == null) continue;
      
      final nameMatch = RegExp(r'name="([^"]*)"').firstMatch(disposition);
      if (nameMatch == null) continue;
      
      final fieldName = nameMatch.group(1)!;
      final filenameMatch = RegExp(r'filename="([^"]*)"').firstMatch(disposition);
      
      // Get field data as raw bytes (everything after headers)
      final dataBytes = partBytes.sublist(headerEndIndex);
      
      if (filenameMatch != null) {
        // File field - keep data as raw bytes for binary files
        final filename = filenameMatch.group(1)!;
        final contentType = headers['content-type'] ?? 'application/octet-stream';
        
        result[fieldName] = {
          'filename': filename,
          'contentType': contentType,
          'data': dataBytes, // Raw bytes - no double encoding
          'size': dataBytes.length,
        };
      } else {
        // Text field - decode as UTF-8 string
        final data = utf8.decode(dataBytes);
        result[fieldName] = data;
      }
    }

    return result;
  }

  /// Helper method to find byte sequence in a larger byte array
  int _indexOfBytes(List<int> haystack, List<int> needle, int start) {
    if (needle.isEmpty || start >= haystack.length) return -1;
    
    for (int i = start; i <= haystack.length - needle.length; i++) {
      bool found = true;
      for (int j = 0; j < needle.length; j++) {
        if (haystack[i + j] != needle[j]) {
          found = false;
          break;
        }
      }
      if (found) return i;
    }
    return -1;
  }
}
