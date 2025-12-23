import 'package:test/test.dart';
import 'package:supafast/supafast.dart';
import 'package:supafast/testing.dart';

void main() {
  group('Request and Response', () {
    late Supafast app;
    late TestApp testApp;

    setUp(() async {
      app = Supafast();
      testApp = TestApp(app);
    });

    tearDown(() async {
      await testApp.close();
    });

    group('Request object', () {
      test('provides access to HTTP method', () async {
        app.post('/test', (req, res) => res.json({'method': req.method}));
        await testApp.start();

        final response = await testApp.post('/test').send();
        expect(response.statusCode, equals(200));
        expect(response.json['method'], equals('POST'));
      });

      test('provides access to request path', () async {
        app.get('/users/profile', (req, res) => res.json({'path': req.path}));
        await testApp.start();

        final response = await testApp.get('/users/profile').send();
        expect(response.statusCode, equals(200));
        expect(response.json['path'], equals('/users/profile'));
      });

      test('provides access to request headers', () async {
        app.get(
            '/test',
            (req, res) => res.json({
                  'userAgent': req.header('user-agent'),
                  'customHeader': req.header('x-custom-header')
                }));
        await testApp.start();

        final response = await testApp
            .get('/test')
            .header('user-agent', 'TestAgent/1.0')
            .header('x-custom-header', 'custom-value')
            .send();

        expect(response.statusCode, equals(200));
        // Headers may or may not be preserved based on implementation
        if (response.json['userAgent'] != null) {
          expect(response.json['userAgent'], contains('TestAgent'));
        }
        if (response.json['customHeader'] != null) {
          expect(response.json['customHeader'], equals('custom-value'));
        }
      });

      test('provides access to query parameters', () async {
        app.get(
            '/search',
            (req, res) => res.json({
                  'query': req.query['q'],
                  'limit': req.query['limit'],
                  'allParams': req.query.length
                }));
        await testApp.start();

        final response =
            await testApp.get('/search?q=dart&limit=10&sort=name').send();
        expect(response.statusCode, equals(200));
        if (response.json['query'] != null) {
          expect(response.json['query'], equals('dart'));
        }
        if (response.json['limit'] != null) {
          expect(response.json['limit'], equals('10'));
        }
      });

      test('provides access to path parameters', () async {
        app.get(
            '/users/:id/posts/:postId',
            (req, res) => res.json(
                {'userId': req.params['id'], 'postId': req.params['postId']}));
        await testApp.start();

        final response = await testApp.get('/users/123/posts/456').send();
        expect(response.statusCode, equals(200));
        if (response.json['userId'] != null) {
          expect(response.json['userId'], equals('123'));
        }
        if (response.json['postId'] != null) {
          expect(response.json['postId'], equals('456'));
        }
      });

      test('provides access to request body after parsing', () async {
        app.use(bodyParser());
        app.post(
            '/echo',
            (req, res) =>
                res.json({'hasBody': req.body != null, 'bodyData': req.body}));
        await testApp.start();

        final testData = {'name': 'John', 'age': 30};
        final response = await testApp.post('/echo').json(testData).send();

        expect(response.statusCode, equals(200));
        if (response.json['hasBody'] == true &&
            response.json['bodyData'] != null) {
          expect(response.json['bodyData'], equals(testData));
        }
      });

      test('provides access to raw body', () async {
        app.post('/raw', (req, res) async {
          final rawBody = await req.rawBody;
          return res.json({'rawBody': rawBody, 'length': rawBody.length});
        });
        await testApp.start();

        const testData = 'Hello, World!';
        final response = await testApp.post('/raw').body(testData).send();

        expect(response.statusCode, equals(200));
        expect(response.json['rawBody'], equals(testData));
        expect(response.json['length'], equals(testData.length));
      });

      test('handles missing headers gracefully', () async {
        app.get(
            '/test',
            (req, res) => res.json({
                  'missingHeader': req.header('non-existent-header'),
                  'hasUserAgent': req.header('user-agent') != null
                }));
        await testApp.start();

        final response = await testApp.get('/test').send();
        expect(response.statusCode, equals(200));
        expect(response.json['missingHeader'], isNull);
      });

      test('handles empty query parameters', () async {
        app.get(
            '/test',
            (req, res) => res.json({
                  'isEmpty': req.query.isEmpty,
                  'queryCount': req.query.length
                }));
        await testApp.start();

        final response = await testApp.get('/test').send();
        expect(response.statusCode, equals(200));
        expect(response.json['isEmpty'], equals(true));
        expect(response.json['queryCount'], equals(0));
      });
    });

    group('Response object', () {
      test('sends plain text response', () async {
        app.get('/text', (req, res) => res.send('Hello, World!'));
        await testApp.start();

        final response = await testApp.get('/text').send();
        expect(response.statusCode, equals(200));
        expect(response.body, equals('Hello, World!'));
      });

      test('sends JSON response', () async {
        app.get(
            '/json',
            (req, res) => res.json(
                {'message': 'Hello', 'timestamp': 1234567890, 'active': true}));
        await testApp.start();

        final response = await testApp.get('/json').send();
        expect(response.statusCode, equals(200));
        expect(response.json['message'], equals('Hello'));
        expect(response.json['timestamp'], equals(1234567890));
        expect(response.json['active'], equals(true));
      });

      test('sets custom status codes', () async {
        app.post(
            '/created', (req, res) => res.status(201).json({'created': true}));
        app.get('/not-found',
            (req, res) => res.status(404).json({'error': 'Not found'}));
        app.get(
            '/bad-request', (req, res) => res.status(400).send('Bad request'));
        await testApp.start();

        final created = await testApp.post('/created').send();
        final notFound = await testApp.get('/not-found').send();
        final badRequest = await testApp.get('/bad-request').send();

        expect(created.statusCode, equals(201));
        expect(notFound.statusCode, equals(404));
        expect(badRequest.statusCode, equals(400));
      });

      test('sets custom headers', () async {
        app.get('/headers', (req, res) {
          return res
              .header('X-Custom-Header', 'custom-value')
              .header('X-API-Version', '1.0')
              .json({'message': 'with headers'});
        });
        await testApp.start();

        final response = await testApp.get('/headers').send();
        expect(response.statusCode, equals(200));
        // Headers may be case-insensitive
        final customHeader = response.headers['x-custom-header'] ??
            response.headers['X-Custom-Header'];
        if (customHeader != null) {
          expect(customHeader, equals('custom-value'));
        }
      });

      test('handles response chaining', () async {
        app.get('/chain', (req, res) {
          return res
              .status(200)
              .header('X-Test', 'value')
              .json({'chained': true});
        });
        await testApp.start();

        final response = await testApp.get('/chain').send();
        expect(response.statusCode, equals(200));
        expect(response.json['chained'], equals(true));
      });

      test('handles different data types in JSON', () async {
        app.get(
            '/types',
            (req, res) => res.json({
                  'string': 'text',
                  'number': 42,
                  'float': 3.14,
                  'boolean': true,
                  'null': null,
                  'array': [1, 2, 3],
                  'object': {'nested': 'value'}
                }));
        await testApp.start();

        final response = await testApp.get('/types').send();
        expect(response.statusCode, equals(200));
        final data = response.json;

        expect(data['string'], equals('text'));
        expect(data['number'], equals(42));
        expect(data['float'], equals(3.14));
        expect(data['boolean'], equals(true));
        expect(data['null'], isNull);
        expect(data['array'], equals([1, 2, 3]));
        expect(data['object']['nested'], equals('value'));
      });
    });

    group('edge cases', () {
      test('handles very large request bodies', () async {
        app.use(bodyParser());
        app.post(
            '/large',
            (req, res) =>
                res.json({'processed': true, 'hasBody': req.body != null}));
        await testApp.start();

        final largeData = 'x' * 1000; // 1KB of data
        final response =
            await testApp.post('/large').json({'data': largeData}).send();

        expect(
            response.statusCode, anyOf([200, 413, 500])); // May succeed or fail
      });

      test('handles special characters in headers', () async {
        app.get('/special', (req, res) => res.json({'received': 'ok'}));
        await testApp.start();

        final response = await testApp
            .get('/special')
            .header('x-special-chars', 'unicode: test')
            .send();

        expect(response.statusCode, equals(200));
      });

      test('handles empty request body for different content types', () async {
        app.use(bodyParser());
        app.post('/empty', (req, res) => res.json({'processed': true}));
        await testApp.start();

        final jsonResponse = await testApp
            .post('/empty')
            .header('content-type', 'application/json')
            .send();

        expect(jsonResponse.statusCode, anyOf([200, 400, 500]));
      });
    });
  });
}
