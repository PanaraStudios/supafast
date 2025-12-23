import '../utils/path_matcher.dart';
import 'middleware.dart';

/// Represents a single HTTP route with its handler, middleware, and matching logic.
///
/// A Route encapsulates all the information needed to handle requests to a specific
/// path pattern and HTTP method combination. It includes the route handler function,
/// any route-specific middleware, and the compiled path pattern for efficient matching.
///
/// ## Basic Usage
///
/// Routes are typically created through Router methods, but can be created directly:
///
/// ```dart
/// final route = Route.create(
///   method: 'GET',
///   path: '/users/:id',
///   handler: (req, res) async {
///     final userId = req.params['id'];
///     await res.json({'id': userId});
///   },
/// );
/// ```
///
/// ## Path Patterns
///
/// Routes support Express.js-style path patterns:
/// - Static paths: `/users`, `/api/posts`
/// - Parameter paths: `/users/:id`, `/posts/:postId/comments/:commentId`
/// - Wildcard paths: `/files/*`, `/api/*/status`
///
/// ## Route Matching
///
/// The route matching process:
/// 1. Check if the HTTP method matches (case insensitive)
/// 2. Match the path pattern against the request path
/// 3. Extract path parameters if the pattern matches
/// 4. Return a RouteMatch with parameters or null if no match
class Route {
  /// The HTTP method this route responds to (GET, POST, PUT, DELETE, etc.)
  ///
  /// Stored in uppercase for consistent matching
  final String method;

  /// The original path pattern as specified when creating the route
  ///
  /// Examples: '/users/:id', '/api/posts', '/files/*'
  final String path;

  /// The handler function that processes requests matching this route
  ///
  /// This function receives Request and Response objects and handles
  /// the actual business logic for the route
  final Handler handler;

  /// List of middleware functions specific to this route
  ///
  /// These middleware functions are executed before the route handler,
  /// in addition to any router-level or global middleware
  final List<Middleware> middleware;

  /// The compiled path pattern used for efficient path matching
  ///
  /// This contains the regex pattern and parameter names extracted
  /// from the original path pattern
  final PathPattern pathPattern;

  /// Creates a new Route instance.
  ///
  /// This constructor is typically not used directly. Use [Route.create]
  /// instead, which automatically compiles the path pattern.
  ///
  /// [method] The HTTP method (should be uppercase)
  /// [path] The original path pattern
  /// [handler] The route handler function
  /// [middleware] List of route-specific middleware
  /// [pathPattern] The pre-compiled path pattern
  Route({
    required this.method,
    required this.path,
    required this.handler,
    required this.middleware,
    required this.pathPattern,
  });

  /// Create a route with automatic path pattern compilation.
  ///
  /// This is the recommended way to create Route instances. It automatically
  /// compiles the path pattern into an efficient regex for matching.
  ///
  /// [method] The HTTP method (case insensitive, will be converted to uppercase)
  /// [path] The path pattern (supports :param and * wildcards)
  /// [handler] The function to handle matching requests
  /// [middleware] Optional list of route-specific middleware
  ///
  /// Returns a new Route instance with compiled path pattern.
  ///
  /// Example:
  /// ```dart
  /// final userRoute = Route.create(
  ///   method: 'GET',
  ///   path: '/users/:id',
  ///   handler: (req, res) async {
  ///     final userId = req.params['id'];
  ///     final user = await getUserById(userId);
  ///     await res.json(user);
  ///   },
  ///   middleware: [validateUserAccess],
  /// );
  /// ```
  factory Route.create({
    required String method,
    required String path,
    required Handler handler,
    List<Middleware>? middleware,
  }) {
    final pathPattern = PathMatcher.compile(path);

    return Route(
      method: method.toUpperCase(),
      path: path,
      handler: handler,
      middleware: middleware ?? [],
      pathPattern: pathPattern,
    );
  }

  /// Check if this route matches the given HTTP method and path.
  ///
  /// This method performs two checks:
  /// 1. Compares the HTTP method (case insensitive)
  /// 2. Attempts to match the path against the compiled pattern
  ///
  /// [method] The HTTP method to check (case insensitive)
  /// [path] The request path to match against this route's pattern
  ///
  /// Returns a [RouteMatch] containing extracted path parameters if the
  /// route matches, or `null` if there's no match.
  ///
  /// Example:
  /// ```dart
  /// final route = Route.create(
  ///   method: 'GET',
  ///   path: '/users/:id',
  ///   handler: handler,
  /// );
  ///
  /// final match1 = route.match('GET', '/users/123');
  /// // Returns RouteMatch with params: {'id': '123'}
  ///
  /// final match2 = route.match('POST', '/users/123');
  /// // Returns null (method doesn't match)
  ///
  /// final match3 = route.match('GET', '/posts/123');
  /// // Returns null (path doesn't match)
  /// ```
  RouteMatch? match(String method, String path) {
    // Check method first (case insensitive)
    if (this.method.toUpperCase() != method.toUpperCase()) {
      return null;
    }

    // Try to match the path pattern
    final pathMatch = PathMatcher.match(pathPattern, path);
    if (pathMatch == null) return null;

    return RouteMatch(
      params: pathMatch.params,
    );
  }

  /// Returns a string representation of this route.
  ///
  /// Format: 'Route(METHOD path)'
  ///
  /// Example: 'Route(GET /users/:id)'
  @override
  String toString() {
    return 'Route($method $path)';
  }

  /// Checks equality based on method and path.
  ///
  /// Two routes are considered equal if they have the same HTTP method
  /// and path pattern. This is used for route deduplication and comparison.
  ///
  /// [other] The object to compare with
  ///
  /// Returns `true` if the routes have the same method and path
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Route && other.method == method && other.path == path;
  }

  /// Returns a hash code based on method and path.
  ///
  /// This ensures that routes with the same method and path have
  /// the same hash code, making them work correctly in hash-based
  /// collections like Set and Map.
  @override
  int get hashCode => Object.hash(method, path);
}
