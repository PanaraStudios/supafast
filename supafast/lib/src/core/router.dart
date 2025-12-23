import 'route.dart';
import 'middleware.dart';

/// A router for organizing and managing collections of routes.
///
/// Router provides functionality for grouping related routes together,
/// applying middleware to groups of routes, and creating modular,
/// mountable route collections.
///
/// ## Basic Usage
///
/// ```dart
/// final router = Router();
///
/// // Add middleware to all routes in this router
/// router.use(authMiddleware);
///
/// // Define routes
/// router.get('/users', getUsersHandler);
/// router.post('/users', createUserHandler);
/// router.get('/users/:id', getUserHandler);
///
/// // Mount the router in your app
/// app.mount('/api', router); // Routes become /api/users, etc.
/// ```
///
/// ## Advanced Usage with Sub-routers
///
/// ```dart
/// final apiRouter = Router();
/// final usersRouter = Router();
/// final postsRouter = Router();
///
/// // Configure users routes
/// usersRouter.get('/', listUsers);
/// usersRouter.post('/', createUser);
/// usersRouter.get('/:id', getUser);
///
/// // Configure posts routes
/// postsRouter.get('/', listPosts);
/// postsRouter.post('/', createPost);
///
/// // Mount sub-routers
/// apiRouter.mount('/users', usersRouter);
/// apiRouter.mount('/posts', postsRouter);
///
/// // Mount main router
/// app.mount('/api', apiRouter);
/// // Results in: /api/users/, /api/posts/, etc.
/// ```
class Router {
  /// Internal list of routes managed by this router
  final List<Route> _routes = [];

  /// List of middleware applied to all routes in this router
  final List<Middleware> _middlewares = [];

  /// Add middleware that will be applied to all routes in this router.
  ///
  /// Middleware added to a router will be executed before any route handlers
  /// in that router, but after any global application middleware.
  ///
  /// [middleware] The middleware function to add
  ///
  /// Example:
  /// ```dart
  /// final adminRouter = Router();
  ///
  /// // Add authentication middleware to all admin routes
  /// adminRouter.use((req, res, next) async {
  ///   if (!await isAuthenticated(req)) {
  ///     return res.unauthorized('Access denied');
  ///   }
  ///   await next();
  /// });
  ///
  /// adminRouter.get('/dashboard', dashboardHandler);
  /// adminRouter.get('/users', adminUsersHandler);
  /// ```
  void use(Middleware middleware) {
    _middlewares.add(middleware);
  }

  /// Register a GET route in this router.
  ///
  /// [path] The route path pattern (e.g., '/users/:id')
  /// [handler] The function to handle GET requests to this route
  /// [middleware] Optional route-specific middleware
  ///
  /// Example:
  /// ```dart
  /// router.get('/users', (req, res) async {
  ///   await res.json(await getAllUsers());
  /// });
  /// ```
  void get(String path, Handler handler, [List<Middleware>? middleware]) {
    _addRoute('GET', path, handler, middleware);
  }

  /// Register a POST route in this router.
  ///
  /// [path] The route path pattern
  /// [handler] The function to handle POST requests to this route
  /// [middleware] Optional route-specific middleware
  ///
  /// Example:
  /// ```dart
  /// router.post('/users', (req, res) async {
  ///   final user = await createUser(req.body);
  ///   await res.status(201).json(user);
  /// });
  /// ```
  void post(String path, Handler handler, [List<Middleware>? middleware]) {
    _addRoute('POST', path, handler, middleware);
  }

  /// Register a PUT route in this router.
  ///
  /// [path] The route path pattern
  /// [handler] The function to handle PUT requests to this route
  /// [middleware] Optional route-specific middleware
  void put(String path, Handler handler, [List<Middleware>? middleware]) {
    _addRoute('PUT', path, handler, middleware);
  }

