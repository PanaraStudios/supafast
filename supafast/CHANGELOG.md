# Changelog

## 0.1.0 - 2024-01-01

### 🎉 Initial Release - MVP

This is the initial release of Supafast, a lightweight Express.js-inspired backend framework for Dart.

### ✨ Features

#### Core Framework
- **HTTP Server**: Built on native `dart:io` HttpServer for maximum performance
- **Express.js-style Routing**: Familiar API with `app.get()`, `app.post()`, etc.
- **Path Parameters**: Support for `:id` style parameters in routes
- **Query String Parsing**: Automatic parsing of URL query parameters
- **Request/Response Wrappers**: Clean abstractions over native HTTP objects

#### Middleware System
- **Middleware Chain**: Ordered execution of middleware functions
- **Error Handling**: Automatic error propagation through middleware
- **Built-in Middleware**:
  - `cors()` - Cross-Origin Resource Sharing support
  - `logger()` - Request/response logging with timing
  - `bodyParser()` - JSON and form-data body parsing
  - `errorHandler()` - Centralized error handling and formatting
  - `serveStatic()` - Static file serving with caching
  - `compression()` - Response compression (basic implementation)

#### Developer Experience
- **Testing Utilities**: `TestApp`, `TestRequest`, `TestResponse` for easy testing
- **Type Safety**: Full Dart type safety throughout the framework
- **Fluent APIs**: Method chaining for clean, readable code
- **Error Messages**: Helpful error messages and stack traces

#### Examples
- **Basic Server**: Simple HTTP server example
- **REST API**: Complete CRUD API with middleware demonstration

### 🔧 Technical Details

- **Minimum Dart SDK**: 3.0.0
- **Dependencies**: Minimal external dependencies (args, path, collection, meta)
- **Architecture**: Modular design with clear separation of concerns
- **Performance**: Zero-copy operations where possible, efficient routing

### 📚 Documentation

- Complete API documentation with examples
- Getting started guide
- Middleware development guide
- Testing best practices

### 🚀 What's Next

This MVP provides the foundation for building HTTP APIs with Dart. Future releases will include:
- CLI tooling for project scaffolding
- Code generation for Flutter clients
- Database ORM integration
- Production deployment helpers

### 🙏 Acknowledgments

Inspired by Express.js, built for the Dart and Flutter ecosystem.

---

For migration guides, API changes, and detailed release notes, see the full documentation at [docs.supafast.io](https://docs.supafast.io).