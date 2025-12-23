import '../core/middleware.dart';
import '../utils/content_type.dart';
import '../exceptions/http_exception.dart';

/// Configuration options for body parser middleware.
///
/// This class allows customization of how request bodies are parsed,
/// including size limits and which content types to handle.
class BodyParserOptions {
  /// Maximum body size in bytes (default: 1MB)
  final int maxBodySize;

  /// Whether to parse JSON bodies (default: true)
  final bool json;

  /// Whether to parse URL-encoded form bodies (default: true)
  final bool urlencoded;

  /// Whether to parse raw text bodies (default: true)
  final bool text;

  /// Whether to parse multipart form bodies (default: true)
  final bool multipart;

  const BodyParserOptions({
    this.maxBodySize = 1024 * 1024, // 1MB
    this.json = true,
    this.urlencoded = true,
    this.text = true,
    this.multipart = true,
  });
}

/// Body parser middleware that parses request bodies based on Content-Type
Middleware bodyParser([BodyParserOptions? options]) {
  final opts = options ?? const BodyParserOptions();

  return (req, res, next) async {
    // Skip body parsing for methods that typically don't have bodies
    if (req.method == 'GET' ||
        req.method == 'HEAD' ||
        req.method == 'OPTIONS') {
      await next();
      return;
    }

    try {
      // Check content length
      final contentLength = req.headers.value('content-length');
      if (contentLength != null) {
        final length = int.tryParse(contentLength);
        if (length != null && length > opts.maxBodySize) {
          throw HttpException.badRequest(
            'Request body too large: $length bytes (max: ${opts.maxBodySize})',
          );
        }
      }

      final contentType = req.contentType;

      if (contentType != null) {
        if (opts.json && ContentTypeUtils.isJson(contentType)) {
          await _parseJsonBody(req, opts.maxBodySize);
        } else if (opts.urlencoded &&
            ContentTypeUtils.isFormData(contentType)) {
          await _parseFormBody(req, opts.maxBodySize);
        } else if (opts.multipart &&
            ContentTypeUtils.isMultipart(contentType)) {
          await _parseMultipartBody(req, opts.maxBodySize);
        } else if (opts.text && ContentTypeUtils.isText(contentType)) {
          await _parseTextBody(req, opts.maxBodySize);
        }
      }

      await next();
    } catch (e) {
      if (e is HttpException) {
        rethrow;
      }
      throw HttpException.badRequest('Failed to parse request body: $e');
    }
  };
}

/// JSON body parser middleware
Middleware jsonParser({int maxBodySize = 1024 * 1024}) {
  return bodyParser(BodyParserOptions(
    maxBodySize: maxBodySize,
    json: true,
    urlencoded: false,
    text: false,
  ));
}

/// URL-encoded form body parser middleware
Middleware urlencodedParser({int maxBodySize = 1024 * 1024}) {
  return bodyParser(BodyParserOptions(
    maxBodySize: maxBodySize,
    json: false,
    urlencoded: true,
    text: false,
  ));
}

/// Raw text body parser middleware
Middleware textParser({int maxBodySize = 1024 * 1024}) {
  return bodyParser(BodyParserOptions(
    maxBodySize: maxBodySize,
    json: false,
    urlencoded: false,
    text: true,
  ));
}

/// Parse JSON body
Future<void> _parseJsonBody(req, int maxBodySize) async {
  await req.parseBody(maxBodySize: maxBodySize);

  // Validate that body was parsed as JSON
  final body = req.body;
  if (body is! Map && body is! List) {
    throw HttpException.badRequest('Invalid JSON format');
  }
}

/// Parse form-encoded body
Future<void> _parseFormBody(req, int maxBodySize) async {
  await req.parseBody(maxBodySize: maxBodySize);
}

/// Parse text body
Future<void> _parseTextBody(req, int maxBodySize) async {
  await req.parseBody(maxBodySize: maxBodySize);
}

/// Parse multipart body
Future<void> _parseMultipartBody(req, int maxBodySize) async {
  await req.parseBody(maxBodySize: maxBodySize);
}
