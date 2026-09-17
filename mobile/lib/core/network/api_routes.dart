abstract final class ApiRoutes {
  static const String feed = '/api/v1/feed';
  static const String me = '/api/v1/me';
  static const String posts = '/api/v1/posts';
  static const String blocks = '/api/v1/blocks';
  static const String reports = '/api/v1/reports';
  static const String searchUsers = '/api/v1/search/users';
  static const String searchPosts = '/api/v1/search/posts';
  static const String searchMentions = '/api/v1/search/mentions';
  static const String authLogin = '/api/v1/auth/login';
  static const String authRegister = '/api/v1/auth/register';
  static const String moderationReports = '/api/v1/moderation/reports';

  static String post(int postId) => '/api/v1/posts/$postId';

  static String postLikes(int postId) => '/api/v1/posts/$postId/likes';

  static String postReplies(int postId) => '/api/v1/posts/${postId}/replies';

  static String profile(String username) =>
      '/api/v1/profiles/${Uri.encodeComponent(username)}';

  static String profilePosts(String username) => '${profile(username)}/posts';

  static String profileFollowers(String username) =>
      '${profile(username)}/followers';

  static String profileFollowing(String username) =>
      '${profile(username)}/following';

  static String profileFollow(String username) =>
      '/api/v1/profiles/${Uri.encodeComponent(username)}/follow';

  static String profileBlock(String username) =>
      '/api/v1/profiles/${Uri.encodeComponent(username)}/block';

  static String moderationReport(int reportId) =>
      '/api/v1/moderation/reports/$reportId';

  static String moderationResolve(int reportId) =>
      '/api/v1/moderation/reports/$reportId/resolve';

  static String moderationDismiss(int reportId) =>
      '/api/v1/moderation/reports/$reportId/dismiss';
}