  /// Register a DELETE route in this router.
  ///
  /// [path] The route path pattern
  /// [handler] The function to handle DELETE requests to this route
  /// [middleware] Optional route-specific middleware
  void delete(String path, Handler handler, [List<Middleware>? middleware]) {
    _addRoute('DELETE', path, handler, middleware);
  }

  /// Register a PATCH route in this router.
  ///
  /// [path] The route path pattern
  /// [handler] The function to handle PATCH requests to this route
  /// [middleware] Optional route-specific middleware
  void patch(String path, Handler handler, [List<Middleware>? middleware]) {
    _addRoute('PATCH', path, handler, middleware);
  }

  /// Register an OPTIONS route in this router.
  ///
  /// [path] The route path pattern
  /// [handler] The function to handle OPTIONS requests to this route
  /// [middleware] Optional route-specific middleware
  void options(String path, Handler handler, [List<Middleware>? middleware]) {
    _addRoute('OPTIONS', path, handler, middleware);
  }

  /// Register a HEAD route in this router.
  ///
  /// [path] The route path pattern
  /// [handler] The function to handle HEAD requests to this route
  /// [middleware] Optional route-specific middleware
  void head(String path, Handler handler, [List<Middleware>? middleware]) {
    _addRoute('HEAD', path, handler, middleware);
  }

  /// Register a route that responds to all HTTP methods.
  ///
  /// This creates multiple route entries for the same path, one for each
  /// HTTP method (GET, POST, PUT, DELETE, PATCH, OPTIONS, HEAD).
  ///
  /// [path] The route path pattern
  /// [handler] The function to handle requests to this route
  /// [middleware] Optional route-specific middleware
  ///
  /// Example:
  /// ```dart
  /// router.all('/api/*', (req, res, next) async {
  ///   // CORS middleware for all API routes
  ///   res.header('Access-Control-Allow-Origin', '*');
  ///   await next();
  /// });
  /// ```
  void all(String path, Handler handler, [List<Middleware>? middleware]) {
    final methods = [
      'GET',
      'POST',
      'PUT',
      'DELETE',
      'PATCH',
      'OPTIONS',
      'HEAD'
    ];
    for (final method in methods) {
      _addRoute(method, path, handler, middleware);
    }
  }

  /// Internal method to add a route with a specific HTTP method.
  ///
  /// This method creates a Route object and adds it to the router's
  /// internal route collection.
  ///
  /// [method] The HTTP method (GET, POST, etc.)
  /// [path] The route path pattern
  /// [handler] The route handler function
  /// [middleware] Optional route-specific middleware
  void _addRoute(
    String method,
    String path,
    Handler handler,
    List<Middleware>? middleware,
  ) {
    final route = Route.create(
      method: method,
      path: path,
      handler: handler,
      middleware: middleware ?? [],
    );

    _routes.add(route);
  }

  /// Find a route that matches the given HTTP method and path.
  ///
  /// This method searches through all registered routes to find the first
  /// one that matches both the HTTP method and the path pattern.
  ///
  /// [method] The HTTP method to match (case insensitive)
  /// [path] The request path to match against route patterns
  ///
  /// Returns a [RouterMatch] containing the matched route, extracted path
  /// parameters, and applicable middleware, or `null` if no match is found.
  ///
  /// Example:
  /// ```dart
  /// final match = router.match('GET', '/users/123');
  /// if (match != null) {
  ///   print('Matched route: ${match.route}');
  ///   print('Parameters: ${match.params}'); // {'id': '123'}
  /// }
  /// ```
  RouterMatch? match(String method, String path) {
    for (final route in _routes) {
      final match = route.match(method, path);
      if (match != null) {
        return RouterMatch(
          route: route,
          params: match.params,
          middleware: [..._middlewares, ...route.middleware],
        );
      }
    }
    return null;
  }

  /// Get an unmodifiable list of all routes in this router.
  ///
  /// Returns a copy of the internal routes list to prevent external modification.
  ///
  /// Example:
  /// ```dart
  /// final allRoutes = router.routes;
  /// print('Router has ${allRoutes.length} routes');
  /// ```
  List<Route> get routes => List.unmodifiable(_routes);

