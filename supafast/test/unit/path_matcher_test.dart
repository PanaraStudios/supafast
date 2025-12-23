import 'package:test/test.dart';
import 'package:supafast/src/utils/path_matcher.dart';

void main() {
  group('PathMatcher', () {
    group('compile', () {
      test('compiles static path correctly', () {
        final pattern = PathMatcher.compile('/users');
        expect(pattern.regex.pattern, equals(r'^/users$'));
        expect(pattern.paramNames, isEmpty);
      });

      test('compiles path with single parameter', () {
        final pattern = PathMatcher.compile('/users/:id');
        expect(pattern.regex.pattern, equals(r'^/users/([^/]+)$'));
        expect(pattern.paramNames, equals(['id']));
      });

      test('compiles path with multiple parameters', () {
        final pattern = PathMatcher.compile('/users/:userId/posts/:postId');
        expect(
            pattern.regex.pattern, equals(r'^/users/([^/]+)/posts/([^/]+)$'));
        expect(pattern.paramNames, equals(['userId', 'postId']));
      });

      test('compiles complex path with mixed segments', () {
        final pattern = PathMatcher.compile('/api/v1/users/:id/profile');
        expect(
            pattern.regex.pattern, equals(r'^/api/v1/users/([^/]+)/profile$'));
        expect(pattern.paramNames, equals(['id']));
      });

      test('handles root path', () {
        final pattern = PathMatcher.compile('/');
        expect(pattern.regex.pattern, equals(r'^/$'));
        expect(pattern.paramNames, isEmpty);
      });

      test('escapes special regex characters', () {
        final pattern = PathMatcher.compile('/files/*.txt');
        expect(pattern.regex.pattern, equals(r'^/files/\*\.txt$'));
        expect(pattern.paramNames, isEmpty);
      });
    });

    group('match', () {
      test('matches static path exactly', () {
        final pattern = PathMatcher.compile('/users');
        final match = PathMatcher.match(pattern, '/users');

        expect(match, isNotNull);
        expect(match!.params, isEmpty);
      });

      test('does not match different static path', () {
        final pattern = PathMatcher.compile('/users');
        final match = PathMatcher.match(pattern, '/posts');

        expect(match, isNull);
      });

      test('matches path with parameters', () {
        final pattern = PathMatcher.compile('/users/:id');
        final match = PathMatcher.match(pattern, '/users/123');

        expect(match, isNotNull);
        expect(match!.params, equals({'id': '123'}));
      });

      test('matches path with multiple parameters', () {
        final pattern = PathMatcher.compile('/users/:userId/posts/:postId');
        final match = PathMatcher.match(pattern, '/users/123/posts/456');

        expect(match, isNotNull);
        expect(match!.params, equals({'userId': '123', 'postId': '456'}));
      });

      test('handles URL-encoded parameters', () {
        final pattern = PathMatcher.compile('/users/:name');
        final match = PathMatcher.match(pattern, '/users/john%20doe');

        expect(match, isNotNull);
        expect(match!.params, equals({'name': 'john doe'}));
      });

      test('handles special characters in parameters', () {
        final pattern = PathMatcher.compile('/search/:query');
        final match = PathMatcher.match(pattern, '/search/hello-world_123');

        expect(match, isNotNull);
        expect(match!.params, equals({'query': 'hello-world_123'}));
      });

      test('does not match if parameter is missing', () {
        final pattern = PathMatcher.compile('/users/:id');
        final match = PathMatcher.match(pattern, '/users/');

        expect(match, isNull);
      });

      test('does not match if too many segments', () {
        final pattern = PathMatcher.compile('/users/:id');
        final match = PathMatcher.match(pattern, '/users/123/extra');

        expect(match, isNull);
      });

      test('matches root path', () {
        final pattern = PathMatcher.compile('/');
        final match = PathMatcher.match(pattern, '/');

        expect(match, isNotNull);
        expect(match!.params, isEmpty);
      });
    });

    group('edge cases', () {
      test('handles empty parameter name gracefully', () {
        final pattern = PathMatcher.compile('/users/:');
        expect(pattern.paramNames, equals(['']));
      });

      test('handles consecutive slashes', () {
        final pattern = PathMatcher.compile('/users//posts');
        final match = PathMatcher.match(pattern, '/users//posts');
        expect(match, isNotNull);
      });

      test('handles parameter at end of path', () {
        final pattern = PathMatcher.compile('/files/:filename');
        final match = PathMatcher.match(pattern, '/files/document.pdf');

        expect(match, isNotNull);
        expect(match!.params, equals({'filename': 'document.pdf'}));
      });
    });
  });
}
