import 'package:test/test.dart';
import 'package:supafast/supafast.dart';
import 'package:supafast/testing.dart';

void main() {
  group('Logger Middleware', () {
    late Supafast app;
    late TestApp testApp;

    setUp(() async {
      app = Supafast();
      testApp = TestApp(app);
    });

    tearDown(() async {
      await testApp.close();
    });

    group('basic logging', () {
      test('adds logger middleware successfully', () async {
        app.use(logger());
        app.get('/test', (req, res) => res.json({'message': 'test'}));
        await testApp.start();

        final response = await testApp.get('/test').send();
        expect(response.statusCode, equals(200));
        expect(response.json['message'], equals('test'));
      });

      test('logs requests without breaking functionality', () async {
        app.use(logger());
        app.post(
            '/data', (req, res) => res.status(201).json({'created': true}));
        await testApp.start();

        final response =
            await testApp.post('/data').json({'test': 'data'}).send();

        expect(response.statusCode, equals(201));
        expect(response.json['created'], equals(true));
      });

      test('handles GET and POST requests', () async {
        app.use(logger());
        app.get('/get-test', (req, res) => res.send('GET response'));
        app.post('/post-test', (req, res) => res.send('POST response'));
        await testApp.start();

        final getResponse = await testApp.get('/get-test').send();
        final postResponse = await testApp.post('/post-test').send();

        expect(getResponse.statusCode, equals(200));
        expect(getResponse.body, equals('GET response'));
        expect(postResponse.statusCode, equals(200));
        expect(postResponse.body, equals('POST response'));
      });

      test('works with query parameters', () async {
        app.use(logger());
        app.get('/search',
            (req, res) => res.json({'query': req.query['q'] ?? 'none'}));
        await testApp.start();

        final response = await testApp.get('/search?q=dart&limit=10').send();

        expect(response.statusCode, equals(200));
        expect(response.json['query'], equals('dart'));
      });

      test('handles 404 errors', () async {
        app.use(logger());
        app.get('/existing', (req, res) => res.send('exists'));
        await testApp.start();

        final existingResponse = await testApp.get('/existing').send();
        final notFoundResponse = await testApp.get('/nonexistent').send();

        expect(existingResponse.statusCode, equals(200));
        expect(notFoundResponse.statusCode, equals(404));
      });

      test('handles errors in route handlers', () async {
        app.use(logger());
        app.get('/error', (req, res) {
          throw Exception('Test error');
        });
        await testApp.start();

        final response = await testApp.get('/error').send();
        expect(response.statusCode, equals(500));
      });

      test('preserves middleware order', () async {
        final executionOrder = <String>[];

        app.use((req, res, next) {
          executionOrder.add('before-logger');
          return next();
        });

        app.use(logger());

        app.use((req, res, next) {
          executionOrder.add('after-logger');
          return next();
        });

        app.get('/test', (req, res) {
          executionOrder.add('handler');
          return res.json({'order': executionOrder});
        });
        await testApp.start();

        final response = await testApp.get('/test').send();

        expect(response.statusCode, equals(200));
        expect(executionOrder, contains('before-logger'));
        expect(executionOrder, contains('after-logger'));
        expect(executionOrder, contains('handler'));
      });
    });

    group('edge cases', () {
      test('handles requests with long URLs', () async {
        app.use(logger());
        app.get('/test', (req, res) => res.json({'success': true}));
        await testApp.start();

        final longQuery =
            List.generate(100, (i) => 'param$i=value$i').join('&');
        final response = await testApp.get('/test?$longQuery').send();

        expect(response.statusCode, equals(200));
        expect(response.json['success'], equals(true));
      });

      test('handles special characters in paths', () async {
        app.use(logger());
        app.get('/test/:param',
            (req, res) => res.json({'param': req.params['param']}));
        await testApp.start();

        final response = await testApp.get('/test/hello%20world').send();

        expect(response.statusCode, equals(200));
        if (response.json['param'] != null) {
          expect(
              response.json['param'], anyOf(['hello%20world', 'hello world']));
        }
      });

      test('handles concurrent requests', () async {
        app.use(logger());
        app.get(
            '/concurrent',
            (req, res) =>
                res.json({'timestamp': DateTime.now().millisecondsSinceEpoch}));
        await testApp.start();

        // Send multiple requests concurrently
        final futures =
            List.generate(5, (_) => testApp.get('/concurrent').send());
        final responses = await Future.wait(futures);

        for (final response in responses) {
          expect(response.statusCode, equals(200));
          expect(response.json['timestamp'], isA<int>());
        }
      });
    });
  });
}
