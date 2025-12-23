import 'dart:async';
import 'dart:io';

import 'middleware.dart';
import 'request.dart';
import 'response.dart';
import 'router.dart';
import '../exceptions/http_exception.dart';

/// The main Supafast application class that serves as the entry point for creating
/// high-performance HTTP servers in Dart.
///
/// Supafast provides an Express.js-like API for building web applications and APIs,
/// including middleware support, routing, and automatic request/response handling.
///
/// ## Basic Usage
///
/// ```dart
/// final app = Supafast();
///
/// // Add middleware
/// app.use(logger());
/// app.use(cors());
/// app.use(bodyParser());
///
/// // Define routes
/// app.get('/api/users/:id', (req, res) async {
///   final userId = req.params['id'];
///   await res.json({'id': userId, 'name': 'John Doe'});
/// });
///
/// // Start the server
/// await app.listen(3000);
/// print('Server running on port 3000');
/// ```
///
/// ## Advanced Usage with Error Handling
///
/// ```dart
/// final app = Supafast();
///
/// app.use(errorHandler());
/// app.use(compression());
/// app.use(serveStatic('public'));
///
/// app.get('/api/health', (req, res) async {
///   await res.json({'status': 'ok', 'uptime': app.uptime?.inSeconds});
/// });
///
/// app.post('/api/data', (req, res) async {
///   final data = req.body;
///   // Process data
///   await res.status(201).json({'message': 'Created', 'data': data});
/// });
///
/// await app.serve(8080);
/// ```
class Supafast {
  /// Internal router for managing all routes
  final Router _router = Router();

  /// List of global middleware applied to all requests
  final List<Middleware> _middlewares = [];

  /// The underlying HTTP server instance
  HttpServer? _server;

  /// Timestamp when the server was started
  DateTime? _startTime;

  /// Get the underlying router instance for advanced routing operations.
  ///
  /// This allows access to the router's methods for mounting sub-routers
  /// or performing complex routing operations.
  ///
  /// Example:
  /// ```dart
  /// final apiRouter = Router();
  /// apiRouter.get('/users', getUsersHandler);
  /// app.router.mount('/api', apiRouter);
  /// ```
  Router get router => _router;

  /// Get the application uptime since the server started.
  ///
  /// Returns [null] if the server is not currently running.
  /// Otherwise returns a [Duration] representing how long the server
  /// has been running.
  ///
  /// Example:
  /// ```dart
  /// final uptime = app.uptime;
  /// if (uptime != null) {
  ///   print('Server has been running for ${uptime.inMinutes} minutes');
  /// }
  /// ```
  Duration? get uptime {
    if (_startTime == null) return null;
    return DateTime.now().difference(_startTime!);
  }

  /// Add global middleware that will be executed for every request.
  ///
  /// Middleware functions are executed in the order they are added.
  /// They can modify the request, response, or stop the chain by not
  /// calling the `next` function.
  ///
  /// [middleware] The middleware function to add
  ///
  /// Example:
  /// ```dart
  /// app.use(logger()); // Log all requests
  /// app.use(cors()); // Enable CORS for all routes
  /// app.use(bodyParser()); // Parse request bodies
  /// ```
  void use(Middleware middleware) {
    _middlewares.add(middleware);
  }

  /// Register a GET route handler.
  ///
  /// [path] The route path pattern (e.g., '/users/:id')
  /// [handler] The function to handle requests to this route
  /// [middleware] Optional route-specific middleware
  ///
  /// Example:
  /// ```dart
  /// app.get('/users/:id', (req, res) async {
  ///   final id = req.params['id'];
  ///   await res.json({'id': id});
  /// });
  /// ```
  void get(String path, Handler handler, [List<Middleware>? middleware]) {
    _router.get(path, handler, middleware);
  }

  /// Register a POST route handler.
  ///
  /// [path] The route path pattern
  /// [handler] The function to handle POST requests to this route
  /// [middleware] Optional route-specific middleware
  ///
  /// Example:
  /// ```dart
  /// app.post('/users', (req, res) async {
  ///   final userData = req.body;
  ///   // Create user logic
  ///   await res.status(201).json({'message': 'User created'});
  /// });
  /// ```
  void post(String path, Handler handler, [List<Middleware>? middleware]) {
    _router.post(path, handler, middleware);
  }

