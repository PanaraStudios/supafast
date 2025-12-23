import 'package:supafast/supafast.dart';

void main() async {
  final app = Supafast();

  // Basic route
  app.get('/', (req, res) {
    return res.send('Hello from Supafast! 🚀');
  });

  // JSON response
  app.get('/json', (req, res) {
    return res.json({
      'message': 'This is a JSON response',
      'timestamp': DateTime.now().toIso8601String(),
      'framework': 'Supafast',
    });
  });

  // HTML response
  app.get('/html', (req, res) {
    final html = '''
<!DOCTYPE html>
<html>
<head>
    <title>Supafast Basic Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #333; }
        .container { max-width: 600px; margin: 0 auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to Supafast! ⚡</h1>
        <p>This is a basic HTML response from a Supafast server.</p>
        <p>Framework: <strong>Supafast v0.1.0</strong></p>
        <p>Time: <strong>${DateTime.now()}</strong></p>
        
        <h2>Available Routes:</h2>
        <ul>
            <li><a href="/">/ - Plain text response</a></li>
            <li><a href="/json">/json - JSON response</a></li>
            <li><a href="/html">/html - This HTML page</a></li>
            <li><a href="/users/123">/users/:id - Path parameters</a></li>
            <li><a href="/search?q=dart">/search?q=term - Query parameters</a></li>
        </ul>
    </div>
</body>
</html>
    ''';
    return res.html(html);
  });

  // Path parameter example
  app.get('/users/:id', (req, res) {
    final userId = req.params['id'];
    return res.json({
      'userId': userId,
      'message': 'User details for ID: $userId',
    });
  });

  // Query parameter example
  app.get('/search', (req, res) {
    final query = req.query['q'] ?? 'no query';
    final limit = int.tryParse(req.query['limit'] ?? '10') ?? 10;

    return res.json({
      'query': query,
      'limit': limit,
      'results': [
        'Result 1 for "$query"',
        'Result 2 for "$query"',
        'Result 3 for "$query"',
      ],
    });
  });

  // Multiple methods on same path
  app.get('/echo', (req, res) {
    return res.json({
      'method': 'GET',
      'message': 'Send a POST request to this endpoint with JSON data',
    });
  });

  app.post('/echo', (req, res) {
    return res.json({
      'method': 'POST',
      'echo': 'You sent data but body parser is not enabled',
      'tip': 'Add bodyParser() middleware to parse request bodies',
    });
  });

  // Status code examples
  app.get('/status/:code', (req, res) {
    final code = int.tryParse(req.params['code'] ?? '200') ?? 200;
    return res.status(code).json({
      'statusCode': code,
      'message': 'Custom status code response',
    });
  });

  // Error example
  app.get('/error', (req, res) {
    throw HttpException(500, 'This is a test error');
  });

  // 404 handler (will be handled automatically by Supafast)
  // app.get('/not-found', ...) - any unmatched route returns 404

  // Start the server
  const port = 3000;
  await app.listen(port);

  print('🚀 Basic Supafast server running on http://localhost:$port');
  print('   Try these routes:');
  print('   • http://localhost:$port/ - Hello message');
  print('   • http://localhost:$port/json - JSON response');
  print('   • http://localhost:$port/html - HTML page with links');
  print('   • http://localhost:$port/users/123 - Path parameters');
  print('   • http://localhost:$port/search?q=dart - Query parameters');
}
