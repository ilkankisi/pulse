import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/pulse/domain/pulse_models.dart';

void main() {
  group('Pulse write request backend golden JSON contract', () {
    test('CreatePostRequest canonical request body ile eşleşir', () {
      final request = CreatePostRequest(content: '  Merhaba Pulse.  ');

      expect(request.toJson(), <String, dynamic>{'content': 'Merhaba Pulse.'});
    });

    test('CreateReplyRequest canonical request body ile eşleşir', () {
      final request = CreateReplyRequest(content: '  Katılıyorum.  ');

      expect(request.toJson(), <String, dynamic>{'content': 'Katılıyorum.'});
    });
  });
}
