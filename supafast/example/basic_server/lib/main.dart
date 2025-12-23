import 'package:supafast/supafast.dart';

void main() async {
  final app = Supafast();

  // Add comprehensive middleware stack
  app.use(logger()); // Request logging
  app.use(cors()); // CORS support
  app.use(compression()); // Response compression
  app.use(bodyParser()); // Body parsing for POST/PUT requests

  // Basic route
  app.get('/hello', (req, res) {
    return res.send('Hello from Supafast! 🚀');
  });

  // Route to serve the static demo page
  app.get('/static-demo', (req, res) {
    return res.file('public/index.html');
  });

  // Static file serving with default options - index.html will be served at root
  app.use(serveStatic('public'));

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
            <li><a href="/upload">/upload - File upload demo</a></li>
            <li><a href="/api/v1/test">/api/v1/test - Router mounting demo</a></li>
            <li><a href="/middleware-demo">/middleware-demo - Custom middleware</a></li>
            <li><a href="/public/">/public/ - Static files (create 'public' folder)</a></li>
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
      'receivedBody': req.body,
      'message': 'Body parsing is now enabled!',
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

  // File upload demo
  app.get('/upload', (req, res) {
    final html = '''
<!DOCTYPE html>
<html>
<head>
    <title>File Upload Demo</title>
</head>
<body>
    <h1>File Upload Test</h1>
    <form action="/upload" method="post" enctype="multipart/form-data">
        <input type="file" name="file" required>
        <input type="submit" value="Upload">
    </form>
    <br>
    <form action="/echo" method="post" enctype="application/json">
        <h2>JSON Body Test</h2>
        <textarea name="json" placeholder='{"test": "data"}'>{"message": "Hello from body parser!"}</textarea><br>
        <input type="submit" value="Send JSON">
    </form>
</body>
</html>
    ''';
    return res.html(html);
  });

  app.post('/upload', (req, res) {
    return res.json({
      'message': 'File upload received',
      'body': req.body,
      'contentType': req.contentType?.toString(),
    });
  });

  // Router mounting demo
  final apiRouter = Router();
  apiRouter.get('/test', (req, res) {
    return res.json({
      'message': 'This route is mounted under /api/v1',
      'fullPath': req.path,
    });
  });
  app.mount('/api/v1', apiRouter);

  // Custom middleware demo
  Middleware timingMiddleware() {
    return (req, res, next) async {
      final start = DateTime.now();
      await next();
      final duration = DateTime.now().difference(start);
      res.header('X-Response-Time', '${duration.inMilliseconds}ms');
    };
  }

  app.get('/middleware-demo', (req, res) {
    return res.json({
      'message': 'This response includes custom timing middleware',
      'tip': 'Check the X-Response-Time header',
    });
  }, [timingMiddleware()]);

  // Error example
  app.get('/error', (req, res) {
    throw HttpException(500, 'This is a test error');
  });

  // 404 handler (will be handled automatically by Supafast)
  // app.get('/not-found', ...) - any unmatched route returns 404

  // Start the server
  const port = 3001;
  print('Starting Supafast server with all features...');
  print('');
  print('🚀 Basic Routes:');
  print('   • http://localhost:$port/ - Static demo page (index.html)');
  print('   • http://localhost:$port/hello - Hello message');
  print('   • http://localhost:$port/json - JSON response');
  print('   • http://localhost:$port/html - HTML page with links');
  print('   • http://localhost:$port/users/123 - Path parameters');
  print('   • http://localhost:$port/search?q=dart - Query parameters');
  print('');
  print('📁 Static Files:');
  print('   • http://localhost:$port/index.html - Static HTML demo page');
  print('   • http://localhost:$port/app.js - JavaScript file');
  print('   • http://localhost:$port/styles.css - CSS stylesheet');
  print('   • http://localhost:$port/data.json - JSON data file');
  print('   • http://localhost:$port/static-demo - Static demo page via route');
  print('');
  print('🔧 Advanced Features:');
  print('   • http://localhost:$port/upload - File upload and body parsing demo');
  print('   • http://localhost:$port/api/v1/test - Router mounting demo');
  print('   • http://localhost:$port/middleware-demo - Custom middleware demo');
  print('   • http://localhost:$port/echo - POST body parsing test');
  print('   • http://localhost:$port/error - Error handling demo');
  print('');
  print('🎯 Middleware Features:');
  print('   • CORS enabled for cross-origin requests');
  print('   • Request/response logging active');
  print('   • Gzip compression for responses');
  print('   • Body parsing for JSON/form data');
  
  await app.listen(port);
}
