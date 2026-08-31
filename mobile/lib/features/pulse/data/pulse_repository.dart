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



  Future<PulsePost> createReply({

    required int postId,

    required CreateReplyRequest request,

  }) async {

    final response = await _dio.post<dynamic>(

      ApiRoutes.postReplies(postId),

      data: request.toJson(),

    );



    return PulsePost.fromJson(_asJsonMap(response.data));

  }



  Future<void> likePost(int postId) async {

    await _dio.post<void>(ApiRoutes.postLikes(postId));

  }



  Future<void> unlikePost(int postId) async {

    await _dio.delete<void>(ApiRoutes.postLikes(postId));

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

    try {

      final response = await _dio.get<dynamic>(ApiRoutes.profilePosts(username));

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

    final response = await _dio.get<dynamic>(ApiRoutes.profileFollowers(username));

    return _socialGraphUsers(response.data);

  }



  Future<List<PulseSocialGraphUser>> getFollowing(String username) async {

    final response = await _dio.get<dynamic>(ApiRoutes.profileFollowing(username));

    return _socialGraphUsers(response.data);

  }



  static bool _isNotFound(DioException error) {

    return error.response?.statusCode == 404;

  }



  static List<PulseSocialGraphUser> _socialGraphUsers(dynamic data) {

    final json = _asJsonMap(data);

    final items = json['items'];



    if (items is! List) {

      throw const FormatException(

        'Sosyal graf yanıtı geçerli bir items listesi içermiyor.',

      );

    }



    final users = <PulseSocialGraphUser>[];



    for (final item in items) {

      if (item is! Map) {

        throw const FormatException(

          'Sosyal graf kullanıcı verisi geçerli değil.',

        );

      }



      users.add(PulseSocialGraphUser.fromJson(Map<String, dynamic>.from(item)));

    }



    return List<PulseSocialGraphUser>.unmodifiable(users);

  }



  static Map<String, dynamic> _asJsonMap(dynamic data) {

    if (data is Map) {

      return Map<String, dynamic>.from(data);

    }



    throw const FormatException('API yanıtı geçerli bir JSON nesnesi değil.');

  }

}


