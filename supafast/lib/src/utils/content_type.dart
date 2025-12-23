import 'dart:io';

/// Utility class for handling MIME types and Content-Type operations.
///
/// This class provides constants for common MIME types and utility methods
/// for content type detection, validation, and manipulation.
class ContentTypeUtils {
  // Common MIME types
  static const String json = 'application/json';
  static const String html = 'text/html';
  static const String css = 'text/css';
  static const String javascript = 'application/javascript';
  static const String plain = 'text/plain';
  static const String formUrlEncoded = 'application/x-www-form-urlencoded';
  static const String multipartFormData = 'multipart/form-data';
  static const String xml = 'application/xml';
  static const String pdf = 'application/pdf';
  static const String zip = 'application/zip';
  static const String octetStream = 'application/octet-stream';

  // Image types
  static const String jpeg = 'image/jpeg';
  static const String png = 'image/png';
  static const String gif = 'image/gif';
  static const String webp = 'image/webp';
  static const String svg = 'image/svg+xml';

  /// Get MIME type from file extension
  static String? fromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case '.html':
      case '.htm':
        return html;
      case '.css':
        return css;
      case '.js':
        return javascript;
      case '.json':
        return json;
      case '.xml':
        return xml;
      case '.txt':
        return plain;
      case '.pdf':
        return pdf;
      case '.zip':
        return zip;
      case '.jpg':
      case '.jpeg':
        return jpeg;
      case '.png':
        return png;
      case '.gif':
        return gif;
      case '.webp':
        return webp;
      case '.svg':
        return svg;
      default:
        return null;
    }
  }

  /// Get MIME type from file path
  static String fromFilePath(String filePath) {
    final extension = filePath.substring(filePath.lastIndexOf('.'));
    return fromExtension(extension) ?? octetStream;
  }

  /// Parse ContentType from string
  static ContentType? parse(String contentTypeString) {
    try {
      return ContentType.parse(contentTypeString);
    } catch (e) {
      return null;
    }
  }

  /// Check if content type is JSON
  static bool isJson(ContentType? contentType) {
    return contentType?.mimeType == json;
  }

  /// Check if content type is form data
  static bool isFormData(ContentType? contentType) {
    return contentType?.mimeType == formUrlEncoded;
  }

  /// Check if content type is multipart
  static bool isMultipart(ContentType? contentType) {
    return contentType?.mimeType.startsWith('multipart/') == true;
  }

  /// Check if content type is text-based
  static bool isText(ContentType? contentType) {
    if (contentType == null) return false;

    return contentType.primaryType == 'text' ||
        isJson(contentType) ||
        contentType.mimeType == javascript ||
        contentType.mimeType == xml;
  }
}
