import 'package:test/test.dart';
import 'package:supafast/src/core/router.dart';

void main() {
  group('Router', () {
    late Router router;

    setUp(() {
      router = Router();
    });

    group('route registration', () {
      test('registers GET routes correctly', () {
        router.get('/test', (req, res) {});
        expect(router.routes.length, equals(1));
        expect(router.routes.first.method, equals('GET'));
      });

      test('registers POST routes correctly', () {
        router.post('/users', (req, res) {});
        expect(router.routes.length, equals(1));
        expect(router.routes.first.method, equals('POST'));
      });

      test('registers multiple HTTP methods', () {
        router.get('/users', (req, res) {});
        router.post('/users', (req, res) {});
        router.put('/users/:id', (req, res) {});
        router.delete('/users/:id', (req, res) {});

        expect(router.routes.length, equals(4));

        final methods = router.routes.map((r) => r.method).toList();
        expect(methods, containsAll(['GET', 'POST', 'PUT', 'DELETE']));
      });

      test('registers routes with middleware', () {
        final middleware1 = (req, res, next) => next();
        final middleware2 = (req, res, next) => next();

        router.get('/test', (req, res) {}, [middleware1, middleware2]);

        expect(router.routes.first.middleware.length, equals(2));
      });

      test('adds global middleware', () {
        final globalMiddleware = (req, res, next) => next();
        router.use(globalMiddleware);

        expect(router.middlewares.length, equals(1));
        expect(router.middlewares.first, equals(globalMiddleware));
      });
    });

    group('route properties', () {
      test('creates routes with correct path patterns', () {
        router.get('/users/:id', (req, res) {});
        router.get('/posts/:postId/comments', (req, res) {});

        expect(router.routes.length, equals(2));
        // Test that routes are created (actual pattern testing would need PathMatcher)
        expect(router.routes.first.path, equals('/users/:id'));
        expect(router.routes.last.path, equals('/posts/:postId/comments'));
      });

      test('stores route handlers correctly', () {
        final handler = (req, res) {};

        router.get('/test', handler);

        expect(router.routes.first.handler, equals(handler));
      });

      test('handles empty middleware lists', () {
        router.get('/test', (req, res) {});
        expect(router.routes.first.middleware, isEmpty);
      });

      test('handles null middleware parameter', () {
        router.get('/test', (req, res) {}, null);
        expect(router.routes.first.middleware, isEmpty);
      });
    });

    group('middleware handling', () {
      test('stores multiple global middlewares in order', () {
        final middleware1 = (req, res, next) => next();
        final middleware2 = (req, res, next) => next();
        final middleware3 = (req, res, next) => next();

        router.use(middleware1);
        router.use(middleware2);
        router.use(middleware3);

        expect(router.middlewares.length, equals(3));
        expect(router.middlewares[0], equals(middleware1));
        expect(router.middlewares[1], equals(middleware2));
        expect(router.middlewares[2], equals(middleware3));
      });

      test('combines route-specific middleware correctly', () {
        final routeMiddleware1 = (req, res, next) => next();
        final routeMiddleware2 = (req, res, next) => next();

        router
            .get('/test', (req, res) {}, [routeMiddleware1, routeMiddleware2]);

        expect(router.routes.first.middleware.length, equals(2));
        expect(router.routes.first.middleware[0], equals(routeMiddleware1));
        expect(router.routes.first.middleware[1], equals(routeMiddleware2));
      });
    });

    group('HTTP method variations', () {
      test('supports all standard HTTP methods', () {
        router.get('/get-route', (req, res) {});
        router.post('/post-route', (req, res) {});
        router.put('/put-route', (req, res) {});
        router.delete('/delete-route', (req, res) {});
        router.patch('/patch-route', (req, res) {});
        router.head('/head-route', (req, res) {});
        router.options('/options-route', (req, res) {});

        expect(router.routes.length, equals(7));

        final methods = router.routes.map((r) => r.method).toSet();
        expect(
            methods,
            containsAll(
                ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS']));
      });

      test('handles case sensitivity in methods', () {
        router.get('/test', (req, res) {});
        expect(
            router.routes.first.method, equals('GET')); // Should be uppercase
      });
    });

    group('edge cases', () {
      test('handles empty path', () {
        router.get('', (req, res) {});
        expect(router.routes.length, equals(1));
        expect(router.routes.first.path, equals(''));
      });

      test('handles root path', () {
        router.get('/', (req, res) {});
        expect(router.routes.length, equals(1));
        expect(router.routes.first.path, equals('/'));
      });

      test('handles complex paths with special characters', () {
        router.get('/test-path_with.chars', (req, res) {});
        expect(router.routes.first.path, equals('/test-path_with.chars'));
      });

      test('handles paths with multiple parameters', () {
        router.get(
            '/users/:userId/posts/:postId/comments/:commentId', (req, res) {});
        expect(router.routes.first.path, contains(':userId'));
        expect(router.routes.first.path, contains(':postId'));
        expect(router.routes.first.path, contains(':commentId'));
      });

      test('handles duplicate route registration', () {
        router.get('/test', (req, res) {});
        router.get('/test', (req, res) {}); // Duplicate

        expect(router.routes.length, equals(2)); // Both should be registered
      });
    });
  });
}
