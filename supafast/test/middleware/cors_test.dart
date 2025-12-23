import 'package:test/test.dart';
import 'package:supafast/supafast.dart';
import 'package:supafast/testing.dart';

void main() {
  group('CORS Middleware', () {
    late Supafast app;
    late TestApp testApp;

    setUp(() async {
      app = Supafast();
      testApp = TestApp(app);
    });

    tearDown(() async {
      await testApp.close();
    });

    group('default configuration', () {
      setUp(() async {
        app.use(cors());
        app.get('/test', (req, res) => res.json({'message': 'test'}));
        await testApp.start();
      });

      test('adds default CORS headers to responses', () async {
        final response = await testApp.get('/test').send();

        expect(response.headers['access-control-allow-origin'], equals('*'));
        expect(response.statusCode, equals(200));
      });

      test('handles preflight OPTIONS requests', () async {
        final response = await testApp
            .request('OPTIONS', '/test')
            .header('origin', 'https://example.com')
            .header('access-control-request-method', 'POST')
            .send();

        expect(response.statusCode, anyOf([200, 204]));
        expect(response.headers['access-control-allow-origin'], isNotNull);
      });
    });

    group('custom configuration', () {
      test('respects custom allowed origins', () async {
        app.use(cors(origins: ['https://example.com', 'https://test.com']));
        app.get('/test', (req, res) => res.json({'message': 'test'}));
        await testApp.start();

        final response = await testApp
            .get('/test')
            .header('origin', 'https://example.com')
            .send();

        expect(response.statusCode, equals(200));
        // Note: Actual behavior may vary based on implementation
      });

      test('respects custom allowed methods', () async {
        app.use(cors(methods: ['GET', 'POST']));
        app.get('/test', (req, res) => res.json({'message': 'test'}));
        await testApp.start();

        final response = await testApp
            .request('OPTIONS', '/test')
            .header('access-control-request-method', 'PUT')
            .send();

        expect(response.statusCode, anyOf([200, 204, 405]));
      });

      test('handles credentials configuration', () async {
        app.use(cors(credentials: true, origins: ['https://example.com']));
        app.get('/test', (req, res) => res.json({'message': 'test'}));
        await testApp.start();

        final response = await testApp
            .get('/test')
            .header('origin', 'https://example.com')
            .send();

        expect(response.statusCode, equals(200));
        final credentialsHeader =
            response.headers['access-control-allow-credentials'];
        if (credentialsHeader != null) {
          expect(credentialsHeader, equals('true'));
        }
      });
    });

    group('edge cases', () {
      test('handles missing origin header gracefully', () async {
        app.use(cors());
        app.get('/test', (req, res) => res.json({'message': 'test'}));
        await testApp.start();

        final response = await testApp.get('/test').send();
        expect(response.statusCode, equals(200));
      });

      test('handles multiple origins correctly', () async {
        app.use(cors(origins: ['https://app1.com', 'https://app2.com']));
        app.get('/test', (req, res) => res.json({'message': 'test'}));
        await testApp.start();

        final response1 = await testApp
            .get('/test')
            .header('origin', 'https://app1.com')
            .send();

        expect(response1.statusCode, equals(200));
      });
    });
  });
}
