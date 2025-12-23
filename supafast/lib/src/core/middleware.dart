import 'dart:async';

import 'request.dart';
import 'response.dart';

/// Type definition for route handler functions.
///
/// A handler function processes HTTP requests and generates responses.
/// It receives a [Request] object containing request data and a [Response]
/// object for sending the response back to the client.
///
/// Handlers can be synchronous or asynchronous, hence the [FutureOr] return type.
///
/// Example:
/// ```dart
/// Handler myHandler = (req, res) async {
///   final userId = req.params['id'];
///   final user = await getUserById(userId);
///   await res.json(user);
/// };
/// ```
typedef Handler = FutureOr<void> Function(Request req, Response res);

/// Type definition for the next function in middleware chains.
///
/// The next function is used by middleware to pass control to the next
/// middleware function in the chain, or to the route handler if this
/// is the last middleware.
///
/// If an error is passed to next, it will skip remaining middleware
/// and trigger error handling.
///
/// Example:
/// ```dart
/// await next(); // Continue to next middleware
/// await next(Exception('Something went wrong')); // Trigger error handling
/// ```
typedef NextFunction = Future<void> Function([dynamic error]);

/// Type definition for middleware functions.
///
/// Middleware functions have access to the request and response objects,
/// and can:
/// - Modify the request or response
/// - Execute code before or after the route handler
/// - End the request-response cycle early
/// - Call the next middleware in the chain
///
/// Middleware can be synchronous or asynchronous, hence the [FutureOr] return type.
///
/// ## Basic Middleware Structure
///
/// ```dart
/// Middleware myMiddleware = (req, res, next) async {
///   // Code executed before route handler
///
///   await next(); // Call next middleware or route handler
///
///   // Code executed after route handler (if next() was called)
/// };
/// ```
///
/// ## Middleware Examples
///
/// Authentication middleware:
/// ```dart
/// Middleware authMiddleware = (req, res, next) async {
///   final token = req.header('authorization');
///   if (token == null) {
///     return res.unauthorized('Authentication required');
///   }
///
///   final user = await validateToken(token);
///   if (user == null) {
///     return res.unauthorized('Invalid token');
///   }
///
///   req.locals['user'] = user;
///   await next(); // User is authenticated, continue
/// };
/// ```
///
/// Logging middleware:
/// ```dart
/// Middleware loggingMiddleware = (req, res, next) async {
///   final start = DateTime.now();
///   print('${req.method} ${req.path} - Started');
///
///   await next();
///
///   final duration = DateTime.now().difference(start);
///   print('${req.method} ${req.path} - ${res.statusCode} (${duration.inMilliseconds}ms)');
/// };
/// ```
typedef Middleware = FutureOr<void> Function(
  Request req,
  Response res,
  NextFunction next,
);

/// Executes a chain of middleware functions in sequence.
///
/// The MiddlewareChain class manages the execution of multiple middleware
/// functions, ensuring they are called in the correct order and that each
/// middleware can pass control to the next one in the chain.
///
/// This class is used internally by the Supafast framework to execute
/// global middleware, router middleware, and route-specific middleware
/// before calling the final route handler.
///
/// ## Execution Flow
///
/// 1. Middleware functions are executed in the order they were added
/// 2. Each middleware can call `next()` to continue to the next middleware
/// 3. If a middleware doesn't call `next()`, the chain stops
/// 4. If an error is passed to `next(error)`, the chain stops and the error is thrown
///
/// Example:
/// ```dart
/// final middlewares = [
///   loggingMiddleware,
///   authenticationMiddleware,
///   validationMiddleware,
/// ];
///
/// final chain = MiddlewareChain(middlewares);
/// await chain.execute(request, response);
/// ```
class MiddlewareChain {
  /// List of middleware functions to execute
  final List<Middleware> middlewares;

  /// Current position in the middleware chain
  int _currentIndex = 0;

  /// Creates a new middleware chain with the given middleware functions.
  ///
  /// [middlewares] The list of middleware functions to execute in order
  MiddlewareChain(this.middlewares);

  /// Execute all middleware functions in the chain.
  ///
  /// This method starts the execution of the middleware chain, calling
  /// each middleware function in order. Each middleware can choose to
  /// call the next middleware in the chain or stop execution.
  ///
  /// [req] The request object to pass to middleware functions
  /// [res] The response object to pass to middleware functions
  ///
  /// Throws any error that is passed to a middleware's `next()` function.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await middlewareChain.execute(request, response);
  ///   print('All middleware executed successfully');
  /// } catch (error) {
  ///   print('Middleware error: $error');
  /// }
  /// ```
  Future<void> execute(Request req, Response res) async {
    if (_currentIndex >= middlewares.length) return;

    final middleware = middlewares[_currentIndex++];
    await middleware(req, res, ([error]) {
      if (error != null) {
        throw error;
      }
      return execute(req, res);
    });
  }

  /// Reset the middleware chain to its initial state.
  ///
  /// This method resets the internal index counter, allowing the same
  /// MiddlewareChain instance to be reused for multiple requests.
  ///
  /// Note: In normal usage, this method is not typically needed as new
  /// MiddlewareChain instances are created for each request.
  ///
  /// Example:
  /// ```dart
  /// final chain = MiddlewareChain(middlewares);
  /// await chain.execute(request1, response1);
  ///
  /// chain.reset(); // Reset for reuse
  /// await chain.execute(request2, response2);
  /// ```
  void reset() {
    _currentIndex = 0;
  }
}
