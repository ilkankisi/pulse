import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/network/api_routes.dart';

void main() {
  group('ApiRoutes upstream contract', () {
    test('feed route geçerli relative API path tanımıdır', () {
      expect(ApiRoutes.feed, isNotEmpty);
      expect(ApiRoutes.feed, startsWith('/'));
      expect(Uri.parse(ApiRoutes.feed).hasScheme, isFalse);
    });

    test('posts route geçerli relative API path tanımıdır', () {
      expect(ApiRoutes.posts, isNotEmpty);
      expect(ApiRoutes.posts, startsWith('/'));
      expect(Uri.parse(ApiRoutes.posts).hasScheme, isFalse);
    });
  });
}
