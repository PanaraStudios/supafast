/// Utility class for parsing URL query strings into key-value maps.
///
/// This class provides methods to parse query strings from URLs and convert
/// them into easily accessible Map structures.
class QueryParser {
  /// Parse a query string into a map of key-value pairs
  static Map<String, String> parse(String queryString) {
    if (queryString.isEmpty) return {};

    final result = <String, String>{};

    // Split by & and parse each pair
    for (final pair in queryString.split('&')) {
      final equalIndex = pair.indexOf('=');

      if (equalIndex == -1) {
        // No = sign, treat as flag
        final key = Uri.decodeQueryComponent(pair);
        if (key.isNotEmpty) {
          result[key] = '';
        }
      } else {
        final key = Uri.decodeQueryComponent(pair.substring(0, equalIndex));
        final value = Uri.decodeQueryComponent(pair.substring(equalIndex + 1));

        if (key.isNotEmpty) {
          result[key] = value;
        }
      }
    }

    return result;
  }

  /// Parse query parameters from a URI
  static Map<String, String> parseFromUri(Uri uri) {
    return Map<String, String>.from(uri.queryParameters);
  }
}