  /// Get an unmodifiable list of all middleware in this router.
  ///
  /// Returns a copy of the internal middleware list to prevent external modification.
  ///
  /// Example:
  /// ```dart
  /// final middleware = router.middlewares;
  /// print('Router has ${middleware.length} middleware functions');
  /// ```
  List<Middleware> get middlewares => List.unmodifiable(_middlewares);

  /// Clear all routes and middleware from this router.
  ///
  /// This removes all registered routes and middleware, effectively
  /// resetting the router to its initial empty state.
  ///
  /// Example:
  /// ```dart
  /// router.get('/test', handler);
  /// print(router.routes.length); // 1
  /// router.clear();
  /// print(router.routes.length); // 0
  /// ```
  void clear() {
    _routes.clear();
    _middlewares.clear();
  }

  /// Mount another router under a path prefix.
  ///
  /// This allows you to combine multiple routers by mounting one router's
  /// routes under a specific path prefix. All routes from the mounted router
  /// will be prefixed with the given prefix.
  ///
  /// [prefix] The path prefix to add to all mounted routes
  /// [router] The router instance to mount
  ///
  /// Example:
  /// ```dart
  /// final apiRouter = Router();
  /// apiRouter.get('/users', getUsersHandler);
  /// apiRouter.post('/posts', createPostHandler);
  ///
  /// final mainRouter = Router();
  /// mainRouter.mount('/api/v1', apiRouter);
  /// // Results in routes: /api/v1/users, /api/v1/posts
  ///
  /// app.mount('/', mainRouter);
  /// ```
  void mount(String prefix, Router router) {
    // Add all routes from the mounted router with the prefix
    for (final route in router.routes) {
      final prefixedPath = _combinePaths(prefix, route.path);

      _addRoute(
        route.method,
        prefixedPath,
        route.handler,
        route.middleware,
      );
    }

    // Add all middleware from the mounted router
    _middlewares.addAll(router.middlewares);
  }

  /// Internal method to combine a prefix path with a route path.
  ///
  /// This method handles the proper joining of path segments, ensuring
  /// proper slash handling and avoiding double slashes.
  ///
  /// [prefix] The prefix path (e.g., '/api')
  /// [path] The route path (e.g., '/users')
  ///
  /// Returns the combined path (e.g., '/api/users')
  String _combinePaths(String prefix, String path) {
    // Remove trailing slash from prefix
    var cleanPrefix = prefix.endsWith('/') && prefix.length > 1
        ? prefix.substring(0, prefix.length - 1)
        : prefix;

    // Ensure path starts with /
    var cleanPath = path.startsWith('/') ? path : '/$path';

    // Handle root path
    if (cleanPath == '/') {
      return cleanPrefix == '' ? '/' : cleanPrefix;
    }

    return cleanPrefix + cleanPath;
  }

  /// Returns a string representation of this router.
  ///
  /// Shows the number of routes and middleware functions registered
  /// in this router.
  ///
  /// Example: 'Router(5 routes, 2 middleware)'
  @override
  String toString() {
    return 'Router(${_routes.length} routes, ${_middlewares.length} middleware)';
  }
}

/// Result of matching a route in a router.
///
/// This class encapsulates the result of a successful route match,
/// including the matched route, extracted path parameters, and
/// the complete middleware chain to execute.
class RouterMatch {
  /// The route that was matched
  final Route route;

  /// Path parameters extracted from the route pattern
  ///
  /// For example, a route pattern '/users/:id' matched against '/users/123'
  /// would produce params = {'id': '123'}
  final Map<String, String> params;

  /// Complete middleware chain including router middleware and route middleware
  final List<Middleware> middleware;

  /// Creates a new router match result.
  ///
  /// [route] The matched route
  /// [params] Path parameters extracted from the URL
  /// [middleware] Complete middleware chain to execute
  const RouterMatch({
    required this.route,
    required this.params,
    required this.middleware,
  });
}
