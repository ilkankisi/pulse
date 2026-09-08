import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/network/api_routes.dart';

void main() {
  group('ApiRoutes upstream contract', () {
    test('feed uses canonical API path', () {
      expect(ApiRoutes.feed, '/api/v1/feed');
    });

    test('posts uses canonical API path', () {
      expect(ApiRoutes.posts, '/api/v1/posts');
    });
  });
}
