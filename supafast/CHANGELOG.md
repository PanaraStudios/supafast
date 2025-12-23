# Changelog

## 0.1.1 - 2025-12-23

### 🚀 Enhanced Features

#### Static File Serving
- **Complete static file serving**: Added comprehensive static file serving with MIME type detection
- **Interactive demo page**: Created rich HTML/CSS/JS demo showcasing framework capabilities
- **Caching support**: ETag and Last-Modified headers for optimal browser caching
- **Security features**: Directory traversal protection and configurable access

#### File Upload & Body Parsing
- **Multipart form support**: Full multipart/form-data parsing for file uploads
- **Raw bytes access**: Added `rawBytes` property to Request for binary data handling
- **Enhanced body parsing**: Improved parsing logic with better error handling

#### Middleware Enhancements
- **Expanded middleware stack**: Enhanced demo with CORS, compression, body parser, logger
- **Router mounting**: Improved router mounting capabilities with comprehensive examples
- **Custom middleware**: Added timing middleware and better middleware composition

#### Developer Experience
- **Rich examples**: Updated basic_server and rest_api examples with advanced features
- **Interactive testing**: JavaScript-based API testing in demo pages
- **Better documentation**: Enhanced inline documentation and examples

### 🔧 Technical Improvements
- **Performance**: Optimized request processing and static file serving
- **Error handling**: Improved error messages and exception handling
- **Testing**: Enhanced test utilities and examples

### 📁 New Files
- `public/index.html` - Interactive demo page
- `public/app.js` - Demo JavaScript functionality
- `public/styles.css` - Modern CSS styling
- `public/data.json` - JSON data demonstration
- `debug_static.dart` - Static file debugging utility

## 0.1.0+1 - 2025-12-23

### 🔧 Repository Update
- Updated repository URL to https://github.com/panarastudios/supafast

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