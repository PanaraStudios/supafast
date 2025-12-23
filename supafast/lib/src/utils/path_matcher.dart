/// Utility class for converting Express-style path patterns to regex patterns.
///
/// This class handles the compilation and matching of route patterns that include
/// parameters (e.g., '/users/:id') and wildcards (e.g., '/files/*').
class PathMatcher {
  /// Convert path pattern like `/users/:id` to regex and extract param names
  static PathPattern compile(String path) {
    final paramNames = <String>[];

    // Escape special regex characters except :, *, and /
    var pattern = path
        .replaceAll(RegExp(r'[.+^$(){}|[\]\\]'), r'\$&')
        .replaceAll('?', r'\?');

    // Replace :param with regex capture groups
    pattern = pattern.replaceAllMapped(
      RegExp(r':([a-zA-Z_][a-zA-Z0-9_]*)'),
      (match) {
        paramNames.add(match.group(1)!);
        return r'([^/]+)'; // Match anything except /
      },
    );

    // Handle wildcards
    pattern = pattern.replaceAll('*', r'([^/]*)');

    // Anchor to start and end
    pattern = '^$pattern\$';

    return PathPattern(
      regex: RegExp(pattern),
      paramNames: paramNames,
    );
  }

  /// Match a path against a pattern and extract parameters
  static RouteMatch? match(PathPattern pattern, String path) {
    final match = pattern.regex.firstMatch(path);
    if (match == null) return null;

    final params = <String, String>{};
    for (var i = 0; i < pattern.paramNames.length; i++) {
      final value = match.group(i + 1);
      if (value != null) {
        params[pattern.paramNames[i]] = Uri.decodeComponent(value);
      }
    }

    return RouteMatch(params: params);
  }
}

/// Compiled path pattern with regex and parameter names
class PathPattern {
  final RegExp regex;
  final List<String> paramNames;

  const PathPattern({
    required this.regex,
    required this.paramNames,
  });
}

/// Result of matching a path against a pattern
class RouteMatch {
  final Map<String, String> params;

  const RouteMatch({required this.params});
}
