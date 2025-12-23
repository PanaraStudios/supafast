import 'package:test/test.dart';
import 'package:supafast/supafast.dart';
import 'package:supafast/testing.dart';

void main() {
  group('Supafast Integration Tests', () {
    late Supafast app;
    late TestApp testApp;

    setUp(() async {
      app = Supafast();
      testApp = TestApp(app);

      // Basic routes
      app.get('/', (req, res) => res.send('Hello Supafast!'));

      app.get('/json', (req, res) => res.json({'message': 'Hello JSON'}));

      app.get('/users/:id', (req, res) {
        final id = req.params['id'];
        return res.json({'userId': id});
      });

      app.post('/echo', (req, res) {
        return res.json({'echo': 'received'});
      });

      // Add middleware
      app.use(logger());
      app.use(bodyParser());

      await testApp.start();
    });

    tearDown(() async {
      await testApp.close();
    });

    test('GET / returns hello message', () async {
      final response = await testApp.get('/').send();

      expect(response.statusCode, equals(200));
      expect(response.body, equals('Hello Supafast!'));
    });

    test('GET /json returns JSON response', () async {
      final response = await testApp.get('/json').send();

      expect(response.statusCode, equals(200));
      expect(response.isJson, isTrue);
      expect(response.json, equals({'message': 'Hello JSON'}));
    });

    test('GET /users/:id returns user data with path params', () async {
      final response = await testApp.get('/users/123').send();

      expect(response.statusCode, equals(200));
      expect(response.json, equals({'userId': '123'}));
    });

    test('GET /unknown returns 404', () async {
      final response = await testApp.get('/unknown').send();

      expect(response.statusCode, equals(404));
    });

    test('POST /echo returns echo response', () async {
      final response =
          await testApp.post('/echo').json({'test': 'data'}).send();

      expect(response.statusCode, equals(200));
      expect(response.json, equals({'echo': 'received'}));
    });

    test('TestRequest expect method works', () async {
      await testApp.get('/').expect(200);
    });

    test('TestRequest expectJson method works', () async {
      await testApp.get('/json').expectJson({'message': 'Hello JSON'});
    });
  });
}
