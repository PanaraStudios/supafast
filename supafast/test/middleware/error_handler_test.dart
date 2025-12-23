import 'package:test/test.dart';
import 'package:supafast/supafast.dart';
import 'package:supafast/testing.dart';

void main() {
  group('Error Handler Middleware', () {
    late Supafast app;
    late TestApp testApp;

    setUp(() async {
      app = Supafast();
      testApp = TestApp(app);
    });

    tearDown(() async {
      await testApp.close();
    });

    group('basic error handling', () {
      test('handles generic exceptions', () async {
        app.use(errorHandler());
        app.get('/error', (req, res) => throw Exception('Test error'));
        await testApp.start();

        final response = await testApp.get('/error').send();
        expect(response.statusCode, equals(500));
      });

      test('handles HttpException with custom status', () async {
        app.use(errorHandler());
        app.get('/http-error',
            (req, res) => throw HttpException(400, 'Bad request'));
        await testApp.start();

        final response = await testApp.get('/http-error').send();
        expect(response.statusCode, equals(400));
      });

      test('preserves normal responses', () async {
        app.use(errorHandler());
        app.get('/normal', (req, res) => res.json({'message': 'success'}));
        await testApp.start();

        final response = await testApp.get('/normal').send();
        expect(response.statusCode, equals(200));
        expect(response.json['message'], equals('success'));
      });

      test('handles errors in middleware', () async {
        app.use((req, res, next) {
          throw Exception('Middleware error');
        });
        app.use(errorHandler());
        app.get('/test', (req, res) => res.send('should not reach here'));
        await testApp.start();

        final response = await testApp.get('/test').send();
        expect(response.statusCode, equals(500));
      });

      test('handles async errors', () async {
        app.use(errorHandler());
        app.get('/async-error', (req, res) async {
          await Future.delayed(Duration(milliseconds: 1));
          throw Exception('Async error');
        });
        await testApp.start();

        final response = await testApp.get('/async-error').send();
        expect(response.statusCode, equals(500));
      });

      test('handles different exception types', () async {
        app.use(errorHandler());
        app.get('/argument-error',
            (req, res) => throw ArgumentError('Invalid argument'));
        app.get(
            '/state-error', (req, res) => throw StateError('Invalid state'));
        app.get('/format-error',
            (req, res) => throw FormatException('Invalid format'));
        await testApp.start();

        final argResponse = await testApp.get('/argument-error').send();
        final stateResponse = await testApp.get('/state-error').send();
        final formatResponse = await testApp.get('/format-error').send();

        expect(argResponse.statusCode, equals(500));
        expect(stateResponse.statusCode, equals(500));
        expect(formatResponse.statusCode, equals(500));
      });
    });

    group('error responses', () {
      test('returns error response with basic information', () async {
        app.use(errorHandler());
        app.get('/error', (req, res) => throw Exception('Test error'));
        await testApp.start();

        final response = await testApp.get('/error').send();

        expect(response.statusCode, equals(500));
        expect(response.isJson, isTrue);
        // Basic error structure should be present
        expect(response.json, isA<Map<String, dynamic>>());
      });

      test('handles different HTTP status codes', () async {
        app.use(errorHandler());
        app.get('/400', (req, res) => throw HttpException(400, 'Bad request'));
        app.get('/401', (req, res) => throw HttpException(401, 'Unauthorized'));
        app.get('/403', (req, res) => throw HttpException(403, 'Forbidden'));
        app.get('/404', (req, res) => throw HttpException(404, 'Not found'));
        await testApp.start();

        final badRequest = await testApp.get('/400').send();
        final unauthorized = await testApp.get('/401').send();
        final forbidden = await testApp.get('/403').send();
        final notFound = await testApp.get('/404').send();

        expect(badRequest.statusCode, equals(400));
        expect(unauthorized.statusCode, equals(401));
        expect(forbidden.statusCode, equals(403));
        expect(notFound.statusCode, equals(404));
      });

      test('provides consistent error response format', () async {
        app.use(errorHandler());
        app.get('/error', (req, res) => throw Exception('Consistent error'));
        await testApp.start();

        final response = await testApp.get('/error').send();

        expect(response.statusCode, equals(500));
        expect(response.isJson, isTrue);

        // Should have some form of error information
        final json = response.json;
        expect(json, isA<Map<String, dynamic>>());
        expect(json.isNotEmpty, isTrue);
      });
    });

    group('middleware integration', () {
      test('works with other middleware', () async {
        final executionOrder = <String>[];

        app.use((req, res, next) {
          executionOrder.add('middleware1');
          return next();
        });

        app.use(errorHandler());

        app.use((req, res, next) {
          executionOrder.add('middleware2');
          return next();
        });

        app.get('/test', (req, res) {
          executionOrder.add('handler');
          return res.json({'order': executionOrder});
        });
        await testApp.start();

        final response = await testApp.get('/test').send();

        expect(response.statusCode, equals(200));
        expect(executionOrder, contains('middleware1'));
        expect(executionOrder, contains('middleware2'));
        expect(executionOrder, contains('handler'));
      });

      test('catches errors from previous middleware', () async {
        app.use((req, res, next) {
          throw Exception('Middleware error');
        });

        app.use(errorHandler());

        app.get('/test', (req, res) => res.send('Should not reach'));
        await testApp.start();

        final response = await testApp.get('/test').send();
        expect(response.statusCode, equals(500));
      });

      test('handles middleware chain interruption', () async {
        final executionOrder = <String>[];

        app.use((req, res, next) {
          executionOrder.add('middleware1');
          return next();
        });

        app.use((req, res, next) {
          executionOrder.add('middleware2');
          throw Exception('Stop here');
        });

        app.use(errorHandler());

        app.use((req, res, next) {
          executionOrder.add('middleware3'); // Should not execute
          return next();
        });

        app.get('/test', (req, res) {
          executionOrder.add('handler'); // Should not execute
          return res.send('test');
        });
        await testApp.start();

        await testApp.get('/test').send();

        expect(executionOrder, equals(['middleware1', 'middleware2']));
      });
    });

    group('edge cases', () {
      test('handles routes without error handler', () async {
        // No error handler middleware added
        app.get('/error', (req, res) => throw Exception('No handler'));
        await testApp.start();

        final response = await testApp.get('/error').send();
        expect(response.statusCode,
            equals(500)); // Should still handle error somehow
      });

      test('handles very long error messages', () async {
        app.use(errorHandler());
        app.get('/long-error', (req, res) {
          final longMessage = 'Error: ' + 'x' * 1000;
          throw Exception(longMessage);
        });
        await testApp.start();

        final response = await testApp.get('/long-error').send();
        expect(response.statusCode, equals(500));
      });

      test('handles unicode characters in error messages', () async {
        app.use(errorHandler());
        app.get('/unicode',
            (req, res) => throw Exception('Error with unicode: 中文 🚀'));
        await testApp.start();

        final response = await testApp.get('/unicode').send();
        expect(response.statusCode, equals(500));
      });

      test('handles multiple consecutive errors', () async {
        app.use(errorHandler());
        app.get('/error1', (req, res) => throw Exception('Error 1'));
        app.get('/error2', (req, res) => throw Exception('Error 2'));
        await testApp.start();

        final response1 = await testApp.get('/error1').send();
        final response2 = await testApp.get('/error2').send();

        expect(response1.statusCode, equals(500));
        expect(response2.statusCode, equals(500));
      });
    });
  });
}
