import 'package:dio/dio.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

import '../../../core/network/api_routes.dart';

import '../domain/pulse_models.dart';

final pulseRepositoryProvider = Provider<PulseRepository>((ref) {
  return PulseRepository(dio: ref.watch(dioProvider));
});

class PulseRepository {
  PulseRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<PulsePost>> getFeed() async {
    try {
      final response = await _dio.get<dynamic>(ApiRoutes.feed);

      return PulseFeed.fromJson(response.data).posts;
    } on DioException catch (error) {
      if (_isNotFound(error)) {
        return const <PulsePost>[];
      }

      rethrow;
    }
  }

  Future<List<PulseProfile>> searchUsers(String query) async {
    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      return const <PulseProfile>[];
    }

    try {
      final response = await _dio.get<dynamic>(
        ApiRoutes.searchUsers,
        queryParameters: <String, dynamic>{'q': normalizedQuery},
      );

      return _profilesFromJson(response.data);
    } on DioException catch (error) {
      if (_isNotFound(error)) {
        return const <PulseProfile>[];
      }

      rethrow;
    }
  }

  Future<List<PulsePost>> searchPosts(String query) async {
    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      return const <PulsePost>[];
    }

    try {
      final response = await _dio.get<dynamic>(
        ApiRoutes.searchPosts,
        queryParameters: <String, dynamic>{'q': normalizedQuery},
      );

      return PulseFeed.fromJson(response.data).posts;
    } on DioException catch (error) {
      if (_isNotFound(error)) {
        return const <PulsePost>[];
      }

      rethrow;
    }
  }

  Future<PulsePost> createPost(CreatePostRequest request) async {
    final response = await _dio.post<dynamic>(
      ApiRoutes.posts,

      data: request.toJson(),
    );

    return PulsePost.fromJson(_asJsonMap(response.data));
  }

  Future<void> deletePost(int postId) async {
    await _dio.delete<void>(ApiRoutes.post(postId));
  }

  Future<List<PulsePost>> getPostReplies(int postId) async {
    try {
      final response = await _dio.get<dynamic>(ApiRoutes.postReplies(postId));

      return PulseFeed.fromJson(response.data).posts;
    } on DioException catch (error) {
      if (_isNotFound(error)) {
        return const <PulsePost>[];
      }

      rethrow;
    }
  }

  Future<dynamic> getPostLikes(int postId) async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/posts/$postId/likes');

      if (response.data == null) {
        throw const FormatException('Beğeni listesi okunamadı.');
      }

      return response.data;
    } on DioException catch (error) {
      if (_isNotFound(error)) {
        return const <dynamic>[];
      }

      rethrow;
    }
  }

  Future<PulsePost> createReply({
    required int postId,

    required CreateReplyRequest request,
  }) async {
    final requestBody = request.toJson();

    final response = await _dio.post<dynamic>(
      ApiRoutes.postReplies(postId),
      data: requestBody,
    );

    final createdReply = PulsePost.fromJson(_asJsonMap(response.data));

    try {
      final canonicalReplies = await getPostReplies(postId);

      for (final reply in canonicalReplies) {
        if (reply.id == createdReply.id) {
          return reply;
        }
      }
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        rethrow;
      }

      return createdReply;
    } on FormatException {
      return createdReply;
    }

    return createdReply;
  }

  Future<dynamic> likePost(int postId) async {
    await _dio.post<void>('/api/v1/posts/$postId/likes');

    final likeReadResponse = await _dio.get<dynamic>(
      '/api/v1/posts/$postId/likes',
    );
    final canonicalLikes = likeReadResponse.data;

    if (canonicalLikes == null) {
      throw const FormatException('Beğeni listesi okunamadı.');
    }

    return canonicalLikes;
  }

  Future<dynamic> unlikePost(int postId) async {
    await _dio.delete<void>('/api/v1/posts/$postId/likes');

    final response = await _dio.get<dynamic>('/api/v1/posts/$postId/likes');

    if (response.data == null) {
      throw const FormatException('Beğeni listesi okunamadı.');
    }

    return response.data;
  }

  Future<PulseProfile?> getMyProfile() async {
    try {
      final response = await _dio.get<dynamic>(ApiRoutes.me);

      return PulseProfile.fromJson(_asJsonMap(response.data));
    } on DioException catch (error) {
      if (_isNotFound(error)) {
        return null;
      }

      rethrow;
    }
  }

  Future<PulseProfile?> getProfile(String username) async {
    try {
      final response = await _dio.get<dynamic>(ApiRoutes.profile(username));

      return PulseProfile.fromJson(_asJsonMap(response.data));
    } on DioException catch (error) {
      if (_isNotFound(error)) {
        return null;
      }

      rethrow;
    }
  }

  Future<List<PulsePost>> getProfilePosts(String username) async {
    final normalizedUsername = username.trim();

    if (normalizedUsername.isEmpty) {
      return const <PulsePost>[];
    }

    try {
      final response = await _dio.get<dynamic>(
        ApiRoutes.profilePosts(normalizedUsername),
      );

      return PulseFeed.fromJson(response.data).posts;
    } on DioException catch (error) {
      if (_isNotFound(error)) {
        return const <PulsePost>[];
      }

      rethrow;
    }
  }

  Future<PulseProfile> updateMyProfile(UpdateProfileRequest request) async {
    final response = await _dio.put<dynamic>(
      ApiRoutes.me,

      data: request.toJson(),
    );

    return PulseProfile.fromJson(_asJsonMap(response.data));
  }

  Future<void> followUser(String username) async {
    await _dio.post<void>(ApiRoutes.profileFollow(username));
  }

  Future<void> unfollowUser(String username) async {
    await _dio.delete<void>(ApiRoutes.profileFollow(username));
  }

  Future<List<PulseSocialGraphUser>> getFollowers(String username) async {
    return _getSocialGraph(ApiRoutes.profileFollowers(username));
  }

  Future<List<PulseSocialGraphUser>> getFollowing(String username) async {
    return _getSocialGraph(ApiRoutes.profileFollowing(username));
  }

  Future<List<PulseSocialGraphUser>> _getSocialGraph(String path) async {
    try {
      final response = await _dio.get<dynamic>(path);

      return _socialGraphFromJson(response.data);
    } on DioException catch (error) {
      if (_isNotFound(error)) {
        return const <PulseSocialGraphUser>[];
      }

      rethrow;
    }
  }

  List<PulseSocialGraphUser> _socialGraphFromJson(dynamic data) {
    final json = _asJsonMap(data);

    final items = json['items'];

    if (items is! List) {
      throw const FormatException('Sosyal grafik listesi okunamadı.');
    }

    return items
        .map((item) => PulseSocialGraphUser.fromJson(_asJsonMap(item)))
        .toList(growable: false);
  }

  List<PulseProfile> _profilesFromJson(dynamic data) {
    dynamic items = data;

    if (data is Map) {
      final json = Map<String, dynamic>.from(data);

      items = json['items'] ?? json['users'] ?? json['data'];
    }

    if (items is! List) {
      throw const FormatException('Kullanıcı listesi okunamadı.');
    }

    return items
        .map((item) => PulseProfile.fromJson(_asJsonMap(item)))
        .toList(growable: false);
  }

  bool _isNotFound(DioException error) {
    return error.response?.statusCode == 404;
  }

  Map<String, dynamic> _asJsonMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    throw const FormatException('Yanıt geçerli bir JSON nesnesi değil.');
  }
}