  /// Register a PUT route handler for updating resources.
  ///
  /// [path] The route path pattern
  /// [handler] The function to handle PUT requests to this route
  /// [middleware] Optional route-specific middleware
  ///
  /// Example:
  /// ```dart
  /// app.put('/users/:id', (req, res) async {
  ///   final id = req.params['id'];
  ///   final updates = req.body;
  ///   // Update user logic
  ///   await res.json({'message': 'User updated'});
  /// });
  /// ```
  void put(String path, Handler handler, [List<Middleware>? middleware]) {
    _router.put(path, handler, middleware);
  }

  /// Register a DELETE route handler for removing resources.
  ///
  /// [path] The route path pattern
  /// [handler] The function to handle DELETE requests to this route
  /// [middleware] Optional route-specific middleware
  ///
  /// Example:
  /// ```dart
  /// app.delete('/users/:id', (req, res) async {
  ///   final id = req.params['id'];
  ///   // Delete user logic
  ///   await res.status(204).send('');
  /// });
  /// ```
  void delete(String path, Handler handler, [List<Middleware>? middleware]) {
    _router.delete(path, handler, middleware);
  }

  /// Register a PATCH route handler for partial resource updates.
  ///
  /// [path] The route path pattern
  /// [handler] The function to handle PATCH requests to this route
  /// [middleware] Optional route-specific middleware
  ///
  /// Example:
  /// ```dart
  /// app.patch('/users/:id', (req, res) async {
  ///   final id = req.params['id'];
  ///   final changes = req.body;
  ///   // Apply partial updates
  ///   await res.json({'message': 'User partially updated'});
  /// });
  /// ```
  void patch(String path, Handler handler, [List<Middleware>? middleware]) {
    _router.patch(path, handler, middleware);
  }

  /// Register an OPTIONS route handler for CORS preflight requests.
  ///
  /// [path] The route path pattern
  /// [handler] The function to handle OPTIONS requests to this route
  /// [middleware] Optional route-specific middleware
  ///
  /// Example:
  /// ```dart
  /// app.options('/api/*', (req, res) async {
  ///   await res.header('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE')
  ///             .sendStatus(200);
  /// });
  /// ```
  void options(String path, Handler handler, [List<Middleware>? middleware]) {
    _router.options(path, handler, middleware);
  }

  /// Register a HEAD route handler for metadata-only responses.
  ///
  /// [path] The route path pattern
  /// [handler] The function to handle HEAD requests to this route
  /// [middleware] Optional route-specific middleware
  ///
  /// Example:
  /// ```dart
  /// app.head('/users/:id', (req, res) async {
  ///   final id = req.params['id'];
  ///   // Check if resource exists and set headers
  ///   await res.sendStatus(200);
  /// });
  /// ```
  void head(String path, Handler handler, [List<Middleware>? middleware]) {
    _router.head(path, handler, middleware);
  }

  /// Register a route that responds to all HTTP methods.
  ///
  /// This is useful for middleware that should apply to all methods
  /// on a specific path, or for catch-all handlers.
  ///
  /// [path] The route path pattern
  /// [handler] The function to handle requests to this route
  /// [middleware] Optional route-specific middleware
  ///
  /// Example:
  /// ```dart
  /// app.all('/api/*', (req, res, next) async {
  ///   // Authentication middleware for all API routes
  ///   if (req.header('authorization') == null) {
  ///     return res.unauthorized('Token required');
  ///   }
  ///   await next();
  /// });
  /// ```
  void all(String path, Handler handler, [List<Middleware>? middleware]) {
    _router.all(path, handler, middleware);
  }

  /// Mount a sub-router with a path prefix.
  ///
  /// This allows you to organize routes into modular routers
  /// and mount them at specific path prefixes.
  ///
  /// [prefix] The path prefix for all routes in the mounted router
  /// [router] The router instance to mount
  ///
  /// Example:
  /// ```dart
  /// final apiRouter = Router();
  /// apiRouter.get('/users', getUsersHandler);
  /// apiRouter.post('/users', createUserHandler);
  ///
  /// final adminRouter = Router();
  /// adminRouter.get('/stats', getStatsHandler);
  ///
  /// app.mount('/api', apiRouter); // Routes: /api/users
  /// app.mount('/admin', adminRouter); // Routes: /admin/stats
  /// ```
  void mount(String prefix, Router router) {
    _router.mount(prefix, router);
  }

