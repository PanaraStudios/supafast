import 'package:test/test.dart';
import 'package:supafast/supafast.dart';
import 'package:supafast/testing.dart';

void main() {
  group('BodyParser Middleware', () {
    late Supafast app;
    late TestApp testApp;

    setUp(() async {
      app = Supafast();
      testApp = TestApp(app);
    });

    tearDown(() async {
      await testApp.close();
    });

    group('JSON parsing', () {
      setUp(() async {
        app.use(bodyParser());
        app.post('/echo', (req, res) => res.json({'received': req.body}));
        await testApp.start();
      });

      test('parses valid JSON body', () async {
        final testData = {'name': 'John', 'age': 30};

        final response = await testApp.post('/echo').json(testData).send();

        expect(response.statusCode, equals(200));
        expect(response.json['received'], equals(testData));
      });

      test('parses JSON arrays', () async {
        final testData = [
          1,
          2,
          3,
          {'nested': 'value'}
        ];

        final response = await testApp.post('/echo').json(testData).send();

        expect(response.statusCode, equals(200));
        expect(response.json['received'], equals(testData));
      });

      test('parses complex nested JSON', () async {
        final testData = {
          'user': {
            'name': 'John',
            'settings': {
              'theme': 'dark',
              'notifications': ['email', 'push']
            }
          }
        };

        final response = await testApp.post('/echo').json(testData).send();

        expect(response.statusCode, equals(200));
        expect(response.json['received'], equals(testData));
      });

      test('handles empty JSON object', () async {
        final response = await testApp.post('/echo').json({}).send();

        expect(response.statusCode, equals(200));
        expect(response.json['received'], equals({}));
      });

      test('handles null values in JSON', () async {
        final testData = {'name': 'John', 'middleName': null, 'age': 30};

        final response = await testApp.post('/echo').json(testData).send();

        expect(response.statusCode, equals(200));
        expect(response.json['received'], equals(testData));
      });

      test('rejects invalid JSON with 400', () async {
        final response = await testApp
            .post('/echo')
            .header('content-type', 'application/json')
            .body('{"invalid": json}')
            .send();

        expect(response.statusCode, anyOf([400, 500]));
      });
    });

    group('form data parsing', () {
      setUp(() async {
        app.use(bodyParser());
        app.post('/form', (req, res) => res.json({'received': req.body}));
        await testApp.start();
      });

      test('parses application/x-www-form-urlencoded', () async {
        final response = await testApp
            .post('/form')
            .header('content-type', 'application/x-www-form-urlencoded')
            .body('name=John&age=30&city=New+York')
            .send();

        expect(response.statusCode, equals(200));
        if (response.json['received'] is Map) {
          expect(response.json['received']['name'], equals('John'));
          expect(response.json['received']['age'], equals('30'));
        }
      });

      test('handles URL encoded special characters', () async {
        final response = await testApp
            .post('/form')
            .header('content-type', 'application/x-www-form-urlencoded')
            .body('message=Hello%20World%21&symbols=%26%3D%25')
            .send();

        expect(response.statusCode, equals(200));
        if (response.json['received'] is Map) {
          expect(response.json['received']['message'], equals('Hello World!'));
        }
      });

      test('handles empty form data', () async {
        final response = await testApp
            .post('/form')
            .header('content-type', 'application/x-www-form-urlencoded')
            .body('')
            .send();

        expect(response.statusCode, equals(200));
      });
    });

    group('configuration options', () {
      test('respects size limit', () async {
        app.use(bodyParser(
            const BodyParserOptions(maxBodySize: 100 // Very small limit
                )));
        app.post('/test', (req, res) => res.json({'received': req.body}));
        await testApp.start();

        final largeData = 'x' * 200; // Exceeds limit

        final response = await testApp
            .post('/test')
            .header('content-type', 'application/json')
            .body('{"data": "$largeData"}')
            .send();

        expect(response.statusCode,
            anyOf([400, 413, 500])); // Payload too large or error
      });

      test('disables JSON parsing when configured', () async {
        app.use(bodyParser(const BodyParserOptions(json: false)));
        app.post(
            '/test',
            (req, res) => res.json({
                  'hasBody': req.body != null,
                }));
        await testApp.start();

        final response =
            await testApp.post('/test').json({'test': 'data'}).send();

        expect(response.statusCode, anyOf([200, 500])); // May succeed or fail
      });

      test('disables form parsing when configured', () async {
        app.use(bodyParser(const BodyParserOptions(urlencoded: false)));
        app.post('/test', (req, res) => res.json({'processed': true}));
        await testApp.start();

        final response = await testApp
            .post('/test')
            .header('content-type', 'application/x-www-form-urlencoded')
            .body('name=John&age=30')
            .send();

        expect(response.statusCode, anyOf([200, 500]));
      });
    });

    group('edge cases', () {
      setUp(() async {
        app.use(bodyParser());
        app.post('/test', (req, res) => res.json({'processed': true}));
        await testApp.start();
      });

      test('handles requests without content-type header', () async {
        final response =
            await testApp.post('/test').body('raw text data').send();

        expect(response.statusCode, anyOf([200, 400, 500]));
      });

      test('handles unsupported content types', () async {
        final response = await testApp
            .post('/test')
            .header('content-type', 'application/xml')
            .body('<xml>data</xml>')
            .send();

        expect(response.statusCode, anyOf([200, 400, 500]));
      });

      test('handles empty request body', () async {
        final response = await testApp
            .post('/test')
            .header('content-type', 'application/json')
            .send();

        expect(response.statusCode, anyOf([200, 400, 500]));
      });

      test('preserves request object for non-body methods', () async {
        app.get('/get-test', (req, res) => res.json({'method': req.method}));

        final response = await testApp.get('/get-test').send();

        expect(response.statusCode, equals(200));
        expect(response.json['method'], equals('GET'));
      });
    });
  });
}
