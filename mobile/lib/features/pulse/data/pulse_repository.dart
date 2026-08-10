import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/pulse_models.dart';

final pulseRepositoryProvider = Provider<PulseRepository>((ref) {
  return PulseRepository(dio: ref.watch(dioProvider));
});

class PulseRepository {
  PulseRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<PulsePost>> getFeed() async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/feed');
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
      '/api/v1/posts',
      data: request.toJson(),
    );

    return PulsePost.fromJson(_asJsonMap(response.data));
  }

  Future<void> deletePost(int postId) async {
    await _dio.delete<void>('/api/v1/posts/$postId');
  }

  Future<PulsePost> createReply({
    required int postId,
    required CreateReplyRequest request,
  }) async {
    final response = await _dio.post<dynamic>(
      '/api/v1/posts/$postId/replies',
      data: request.toJson(),
    );

    return PulsePost.fromJson(_asJsonMap(response.data));
  }

  Future<void> likePost(int postId) async {
    await _dio.post<void>('/api/v1/posts/$postId/likes');
  }

  Future<void> unlikePost(int postId) async {
    await _dio.delete<void>('/api/v1/posts/$postId/likes');
  }

  Future<PulseProfile?> getMyProfile() async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/me');
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
      final encodedUsername = Uri.encodeComponent(username);
      final response = await _dio.get<dynamic>(
        '/api/v1/profiles/$encodedUsername',
      );

      return PulseProfile.fromJson(_asJsonMap(response.data));
    } on DioException catch (error) {
      if (_isNotFound(error)) {
        return null;
      }
      rethrow;
    }
  }

  Future<List<PulsePost>> getProfilePosts(String username) async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/feed');

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
      '/api/v1/me',
      data: request.toJson(),
    );

    return PulseProfile.fromJson(_asJsonMap(response.data));
  }

  Future<void> followUser(String username) async {
    final encodedUsername = Uri.encodeComponent(username);
    await _dio.post<void>('/api/v1/profiles/$encodedUsername/follow');
  }

  Future<void> unfollowUser(String username) async {
    final encodedUsername = Uri.encodeComponent(username);
    await _dio.delete<void>('/api/v1/profiles/$encodedUsername/follow');
  }

  static bool _isNotFound(DioException error) {
    return error.response?.statusCode == 404;
  }

  static Map<String, dynamic> _asJsonMap(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw const FormatException('API yanıtı geçerli bir JSON nesnesi değil.');
  }
}