  /// Start the HTTP server and begin listening for requests.
  ///
  /// This method starts the server but does not block. Use [serve] instead
  /// if you want the server to run indefinitely.
  ///
  /// [port] The port number to listen on
  /// [hostname] The hostname/IP to bind to (default: '0.0.0.0' for all interfaces)
  /// [backlog] The maximum number of pending connections (default: 0)
  /// [v6Only] Whether to only accept IPv6 connections (default: false)
  /// [shared] Whether to allow port sharing (default: false)
  ///
  /// Throws [StateError] if the server is already listening.
  ///
  /// Example:
  /// ```dart
  /// final app = Supafast();
  /// app.get('/', (req, res) => res.send('Hello World'));
  ///
  /// await app.listen(3000);
  /// print('Server listening on port 3000');
  /// // Server is now running, but function continues
  /// ```
  Future<void> listen(
    int port, {
    String hostname = '0.0.0.0',
    int? backlog,
    bool v6Only = false,
    bool shared = false,
  }) async {
    if (_server != null) {
      throw StateError('Server is already listening');
    }

    try {
      _server = await HttpServer.bind(
        hostname,
        port,
        backlog: backlog ?? 0,
        v6Only: v6Only,
        shared: shared,
      );

      _startTime = DateTime.now();

      // Log server startup
      final displayHost = hostname == '0.0.0.0' ? 'localhost' : hostname;
      print('🚀 Supafast server started at http://$displayHost:$port');

      // Handle requests
      await for (final request in _server!) {
        // Handle request in a separate async context to avoid blocking
        // the server's request handling loop
        _handleRequest(request).catchError((error, stackTrace) {
          // Log error but don't crash the server
          print('Unhandled error in request handler: $error');
          print('Stack trace: $stackTrace');

          // Try to send error response if possible
          if (!request.response.headers.chunkedTransferEncoding) {
            try {
              request.response
                ..statusCode = HttpStatus.internalServerError
                ..headers.contentType = ContentType.json
                ..write('{"error":"Internal Server Error"}');
              request.response.close();
            } catch (_) {
              // Ignore errors when trying to send error response
            }
          }
        });
      }
    } catch (e) {
      await close();
      rethrow;
    }
  }

