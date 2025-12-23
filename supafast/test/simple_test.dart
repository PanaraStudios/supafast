import 'package:test/test.dart';

void main() {
  group('Simple Test', () {
    test('basic test works', () {
      expect(1 + 1, equals(2));
    });

    test('string concatenation works', () {
      expect('hello' + ' world', equals('hello world'));
    });

    test('list operations work', () {
      final list = [1, 2, 3];
      expect(list.length, equals(3));
      expect(list.first, equals(1));
      expect(list.last, equals(3));
    });
  });
}
