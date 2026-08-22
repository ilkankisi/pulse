abstract final class ApiRoutes {
  static const String feed = '/api/v1/feed';
  static const String me = '/api/v1/me';
  static const String posts = '/api/v1/posts';
  static const String blocks = '/api/v1/blocks';
  static const String moderationReports = '/api/v1/moderation/reports';

  static String postLikes(int postId) => '/api/v1/posts/$postId/likes';

  static String postReplies(int postId) => '/api/v1/posts/$postId/replies';

  static String profileFollow(String username) =>
      '/api/v1/profiles/$username/follow';

  static String moderationResolve(int reportId) =>
      '/api/v1/moderation/reports/$reportId/resolve';
}
