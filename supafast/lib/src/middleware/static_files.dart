import 'dart:io';

import '../core/middleware.dart';
import '../utils/content_type.dart';
import '../exceptions/http_exception.dart';

/// Configuration options for static file serving middleware.
///
/// Controls how static files are served, including security settings,
/// caching behavior, and directory handling. Provides fine-grained
/// control over static file delivery performance and security.
///
/// Example:
/// ```dart
/// // Basic static file serving
/// final options = StaticOptions();
///
/// // Production setup with aggressive caching
/// final prodOptions = StaticOptions(
///   maxAge: 86400, // 24 hours
///   etag: true,
///   lastModified: true,
///   dotFiles: false, // Security: hide dotfiles
/// );
///
/// // Development setup
/// final devOptions = StaticOptions(
///   maxAge: 0, // No caching
///   dotFiles: false,
/// );
/// ```
class StaticOptions {
  /// Whether to serve dotfiles (files starting with '.').
  ///
  /// Dotfiles often contain sensitive configuration or system files
  /// that should not be publicly accessible. Disable this in production
  /// for security. Default is false for safety.
  final bool dotFiles;

  /// Default file to serve when requesting a directory.
  ///
  /// When a request targets a directory, this file will be served
  /// if it exists. Common values are 'index.html' or 'index.htm'.
  /// Set to null to disable directory index serving.
  final String? index;

  /// Maximum age for cache headers in seconds.
  ///
  /// Sets the 'Cache-Control: max-age' header to enable browser
  /// and proxy caching. Higher values improve performance but may
  /// delay updates. Set to null to disable cache headers.
  final int? maxAge;

  /// Whether to generate and set ETag headers.
  ///
  /// ETags enable efficient caching by allowing clients to check
  /// if files have changed. Recommended for production deployments.
  final bool etag;

  /// Whether to set Last-Modified headers.
  ///
  /// Enables date-based caching where clients can check if files
  /// have been modified since their cached version. Works with ETags.
  final bool lastModified;

  /// Creates static file serving options with the specified settings.
  ///
  /// [dotFiles] Whether to serve dotfiles (default: false for security).
  /// [index] Default directory index file (default: 'index.html').
  /// [maxAge] Cache duration in seconds (default: null, no caching).
  /// [etag] Whether to generate ETag headers (default: true).
  /// [lastModified] Whether to set Last-Modified headers (default: true).
  const StaticOptions({
    this.dotFiles = false,
    this.index = 'index.html',
    this.maxAge,
    this.etag = true,
    this.lastModified = true,
  });
}

/// Static file serving middleware for delivering files from a directory.
///
/// Serves static files (HTML, CSS, JavaScript, images, etc.) from a specified
/// directory with security protections, caching support, and directory traversal
/// prevention. Handles content-type detection, conditional requests, and
/// proper HTTP semantics.
///
/// Example:
/// ```dart
/// // Serve files from 'public' directory
/// app.use(serveStatic('public'));
///
/// // Serve with custom options
/// app.use(serveStatic('assets', StaticOptions(
///   maxAge: 3600, // 1 hour cache
///   dotFiles: false, // Security: hide dotfiles
///   index: 'index.html',
/// )));
///
/// // Serve from absolute path
/// app.use(serveStatic('/var/www/static'));
///
/// // Use convenience functions
/// app.use(publicFiles()); // Serves from 'public' directory
/// app.use(staticWithCaching('assets')); // Serves with 24h caching
/// ```
///
/// Features:
/// - **Security**: Prevents directory traversal attacks
/// - **Performance**: Supports ETag and Last-Modified caching
/// - **Content-Type**: Automatic MIME type detection
/// - **Conditional Requests**: Handles If-None-Match and If-Modified-Since
/// - **Directory Index**: Optional index file serving for directories
/// - **HEAD Support**: Proper HEAD request handling
///
/// Security protections:
/// - Blocks access to files outside the specified directory
/// - Prevents directory traversal with '..' patterns
/// - Optional dotfile hiding (recommended for production)
/// - Path sanitization and validation
///
/// HTTP features:
/// - Proper Content-Type headers based on file extensions
/// - Content-Length headers for efficient transfers
/// - ETag generation for cache validation
/// - Last-Modified headers for date-based caching
/// - 304 Not Modified responses for unchanged files
///
/// [directory] Path to the directory containing static files (relative or absolute).
/// [options] Configuration options for serving behavior.
///
/// Returns a [Middleware] function that serves static files.
///
/// Throws [HttpException] if file serving fails due to I/O errors.
///
/// Note: Only handles GET and HEAD requests. Other methods pass through
/// to the next middleware. File not found continues to next middleware
/// rather than returning 404.
Middleware serveStatic(String directory, [StaticOptions? options]) {
  final opts = options ?? const StaticOptions();
  final absoluteDirectory = Directory(directory).absolute.path;

  return (req, res, next) async {
    // Only handle GET and HEAD requests
    if (req.method != 'GET' && req.method != 'HEAD') {
      return next();
    }

    try {
      // Build file path
      String requestPath = req.path;

      // Remove leading slash and decode URI components
      if (requestPath.startsWith('/')) {
        requestPath = requestPath.substring(1);
      }
      requestPath = Uri.decodeComponent(requestPath);

      // Security: prevent directory traversal
      if (requestPath.contains('..')) {
        return next();
      }

      final filePath = '$absoluteDirectory/$requestPath';
      final file = File(filePath);

      // Additional security check
      if (!file.absolute.path.startsWith(absoluteDirectory)) {
        return next();
      }

      final stat = await file.stat();

      // Handle directories
      if (stat.type == FileSystemEntityType.directory) {
        if (opts.index != null) {
          final indexFile = File('$filePath/${opts.index!}');
          if (await indexFile.exists()) {
            await _serveFile(indexFile, req, res, opts);
            return;
          }
        }
        // Directory listing is not supported, continue to next middleware
        return next();
      }

      // Handle files
      if (stat.type == FileSystemEntityType.file) {
        // Check dotfiles
        final fileName = file.path.split('/').last;
        if (!opts.dotFiles && fileName.startsWith('.')) {
          return next();
        }

        await _serveFile(file, req, res, opts);
        return;
      }

      // File not found, continue to next middleware
      return next();
    } catch (e) {
      if (e is FileSystemException) {
        // File not found or access denied, continue to next middleware
        return next();
      }
      rethrow;
    }
  };
}

