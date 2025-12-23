# ⚡ Supafast

> Express.js-inspired backend framework for Dart

**Supafast** is a lightweight, Express.js-inspired HTTP framework for Dart that makes building backend APIs fast and enjoyable.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Pub Version](https://img.shields.io/pub/v/supafast)](https://pub.dev/packages/supafast)

---

## ✨ Features

- **🚀 Express.js-like API** - Familiar routing and middleware patterns
- **⚡ Zero Dependencies** - Built on pure `dart:io` for maximum performance  
- **🔧 Type Safe** - Full Dart type safety throughout
- **🧪 Testing Ready** - Built-in testing utilities
- **🔌 Middleware Support** - Extensible middleware system
- **📦 Production Ready** - Comprehensive error handling and logging

## 🚀 Quick Start

### Installation

```yaml
dependencies:
  supafast: ^0.1.0
```

### Hello World

```dart
import 'package:supafast/supafast.dart';

void main() async {
  final app = Supafast();
  
  app.get('/', (req, res) => res.send('Hello, Supafast! ⚡'));
  
  await app.listen(3000);
  print('🚀 Server running on http://localhost:3000');
}
```

### With Middleware

```dart
import 'package:supafast/supafast.dart';

void main() async {
  final app = Supafast();
  
  // Add middleware
  app.use(cors());
  app.use(logger());
  app.use(bodyParser());
  
  // Define routes
  app.get('/users/:id', (req, res) {
    final userId = req.params['id'];
    return res.json({'userId': userId, 'name': 'John Doe'});
  });
  
  app.post('/users', (req, res) {
    final userData = req.body;
    return res.status(201).json({'message': 'User created', 'data': userData});
  });
  
  // Error handling
  app.use(errorHandler());
  
  await app.listen(3000);
  print('🚀 Server running on http://localhost:3000');
}
```

## 📚 Core Concepts

### Routing

Supafast uses Express.js-style routing:

```dart
// HTTP methods
app.get('/users', handler);
app.post('/users', handler);
app.put('/users/:id', handler);
app.delete('/users/:id', handler);
app.patch('/users/:id', handler);

// Path parameters
app.get('/users/:id/posts/:postId', (req, res) {
  final userId = req.params['id'];
  final postId = req.params['postId'];
  // ...
});

// Query parameters
app.get('/search', (req, res) {
  final query = req.query['q'];
  final limit = int.tryParse(req.query['limit'] ?? '10') ?? 10;
  // ...
});
```

### Request Object

```dart
app.post('/data', (req, res) async {
  // Path parameters
  final id = req.params['id'];
  
  // Query parameters  
  final filter = req.query['filter'];
  
  // Headers
  final authHeader = req.header('authorization');
  final contentType = req.contentType;
  
  // Body (requires bodyParser middleware)
  final jsonData = req.body; // Parsed JSON/form data
  final rawBody = await req.rawBody; // Raw string
  
  // Cookies
  final sessionId = req.cookie('sessionId');
  
  // Request info
  final userAgent = req.userAgent;
  final isSecure = req.isSecure;
  final clientIP = req.ip;
});
```

### Response Object

```dart
app.get('/api/data', (req, res) async {
  // Status codes
  res.status(201);
  
  // Headers
  res.header('X-API-Version', '1.0');
  res.contentType('application/json');
  
  // Cookies
  res.cookie('sessionId', 'abc123', maxAge: 3600);
  
  // Responses
  return res.send('Plain text');
  return res.json({'key': 'value'});
  return res.html('<h1>Hello</h1>');
  return res.file('/path/to/file.pdf');
  return res.redirect('/other-page');
  
  // Error responses
  return res.notFound('Resource not found');
  return res.badRequest('Invalid data');
  return res.serverError('Something went wrong');
});
```

### Middleware

```dart
// Global middleware
app.use(cors());
app.use(logger());
app.use(bodyParser());

// Route-specific middleware
app.get('/protected', [authMiddleware], (req, res) {
  return res.json({'message': 'Protected resource'});
});

// Custom middleware
Middleware customAuth() {
  return (req, res, next) async {
    final token = req.header('authorization');
    
    if (token == null) {
      return res.unauthorized('Missing auth token');
    }
    
    // Add user to request
    req.locals['user'] = {'id': '123', 'name': 'John'};
    
    await next(); // Continue to next middleware/handler
  };
}
```

### Error Handling

```dart
// Global error handler (should be last middleware)
app.use(errorHandler());

// Throwing errors in handlers
app.get('/error-demo', (req, res) {
  throw HttpException(400, 'Something went wrong');
  // or
  throw HttpException.badRequest('Invalid input');
});

// Custom error handler
app.use((req, res, next) async {
  try {
    await next();
  } catch (error) {
    if (error is CustomException) {
      return res.status(422).json({'error': error.message});
    }
    rethrow; // Let default error handler deal with it
  }
});
```

### Nested Routing

```dart
// Create sub-router
final apiRouter = Router();
apiRouter.get('/users', getUsersHandler);
apiRouter.post('/users', createUserHandler);

final adminRouter = Router();
adminRouter.use(adminAuthMiddleware); // Apply auth to all admin routes
adminRouter.get('/stats', getStatsHandler);

// Mount routers
app.mount('/api/v1', apiRouter);
app.mount('/admin', adminRouter);

// Results in:
// GET /api/v1/users
// POST /api/v1/users  
// GET /admin/stats
```

## 🧪 Testing

Supafast includes comprehensive testing utilities:

```dart
import 'package:test/test.dart';
import 'package:supafast/supafast.dart';
import 'package:supafast/testing.dart';

void main() {
  group('API Tests', () {
    late Supafast app;
    late TestApp testApp;

    setUp(() async {
      app = Supafast();
      testApp = TestApp(app);
      
      app.get('/hello', (req, res) => res.send('Hello'));
      app.post('/data', (req, res) => res.json(req.body));
      
      await testApp.start();
    });

    tearDown(() => testApp.close());

    test('GET /hello returns hello message', () async {
      final response = await testApp.get('/hello').send();
      
      expect(response.statusCode, 200);
      expect(response.body, 'Hello');
    });

    test('POST /data echoes JSON', () async {
      final testData = {'name': 'John'};
      
      await testApp
          .post('/data')
          .json(testData)
          .expect(200)
          .expectJson(testData);
    });
  });
}
```

## 🔌 Built-in Middleware

### CORS
```dart
app.use(cors()); // Allow all origins

app.use(cors(
  origins: ['https://myapp.com'],
  methods: ['GET', 'POST'],
  credentials: true,
));
```

### Logging
```dart
app.use(logger()); // Basic request logging

app.use(compactLogger()); // Compact format
app.use(devLogger()); // Detailed logging for development
```

### Body Parsing
```dart
app.use(bodyParser()); // Parse JSON and form data

app.use(jsonParser()); // JSON only
app.use(urlencodedParser()); // Form data only
```

### Static Files
```dart
app.use(serveStatic('public')); // Serve files from public/

app.use(serveStatic('assets', StaticOptions(
  index: 'index.html',
  maxAge: 3600, // 1 hour cache
)));
```

### Error Handling
```dart
app.use(errorHandler()); // Basic error handling

app.use(devErrorHandler()); // Include stack traces
app.use(prodErrorHandler()); // Production-safe errors
```

## 🎯 Examples

Check out the `examples/` directory:

- **[Basic Server](examples/basic_server/)** - Simple HTTP server
- **[REST API](examples/rest_api/)** - Full CRUD API with middleware

## 📖 API Reference

### Supafast Class

- `get(path, handler, [middleware])` - Register GET route
- `post(path, handler, [middleware])` - Register POST route
- `put(path, handler, [middleware])` - Register PUT route
- `delete(path, handler, [middleware])` - Register DELETE route
- `patch(path, handler, [middleware])` - Register PATCH route
- `options(path, handler, [middleware])` - Register OPTIONS route
- `head(path, handler, [middleware])` - Register HEAD route
- `all(path, handler, [middleware])` - Register route for all methods
- `use(middleware)` - Add global middleware
- `mount(prefix, router)` - Mount sub-router
- `listen(port, {hostname})` - Start HTTP server
- `close({force})` - Stop HTTP server

### Request Properties

- `method` - HTTP method (GET, POST, etc.)
- `path` - Request path without query string
- `uri` - Complete URI
- `params` - Path parameters (`Map<String, String>`)
- `query` - Query parameters (`Map<String, String>`)
- `headers` - HTTP headers
- `body` - Parsed request body
- `cookies` - Request cookies
- `ip` - Client IP address
- `userAgent` - User-Agent header
- `isSecure` - Whether request is HTTPS
- `locals` - Custom data storage

### Response Methods

- `status(code)` - Set status code
- `header(name, value)` - Set header
- `cookie(name, value, options)` - Set cookie
- `send(text)` - Send text response
- `json(data)` - Send JSON response
- `html(html)` - Send HTML response
- `file(path)` - Send file
- `redirect(url, status)` - Redirect request
- `notFound(message)` - Send 404 error
- `badRequest(message)` - Send 400 error
- `unauthorized(message)` - Send 401 error
- `serverError(message)` - Send 500 error

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Report bugs** - Open an issue with reproduction steps
2. **Suggest features** - Share your ideas for improvements
3. **Submit PRs** - Fix bugs or implement features
4. **Write docs** - Help improve documentation
5. **Create examples** - Show off what you've built

### Development Setup

```bash
git clone https://github.com/supafast-dart/supafast.git
cd supafast/packages/supafast
dart pub get
dart test
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🔗 Links

- **GitHub**: [supafast-dart/supafast](https://github.com/supafast-dart/supafast)
- **Pub.dev**: [pub.dev/packages/supafast](https://pub.dev/packages/supafast)
- **Examples**: [examples/](../../examples/)
- **Issues**: [GitHub Issues](https://github.com/supafast-dart/supafast/issues)

---

**Built with ❤️ for the Dart community**

*Making backend development supafast* ⚡