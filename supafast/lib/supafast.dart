/// A lightweight, Express.js-inspired backend framework for Dart.
///
/// Supafast provides a simple, familiar API for building HTTP servers with
/// first-class support for middleware, routing, and request/response handling.
library supafast;

// Core exports
export 'src/core/supafast_app.dart';
export 'src/core/request.dart';
export 'src/core/response.dart';
export 'src/core/router.dart';
export 'src/core/route.dart';
export 'src/core/middleware.dart';

// Built-in middleware exports
export 'src/middleware/cors.dart';
export 'src/middleware/logger.dart';
export 'src/middleware/body_parser.dart';
export 'src/middleware/error_handler.dart';
export 'src/middleware/compression.dart';
export 'src/middleware/static_files.dart';

// Utility exports
export 'src/utils/path_matcher.dart';
export 'src/utils/query_parser.dart';
export 'src/utils/content_type.dart';

// Exception exports
export 'src/exceptions/supafast_exception.dart';
export 'src/exceptions/http_exception.dart';
