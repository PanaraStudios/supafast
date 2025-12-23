# ⚡ Supafast

> Build full-stack Dart apps at lightning speed

**Supafast** is a modern, lightweight backend framework for Dart that brings Express.js-like simplicity to server-side development, with first-class Flutter integration through automatic code generation.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Pub Version](https://img.shields.io/pub/v/supafast)](https://pub.dev/packages/supafast)
[![Discord](https://img.shields.io/discord/placeholder)](https://supafast.io/discord)

🌐 **Website**: [supafast.io](https://supafast.io)  
📚 **Documentation**: [docs.supafast.io](https://docs.supafast.io)  
💬 **Discord**: [supafast.io/discord](https://supafast.io/discord)

---

## 🚀 Vision

Supafast aims to be **the** de facto backend framework for Flutter developers, combining:

- **Express.js simplicity** - Familiar, minimal API for rapid development
- **Type-safe code generation** - Shared models between backend and Flutter clients
- **Zero boilerplate** - Auto-generated HTTP clients, serialization, and validation
- **Pure Dart** - Built on native `dart:io` with no hidden magic
- **Production-ready** - Security, performance, and scalability baked in

## ⚡ Quick Start

**Installation:**
```yaml
dependencies:
  supafast: ^0.1.0
```

**Create your first server:**
```dart
import 'package:supafast/supafast.dart';

void main() async {
  final app = Supafast();
  
  app.get('/hello/:name', (req, res) {
    final name = req.params['name'];
    return res.json({'message': 'Hello, $name!'});
  });
  
  print('Starting server...');
  await app.listen(3000);
}
```

**With middleware:**
```dart
final app = Supafast();

// Add middleware
app.use(cors());
app.use(logger());
app.use(bodyParser());

// Define routes
app.post('/users', (req, res) {
  final userData = req.body;
  return res.status(201).json(userData);
});

// Error handling
app.use(errorHandler());

print('Starting server with middleware...');
await app.listen(3000);
```

**Run example:**
```bash
cd examples/basic_server
dart run lib/main.dart
```

## 🎯 Why Supafast?

### The Problem
Building full-stack Dart applications today means:
- Writing boilerplate HTTP clients in Flutter
- Manually keeping frontend/backend types in sync
- Dealing with serialization bugs at runtime
- Complex setup with existing frameworks (Shelf, Serverpod)

### The Solution
Supafast provides:
- ✅ **Express.js-like DX** - If you know Express, you know Supafast
- ✅ **60-second setup** - From zero to running API faster than any alternative
- ✅ **Flutter-first** - Built by Flutter developers, for Flutter developers
- 🚧 **Automatic code generation** - Coming in v0.2.0+ (types, clients, DTOs)

### Comparison

| Feature | Supafast | Serverpod | Shelf | Express.js |
|---------|----------|-----------|-------|------------|
| **Developer Experience** | ⚡ Express-like | Complex | Low-level | ✓ Gold standard |
| **Code Generation** | 🚧 Coming soon | ✓ Full-stack | ✗ Manual | ✗ Manual |
| **Setup Time** | < 60 seconds | ~10 minutes | ~5 minutes | < 60 seconds |
| **Learning Curve** | Low | Medium-High | Medium | Low |
| **Flutter Integration** | 🚧 Coming soon | ✓ Native | Manual | Manual |
| **Dependencies** | Minimal | Heavy | Minimal | Minimal |

---

## ✅ **MVP v0.1.0 - COMPLETED** 

Supafast MVP is now complete and ready for use! 🎉

## 🚀 **What's Available Now**

### Core HTTP Framework ✅
- **Express.js-style API**: `app.get()`, `app.post()`, `app.put()`, `app.delete()`
- **Path Parameters**: `/users/:id` with automatic extraction
- **Query String Parsing**: Automatic URL query parameter parsing  
- **Request/Response Wrappers**: Clean abstractions with fluent APIs
- **Middleware System**: Ordered execution with error propagation
- **Router Support**: Nested routing with `app.mount()`

### Built-in Middleware ✅
- `cors()` - Cross-Origin Resource Sharing
- `logger()` - Request/response logging with timing
- `bodyParser()` - JSON and form-data parsing
- `errorHandler()` - Centralized error handling and formatting
- `serveStatic()` - Static file serving with caching
- `compression()` - Response compression support

### Developer Experience ✅
- **Testing Utilities**: `TestApp`, `TestRequest`, `TestResponse`
- **Type Safety**: Full Dart type safety throughout
- **Zero Dependencies**: Built on pure `dart:io`
- **Examples**: Working basic server and REST API examples
- **Documentation**: Complete API docs and examples

## 🗺️ Future Roadmap

### Phase 2: Developer Experience 🔜 (Coming Next)

**Goal**: Create tooling for excellent DX

#### 2.1 CLI Tool (`supafast_cli`)
```bash
# Install
dart pub global activate supafast_cli

# Create new project
supafast create my_api
cd my_api

# Development mode with hot reload
supafast dev

# Generate client code
supafast generate client --output ../my_flutter_app/lib/api
```

#### 2.2 Project Scaffolding
```
my_api/
├── lib/
│   ├── routes/
│   │   ├── users.dart
│   │   └── posts.dart
│   ├── models/
│   │   └── user.dart
│   ├── middleware/
│   │   └── auth.dart
│   └── main.dart
├── shared/          # Generated models for Flutter
│   ├── models/
│   └── dtos/
├── test/
├── pubspec.yaml
└── supafast.yaml    # Configuration
```

#### 2.3 Validation & Error Handling
```dart
@Model()
class CreateUserDto {
  @Required()
  @Email()
  final String email;
  
  @MinLength(8)
  final String password;
}

app.post('/users', (req, res) async {
  final dto = req.body<CreateUserDto>(); // Auto-validated
  // ...
});
```

#### 2.4 Testing Utilities ✅ (Available Now)
```dart
import 'package:supafast/testing.dart';

void main() {
  test('GET /users/:id returns user', () async {
    final app = Supafast();
    final testApp = TestApp(app);
    
    app.get('/users/:id', (req, res) => res.json({'id': req.params['id']}));
    
    await testApp.start();
    final response = await testApp.get('/users/123').expect(200);
    expect(response.json, equals({'id': '123'}));
    await testApp.close();
  });
}
```

**Deliverable**: CLI tool, project templates, validation system

---

### Phase 3: Code Generation Engine 🔮 (Weeks 6-9)

**Goal**: Automatic code generation for models and serialization

#### 3.1 Model Definition
```dart
import 'package:supafast/supafast.dart';

@Model()
class User {
  final int id;
  
  @Required()
  @Email()
  final String email;
  
  final String? name;
  
  @DateTimeField()
  final DateTime createdAt;
  
  User({
    required this.id,
    required this.email,
    this.name,
    required this.createdAt,
  });
}
```

#### 3.2 Build Runner Integration
- Auto-generate `toJson()` / `fromJson()`
- Generate validation logic
- Create database models (if using ORM)
- Generate Flutter-compatible DTOs

**Generated code:**
```dart
// user.g.dart (auto-generated)
extension UserX on User {
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
  };
  
  static User fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int,
    email: json['email'] as String,
    name: json['name'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
```

#### 3.3 Shared Package Structure
```
my_project/
├── server/              # Backend Supafast app
│   ├── lib/
│   └── pubspec.yaml
├── shared/              # Generated shared code
│   ├── lib/
│   │   ├── models/     # Shared models
│   │   └── dtos/       # Data transfer objects
│   └── pubspec.yaml
└── client/              # Flutter app
    ├── lib/
    │   └── api/        # Imports 'shared' package
    └── pubspec.yaml
```

**Deliverable**: Full code generation pipeline using `build_runner` and `source_gen`

---

### Phase 4: HTTP Client Generation ⚡ (Weeks 10-11)

**Goal**: Auto-generate type-safe Flutter HTTP clients from backend routes

#### 4.1 Route Analysis
The framework analyzes your routes at build time:
```dart
// Backend route definition
app.get('/users/:id', getUserHandler);
app.post('/users', createUserHandler);
app.put('/users/:id', updateUserHandler);
app.delete('/users/:id', deleteUserHandler);
```

#### 4.2 Client Generation
Generates type-safe Flutter client:
```dart
// Generated: lib/api/client.g.dart
class SupafastClient {
  final String baseUrl;
  final Dio _dio;
  
  SupafastClient({required this.baseUrl}) : _dio = Dio(baseOptions: ...);
  
  // Auto-generated from routes
  Future<User> getUser(int id) async {
    final response = await _dio.get('$baseUrl/users/$id');
    return User.fromJson(response.data);
  }
  
  Future<User> createUser(CreateUserDto dto) async {
    final response = await _dio.post('$baseUrl/users', data: dto.toJson());
    return User.fromJson(response.data);
  }
  
  Future<User> updateUser(int id, UpdateUserDto dto) async {
    final response = await _dio.put('$baseUrl/users/$id', data: dto.toJson());
    return User.fromJson(response.data);
  }
  
  Future<void> deleteUser(int id) async {
    await _dio.delete('$baseUrl/users/$id');
  }
}
```

#### 4.3 Advanced Client Features
- Retry logic with exponential backoff
- Timeout configuration
- Request/response interceptors
- Error handling with custom exceptions
- Offline queue support (optional)

**Flutter Usage:**
```dart
final client = SupafastClient(baseUrl: 'https://api.myapp.com');

// Type-safe API calls
try {
  final user = await client.getUser(123);
  print(user.email);
} on SupafastException catch (e) {
  if (e.statusCode == 404) {
    // Handle not found
  }
}
```

**Deliverable**: Complete client generation system with Dio integration

---

### Phase 5: Database Layer (Optional) 🗄️ (Weeks 12-14)

**Goal**: Lightweight ORM for common databases

#### 5.1 Query Builder
```dart
@Model()
@Table('users')
class User extends SupafastModel {
  final int id;
  final String email;
  
  // Generated query builder
  static Future<User?> find(int id) => User.query().where('id', id).first();
  static Future<List<User>> all() => User.query().get();
  static Future<User> create(Map<String, dynamic> data) => User.query().insert(data);
}

// Usage
final user = await User.find(123);
final users = await User.query()
  .where('email', 'like', '%@gmail.com')
  .orderBy('createdAt', 'desc')
  .limit(10)
  .get();
```

#### 5.2 Supported Databases
- PostgreSQL (primary)
- SQLite (for development/testing)
- MySQL (community support)

#### 5.3 Migrations
```bash
supafast migrate create create_users_table
supafast migrate run
supafast migrate rollback
```

```dart
// migrations/001_create_users.dart
class CreateUsers extends Migration {
  @override
  Future<void> up(Schema schema) async {
    await schema.create('users', (table) {
      table.id();
      table.string('email').unique();
      table.string('name').nullable();
      table.timestamps();
    });
  }
  
  @override
  Future<void> down(Schema schema) async {
    await schema.drop('users');
  }
}
```

#### 5.4 Relations
```dart
@Model()
class User {
  final int id;
  
  @HasMany()
  List<Post>? posts;
}

@Model()
class Post {
  final int id;
  
  @BelongsTo()
  User? author;
}

// Usage with eager loading
final user = await User.query()
  .with(['posts'])
  .find(123);
```

**Deliverable**: Full ORM with query builder, migrations, and relations

---

### Phase 6: Production Features 🚀 (Weeks 15-17)

**Goal**: Make Supafast production-ready

#### 6.1 Performance
- Connection pooling for databases
- Response compression (gzip, brotli)
- Request caching middleware
- Static asset optimization

```dart
app.use(compression());
app.use(cache(duration: Duration(minutes: 5)));
app.use(rateLimit(max: 100, window: Duration(minutes: 1)));
```

#### 6.2 Security
- JWT authentication middleware
- Helmet-style security headers
- CSRF protection
- Input sanitization
- SQL injection prevention (if using ORM)

```dart
import 'package:supafast/auth.dart';

app.use(helmet());
app.use(csrf());

app.post('/login', (req, res) async {
  final token = await JWT.sign(userId: user.id);
  return res.json({'token': token});
});

app.get('/protected', [
  authenticate(), // Middleware
], (req, res) {
  final userId = req.user.id; // Extracted from JWT
  return res.json({'userId': userId});
});
```

#### 6.3 Monitoring & Logging
- Structured logging
- Performance metrics
- Health check endpoints
- Request tracing

```dart
app.get('/health', (req, res) {
  return res.json({
    'status': 'healthy',
    'uptime': app.uptime,
    'memory': processMemory(),
  });
});
```

#### 6.4 Deployment
- Docker support with optimized images
- Graceful shutdown handling
- Environment configuration
- CI/CD templates (GitHub Actions, GitLab CI)

**Dockerfile:**
```dockerfile
FROM dart:stable AS build
WORKDIR /app
COPY . .
RUN dart pub get
RUN dart compile exe lib/main.dart -o server

FROM scratch
COPY --from=build /app/server /app/server
EXPOSE 8080
CMD ["/app/server"]
```

**Deliverable**: Production-ready framework with security, monitoring, and deployment tools

---

## 📦 Package Ecosystem

The Supafast ecosystem consists of:

1. **`supafast`** (core) - The main framework
2. **`supafast_cli`** - Command-line tools
3. **`supafast_orm`** - Optional database layer
4. **`supafast_auth`** - Authentication plugins (JWT, OAuth)
5. **`supafast_client`** - Generated Flutter clients
6. **`supafast_testing`** - Testing utilities

## 🛠️ Tech Stack

- **Core**: `dart:io` HttpServer (native, no dependencies)
- **Code Generation**: `build_runner`, `source_gen`, `analyzer`
- **CLI**: `args`, `mason` (templating), `watcher` (hot reload)
- **Database**: `postgres`, `sqlite3` packages
- **HTTP Client**: `dio` (for generated clients)
- **Testing**: `test`, `mockito`

## 🎯 Success Metrics

### MVP Launch (Week 12)
- ✅ Phases 1-3 complete
- ✅ Basic client generation
- ✅ Documentation site live
- ✅ 3+ example projects
- 🎯 100+ GitHub stars
- 🎯 10+ community contributors

### V1.0 Launch (Week 18)
- ✅ All 6 phases complete
- ✅ Production-grade features
- ✅ Comprehensive documentation
- ✅ Video tutorials
- 🎯 1,000+ GitHub stars
- 🎯 Published on Product Hunt
- 🎯 50+ production deployments

## 🚀 Launch Strategy

### Pre-Launch (Weeks 1-11)
1. **Build in public** - Weekly Twitter threads on progress
2. **Early access** - Invite Flutter developers to test
3. **Content creation**:
   - Technical blog posts on Medium
   - "Building Supafast" video series
   - Live coding streams

### Launch Week (Week 12)
1. **Product Hunt launch** - Prepare hunt with demo video
2. **Social media blitz**:
   - Twitter announcement thread
   - Reddit posts (r/FlutterDev, r/dartlang)
   - Dev.to article
3. **Outreach**:
   - Flutter community Discord
   - Dart Slack workspace
   - Flutter newsletter mentions

### Post-Launch (Week 13+)
1. **Tutorial content** - "Build X in 10 minutes with Supafast"
2. **Case studies** - Real-world production apps
3. **Conference talks** - Submit to Flutter/Dart conferences
4. **Partnerships** - Collaborate with Flutter educators

## 🤝 Contributing

Supafast is open-source and welcomes contributions! Here's how you can help:

### Areas Needing Help
- [ ] Core framework development
- [ ] Documentation and examples
- [ ] Testing and bug fixes
- [ ] Code generation improvements
- [ ] Database adapters
- [ ] Middleware plugins
- [ ] Tutorial content

### Getting Started
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 📋 Current Status

**Phase**: MVP v0.1.0 Complete ✅  
**Progress**: 🎉 **MVP Released!**  
**Status**: Production-ready for HTTP APIs  
**Contributors**: Welcome! See contributing section below

### ✅ **What's Complete**
- [x] Monorepo structure with packages and examples
- [x] Express.js-style routing system
- [x] Request/Response wrappers with fluent APIs
- [x] Middleware chain with error handling
- [x] Built-in middleware (CORS, logging, body parsing, etc.)
- [x] Testing utilities and examples
- [x] Complete documentation and examples
- [x] Zero lint errors, production-ready code

### 🔜 **Next Up (v0.2.0)**
- [ ] CLI tool for project scaffolding
- [ ] Hot reload development mode
- [ ] Request validation system
- [ ] Performance optimizations

## 💡 Inspiration & Differentiation

### Inspired By
- **Express.js** - DX and routing simplicity
- **Serverpod** - Full-stack Dart code generation
- **tRPC** - Type-safe client-server communication
- **Nest.js** - Decorator-based architecture

### What Makes Supafast Different
1. **Flutter-first mindset** - Built specifically for Flutter developers
2. **Zero magic** - Pure Dart, no code generation runtime overhead
3. **Progressive complexity** - Start simple, add features as needed
4. **Minimal dependencies** - Core framework has near-zero dependencies
5. **Speed obsessed** - Both DX speed and runtime performance

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details

## 🔗 Links

- **Website**: [supafast.io](https://supafast.io)
- **Documentation**: [docs.supafast.io](https://docs.supafast.io)
- **Discord Community**: [supafast.io/discord](https://supafast.io/discord)
- **Twitter**: [@supafast_io](https://twitter.com/supafast_io)
- **GitHub**: [github.com/supafast-dart](https://github.com/supafast-dart)

## ⭐ Star History

If you find Supafast useful, please consider starring the repo to help others discover it!

---

**Built with ❤️ by the Dart community**

*Making full-stack Dart development supafast* ⚡
