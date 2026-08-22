import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../domain/pulse_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class PulseRepository {
  PulseRepository(this._dio);

  final Dio _dio;

  Future<PulseFeed> getFeed() async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/feed');

      return PulseFeed.fromJson(response.data);
    } on DioException catch (error) {
      if (_isNotFound(error)) {
        return PulseFeed.fromJson(<String, dynamic>{'items': <dynamic>[]});
      }

      rethrow;
    }
  }

  Future<PulsePost> createPost({
    required String content,

    List<int> mediaIds = const <int>[],
  }) async {
    final response = await _dio.post<dynamic>(
      '/api/v1/posts',

      data: <String, dynamic>{'content': content},

      options: _jsonOptions,
    );

    return PulsePost.fromJson(_jsonMap(response.data));
  }

  Future<void> deletePost(int postId) async {
    await _dio.delete<void>('/api/v1/posts/$postId');
  }

  Future<PulsePost> createReply({
    required int postId,

    required String content,
  }) async {
    final response = await _dio.post<dynamic>(
      '/api/v1/posts/$postId/replies',

      data: <String, dynamic>{'content': content},

      options: _jsonOptions,
    );

    return PulsePost.fromJson(_jsonMap(response.data));
  }

  Future<void> likePost(int postId) async {
    await _dio.post<void>('/api/v1/posts/$postId/likes');
  }

  Future<void> unlikePost(int postId) async {
    await _dio.delete<void>('/api/v1/posts/$postId/likes');
  }

  Future<int> uploadMedia({
    required Uint8List bytes,

    required String fileName,
  }) {
    return Future<int>.error(
      UnsupportedError(
        'Standalone media upload is not defined by the canonical API contract.',
      ),
    );
  }

  Future<PulseProfile> getMe() async {
    final response = await _dio.get<dynamic>('/api/v1/me');

    return PulseProfile.fromJson(_jsonMap(response.data));
  }

  Future<PulseProfile?> getMyProfile() async {
    try {
      return await getMe();
    } on DioException catch (error) {
      if (_isNotFound(error)) {
        return null;
      }

      rethrow;
    }
  }

  Future<PulseProfile> updateMyProfile(UpdateProfileRequest request) async {
    final response = await _dio.put<dynamic>(
      '/api/v1/me',

      data: request.toJson(),

      options: _jsonOptions,
    );

    return PulseProfile.fromJson(_jsonMap(response.data));
  }

  Future<PulseProfile> getProfile(String username) async {
    final encoded = Uri.encodeComponent(username);

    final response = await _dio.get<dynamic>('/api/v1/profiles/$encoded');

    return PulseProfile.fromJson(_jsonMap(response.data));
  }

  Future<PulseFeed> getProfilePosts(String username) async {
    final encoded = Uri.encodeComponent(username);

    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/profiles/$encoded/posts',
      );

      return PulseFeed.fromJson(response.data);
    } on DioException catch (error) {
      if (_isNotFound(error)) {
        return PulseFeed.fromJson(<String, dynamic>{'items': <dynamic>[]});
      }

      rethrow;
    }
  }

  Future<void> follow(String username) async {
    final encoded = Uri.encodeComponent(username);

    await _dio.post<void>('/api/v1/profiles/$encoded/follow');
  }

  Future<void> unfollow(String username) async {
    final encoded = Uri.encodeComponent(username);

    await _dio.delete<void>('/api/v1/profiles/$encoded/follow');
  }

  Future<void> followUser(String username) {
    return follow(username);
  }

  Future<void> unfollowUser(String username) {
    return unfollow(username);
  }

  bool _isNotFound(DioException error) {
    return error.response?.statusCode == 404;
  }

  Options get _jsonOptions {
    return Options(contentType: Headers.jsonContentType);
  }

  Map<String, dynamic> _jsonMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    throw const FormatException('Response must be a JSON object');
  }
}

final pulseRepositoryProvider = Provider<PulseRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return PulseRepository(dio);
});
