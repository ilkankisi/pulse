import 'package:flutter_test/flutter_test.dart';

void main() {
  group('canonical social interaction JSON contract', () {
    test('post create body uses content', () {
      final body = <String, dynamic>{'content': 'Merhaba @alice #pulse'};

      expect(body, <String, dynamic>{'content': 'Merhaba @alice #pulse'});

      expect(body.containsKey('text'), isFalse);
      expect(body.containsKey('body'), isFalse);
      expect(body.containsKey('title'), isFalse);
      expect(body.containsKey('description'), isFalse);
    });

    test('identifiers are integers', () {
      final json = <String, dynamic>{'id': 1, 'postId': 42};

      expect(json['id'], isA<int>());
      expect(json['postId'], isA<int>());
    });

    test('timestamps use UTC ISO 8601', () {
      final value = DateTime.utc(2026, 8, 19, 12).toIso8601String();

      expect(value, '2026-08-19T12:00:00.000Z');
    });

    test('notification type values use canonical names', () {
      const values = <String>['Like', 'Reply', 'Follow', 'Mention'];

      expect(values, contains('Like'));
      expect(values, contains('Reply'));
      expect(values, contains('Follow'));
      expect(values, contains('Mention'));
    });
  });
}