/// Serve a single file with proper HTTP headers and caching support.
///
/// Handles all aspects of file serving including content-type detection,
/// cache header generation, conditional request handling, and efficient
/// file streaming. Implements HTTP best practices for static file delivery.
///
/// [file] The file to serve.
/// [req] The HTTP request object.
/// [res] The HTTP response object.
/// [opts] Static serving options.
///
/// Throws [HttpException] if file cannot be served due to I/O errors.
Future<void> _serveFile(
  File file,
  req,
  res,
  StaticOptions opts,
) async {
  try {
    final stat = await file.stat();
    final lastModified = stat.modified;
    final size = stat.size;

    // Set Content-Type
    final mimeType = ContentTypeUtils.fromFilePath(file.path);
    res.contentType(mimeType);

    // Set Content-Length
    res.header('Content-Length', size.toString());

    // Set Last-Modified header
    if (opts.lastModified) {
      res.header('Last-Modified', HttpDate.format(lastModified));
    }

    // Set ETag header
    String? etag;
    if (opts.etag) {
      etag = _generateETag(stat);
      res.header('ETag', etag);
    }

    // Set Cache-Control header
    if (opts.maxAge != null) {
      res.header('Cache-Control', 'public, max-age=${opts.maxAge}');
    }

    // Check If-None-Match (ETag-based caching)
    if (etag != null) {
      final ifNoneMatch = req.header('if-none-match');
      if (ifNoneMatch == etag) {
        return res.sendStatus(304); // Not Modified
      }
    }

    // Check If-Modified-Since (date-based caching)
    if (opts.lastModified) {
      final ifModifiedSince = req.header('if-modified-since');
      if (ifModifiedSince != null) {
        try {
          final ifModifiedSinceDate = HttpDate.parse(ifModifiedSince);
          if (!lastModified.isAfter(ifModifiedSinceDate)) {
            return res.sendStatus(304); // Not Modified
          }
        } catch (_) {
          // Invalid date format, ignore
        }
      }
    }

    // Handle HEAD requests
    if (req.method == 'HEAD') {
      return res.sendStatus(200);
    }

    // Stream the file
    await res.file(file.path);
  } catch (e) {
    throw HttpException.internalServerError('Failed to serve file: $e');
  }
}

/// Generate ETag for a file based on its metadata.
///
/// Creates a strong ETag using file size and modification time.
/// The ETag format is '"size-modifiedTime"' where both values
/// are in hexadecimal for compactness.
///
/// [stat] File statistics containing size and modification time.
/// Returns a properly quoted ETag string suitable for HTTP headers.
String _generateETag(FileStat stat) {
  final size = stat.size;
  final modified = stat.modified.millisecondsSinceEpoch;
  return '"${size.toRadixString(16)}-${modified.toRadixString(16)}"';
}

/// Serve static files from a 'public' directory with default options.
///
/// Convenience function for the common pattern of serving static files
/// from a 'public' directory. Equivalent to `serveStatic('public', options)`.
///
/// Example:
/// ```dart
/// // Basic public file serving
/// app.use(publicFiles());
///
/// // Public files with custom caching
/// app.use(publicFiles(StaticOptions(
///   maxAge: 3600,
///   dotFiles: false,
/// )));
/// ```
///
/// [options] Configuration options for file serving.
/// Returns a [Middleware] that serves files from the 'public' directory.
Middleware publicFiles([StaticOptions? options]) {
  return serveStatic('public', options);
}

/// Serve static files with aggressive caching enabled.
///
/// Convenience function that configures static file serving with
/// optimal caching settings for production deployments. Enables
/// both ETag and Last-Modified headers with a configurable max-age.
///
/// Example:
/// ```dart
/// // 24-hour caching (default)
/// app.use(staticWithCaching('assets'));
///
/// // 1-hour caching
/// app.use(staticWithCaching('public', maxAge: 3600));
///
/// // 1-week caching for long-term assets
/// app.use(staticWithCaching('cdn', maxAge: 604800));
/// ```
///
/// [directory] Directory containing static files to serve.
/// [maxAge] Cache duration in seconds (default: 86400 = 24 hours).
///
/// Returns a [Middleware] configured with aggressive caching.
Middleware staticWithCaching(String directory, {int maxAge = 86400}) {
  return serveStatic(
    directory,
    StaticOptions(
      maxAge: maxAge,
      etag: true,
      lastModified: true,
    ),
  );
}