  /// Start the HTTP server and keep it running indefinitely.
  ///
  /// This method starts the server and blocks until the server is manually
  /// closed. This is typically used in production scenarios where you want
  /// the server to run continuously.
  ///
  /// [port] The port number to listen on
  /// [hostname] The hostname/IP to bind to (default: '0.0.0.0' for all interfaces)
  /// [backlog] The maximum number of pending connections (default: 0)
  /// [v6Only] Whether to only accept IPv6 connections (default: false)
  /// [shared] Whether to allow port sharing (default: false)
  ///
  /// Example:
  /// ```dart
  /// final app = Supafast();
  /// app.get('/', (req, res) => res.send('Hello World'));
  ///
  /// print('Starting server on port 8080...');
  /// await app.serve(8080); // This will block
  /// print('Server stopped'); // This line won't run until server stops
  /// ```
  Future<void> serve(
    int port, {
    String hostname = '0.0.0.0',
    int? backlog,
    bool v6Only = false,
    bool shared = false,
  }) async {
    await listen(
      port,
      hostname: hostname,
      backlog: backlog,
      v6Only: v6Only,
      shared: shared,
    );

    _server?.serverHeader = null; // Remove default server header

    // This will keep the server running until manually stopped
    while (_server != null) {
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  /// Stop the HTTP server and clean up resources.
  ///
  /// [force] Whether to forcefully close active connections (default: false)
  ///
  /// When [force] is false, the server will stop accepting new connections
  /// but wait for existing connections to finish. When [force] is true,
  /// all connections are immediately terminated.
  ///
  /// Example:
  /// ```dart
  /// // Graceful shutdown
  /// await app.close();
  ///
  /// // Force shutdown (immediate)
  /// await app.close(force: true);
  /// ```
  Future<void> close({bool force = false}) async {
    if (_server != null) {
      await _server!.close(force: force);
      _server = null;
      _startTime = null;
    }
  }

  /// Handle an incoming HTTP request through the middleware and routing chain.
  ///
  /// This is an internal method that processes each incoming request by:
  /// 1. Wrapping the HTTP request/response in Supafast objects
  /// 2. Executing global middleware first (Express.js pattern)
  /// 3. Finding a matching route if middleware doesn't handle the request
  /// 4. Executing route middleware and handler
  /// 5. Handling any errors that occur
  ///
  /// [httpRequest] The raw HTTP request from the server
  Future<void> _handleRequest(HttpRequest httpRequest) async {
    final request = Request(httpRequest);
    final response = Response(httpRequest.response);

    try {
      // First, execute global middleware (this allows static files, auth, etc. to handle requests)
      if (_middlewares.isNotEmpty) {
        // Create a middleware chain with a special "route checking" middleware at the end
        final globalMiddlewareWithRouting = <Middleware>[
          ..._middlewares,
          // This middleware checks if the response was handled by previous middleware
          (req, res, next) async {
            if (!res.sent) {
              // Response not sent by global middleware, try route matching
              final routeMatch = _router.match(req.method, req.path);

              if (routeMatch != null) {
                // Set path parameters
                req.setParams(routeMatch.params);

                // Execute route middleware and handler
                final routeMiddleware = <Middleware>[
                  ...routeMatch.middleware,
                  // Convert handler to middleware for uniform execution
                  (req, res, next) async {
                    await routeMatch.route.handler(req, res);
                  },
                ];

                final routeChain = MiddlewareChain(routeMiddleware);
                await routeChain.execute(req, res);
              } else {
                // No route found and no middleware handled the request
                await res.notFound();
              }
            }
          },
        ];

        final globalChain = MiddlewareChain(globalMiddlewareWithRouting);
        await globalChain.execute(request, response);
      } else {
        // No global middleware, proceed directly to route matching
        final routeMatch = _router.match(request.method, request.path);

        if (routeMatch == null) {
          // No route found, send 404
          await response.notFound();
          return;
        }

        // Set path parameters
        request.setParams(routeMatch.params);

        // Build route middleware chain
        final routeMiddleware = <Middleware>[
          ...routeMatch.middleware,
          // Convert handler to middleware for uniform execution
          (req, res, next) async {
            await routeMatch.route.handler(req, res);
          },
        ];

        // Execute route middleware chain
        final chain = MiddlewareChain(routeMiddleware);
        await chain.execute(request, response);
      }

      // Ensure response is closed if not already sent
      if (!response.sent) {
        await response.close();
      }
    } catch (e, stackTrace) {
      await _handleError(e, stackTrace, request, response);
    }
  }

  /// Handle errors that occur during request processing.
  ///
  /// This method formats and sends appropriate error responses based on
  /// the type of error that occurred. It handles [HttpException] instances
  /// specially to preserve status codes and messages.
  ///
  /// [error] The error that occurred
  /// [stackTrace] The stack trace of the error
  /// [request] The request being processed
  /// [response] The response to send the error to
  Future<void> _handleError(
    dynamic error,
    StackTrace stackTrace,
    Request request,
    Response response,
  ) async {
    // Don't send error response if already sent
    if (response.sent) {
      print('Error after response sent: $error');
      return;
    }

    try {
      if (error is HttpException) {
        await response.status(error.statusCode).json({
          'error': error.message,
          'statusCode': error.statusCode,
        });
      } else {
        // Generic error
        print('Unhandled error: $error');
        print('Stack trace: $stackTrace');

        await response.status(500).json({
          'error': 'Internal Server Error',
          'statusCode': 500,
        });
      }
    } catch (e) {
      // Last resort - try to close the response
      print('Error sending error response: $e');
      try {
        await response.close();
      } catch (_) {
        // Nothing more we can do
      }
    }
  }

  /// Returns a string representation of the Supafast application instance.
  ///
  /// Shows the server status and listening address if the server is running.
  ///
  /// Returns:
  /// - 'Supafast(listening on {address}:{port})' if server is running
  /// - 'Supafast(not listening)' if server is not running
  @override
  String toString() {
    final port = _server?.port;
    final address = _server?.address.address;

    if (port != null && address != null) {
      return 'Supafast(listening on $address:$port)';
    }

    return 'Supafast(not listening)';
  }
}
