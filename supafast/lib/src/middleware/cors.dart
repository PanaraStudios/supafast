import '../core/middleware.dart';

/// CORS (Cross-Origin Resource Sharing) middleware that handles cross-origin requests.
///
/// CORS is a security mechanism that allows servers to specify which origins, methods,
/// and headers are allowed when accessing resources from a different domain. This middleware
/// automatically handles CORS headers and preflight requests.
///
/// Example:
/// ```dart
/// // Allow all origins (not recommended for production)
/// app.use(corsAll());
///
/// // Configure specific origins and methods
/// app.use(cors(
///   origins: ['https://example.com', 'https://app.example.com'],
///   methods: ['GET', 'POST', 'PUT', 'DELETE'],
///   allowedHeaders: ['Content-Type', 'Authorization'],
///   credentials: true,
///   maxAge: 3600,
/// ));
///
/// // Simple CORS for development
/// app.use(cors(origins: ['http://localhost:3000']));
/// ```
///
/// Configuration options:
/// - **origins**: List of allowed origins. Use ['*'] for all origins or specific URLs
/// - **methods**: Allowed HTTP methods. Defaults to common REST methods
/// - **allowedHeaders**: Headers that clients can include in requests
/// - **exposedHeaders**: Headers that clients can access in responses
/// - **credentials**: Whether to allow credentials (cookies, auth headers)
/// - **maxAge**: How long browsers can cache preflight responses (seconds)
/// - **optionsSuccessStatus**: Status code for successful OPTIONS requests (204 or 200)
///
/// Security considerations:
/// - Never use ['*'] for origins in production when credentials are enabled
/// - Be specific about allowed headers to prevent security vulnerabilities
/// - Set appropriate maxAge to reduce preflight request overhead
///
/// [origins] List of allowed origin URLs. Use ['*'] to allow all origins.
/// [methods] List of allowed HTTP methods. Defaults to common REST methods.
/// [allowedHeaders] List of headers that can be included in requests.
/// [exposedHeaders] List of headers that browsers can access in responses.
/// [credentials] Whether to allow credentials like cookies and auth headers.
/// [maxAge] Cache duration for preflight responses in seconds.
/// [optionsSuccessStatus] Whether OPTIONS requests return 200 (true) or 204 (false).
///
/// Returns a [Middleware] function that handles CORS for all requests.
///
/// Throws no exceptions directly, but malformed requests may result in appropriate HTTP responses.
Middleware cors({
  List<String>? origins,
  List<String>? methods,
  List<String>? allowedHeaders,
  List<String>? exposedHeaders,
  bool credentials = false,
  int? maxAge,
  bool optionsSuccessStatus = false,
}) {
  return (req, res, next) async {
    // Determine allowed origin
    String allowedOrigin = '*';
    if (origins != null && origins.isNotEmpty) {
      final requestOrigin = req.header('origin');
      if (requestOrigin != null && origins.contains(requestOrigin)) {
        allowedOrigin = requestOrigin;
      } else if (origins.length == 1 && !origins.first.contains('*')) {
        allowedOrigin = origins.first;
      }
    }

    // Set CORS headers
    res.header('Access-Control-Allow-Origin', allowedOrigin);

    // Set credentials header if specified
    if (credentials) {
      res.header('Access-Control-Allow-Credentials', 'true');
    }

    // Handle preflight requests
    if (req.method == 'OPTIONS') {
      // Set allowed methods
      final allowedMethods =
          methods ?? ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'];
      res.header('Access-Control-Allow-Methods', allowedMethods.join(', '));

      // Set allowed headers
      if (allowedHeaders != null) {
        res.header('Access-Control-Allow-Headers', allowedHeaders.join(', '));
      } else {
        // Use requested headers if no specific headers are configured
        final requestedHeaders = req.header('access-control-request-headers');
        if (requestedHeaders != null) {
          res.header('Access-Control-Allow-Headers', requestedHeaders);
        }
      }

      // Set max age for preflight cache
      if (maxAge != null) {
        res.header('Access-Control-Max-Age', maxAge.toString());
      }

      // Send preflight response
      final statusCode = optionsSuccessStatus ? 200 : 204;
      return res.sendStatus(statusCode);
    }

    // Set exposed headers for actual requests
    if (exposedHeaders != null && exposedHeaders.isNotEmpty) {
      res.header('Access-Control-Expose-Headers', exposedHeaders.join(', '));
    }

    await next();
  };
}

/// Simple CORS middleware that allows all origins and methods.
///
/// This is a convenience function for development environments where you need
/// to quickly enable CORS without security restrictions. It allows all origins,
/// methods, and headers but disables credentials for security.
///
/// **Warning**: This should only be used in development environments.
/// For production, use the main [cors] function with specific origins.
///
/// Example:
/// ```dart
/// // Development setup - allows all origins
/// if (isDevelopment) {
///   app.use(corsAll());
/// }
/// ```
///
/// This is equivalent to:
/// ```dart
/// cors(
///   origins: ['*'],
///   methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS', 'HEAD'],
///   allowedHeaders: ['*'],
///   credentials: false,
/// )
/// ```
///
/// Returns a [Middleware] function configured for maximum compatibility.
Middleware corsAll() {
  return cors(
    origins: ['*'],
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS', 'HEAD'],
    allowedHeaders: ['*'],
    credentials: false,
  );
}
