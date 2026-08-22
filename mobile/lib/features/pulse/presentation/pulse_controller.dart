import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pulse_repository.dart';
import '../domain/pulse_models.dart';

class PulseState {
  const PulseState({
    this.posts = const <PulsePost>[],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final List<PulsePost> posts;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  bool get isEmpty => !isLoading && errorMessage == null && posts.isEmpty;

  PulseState copyWith({
    List<PulsePost>? posts,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PulseState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final pulseControllerProvider =
    StateNotifierProvider<PulseController, PulseState>((ref) {
      return PulseController(ref.watch(pulseRepositoryProvider));
    });

class PulseController extends StateNotifier<PulseState> {
  PulseController(this._repository) : super(const PulseState());

  final PulseRepository _repository;

  Future<void> loadFeed() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final List<PulsePost> posts = await _repository.getFeed();
      state = PulseState(posts: _sortPosts(posts));
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _errorMessage(error, 'Akış yüklenemedi'),
      );
    } on FormatException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Akış yüklenemedi',
      );
    }
  }

  Future<bool> createPost(String content) async {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty || trimmedContent.length > 280) {
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final PulsePost createdPost = await _repository.createPost(
        CreatePostRequest(content: trimmedContent),
      );

      state = state.copyWith(
        posts: _sortPosts(<PulsePost>[createdPost, ...state.posts]),
        isSubmitting: false,
      );
      return true;
    } on DioException catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _errorMessage(
          error,
          'Gönderi paylaşılamadı. Taslağınız korundu.',
        ),
      );
      return false;
    } on FormatException {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Gönderi paylaşılamadı. Taslağınız korundu.',
      );
      return false;
    }
  }

  Future<bool> createReply({
    required int postId,
    required String content,
  }) async {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty || trimmedContent.length > 280) {
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      await _repository.createReply(
        postId: postId,
        request: CreateReplyRequest(content: trimmedContent),
      );

      final updatedPosts = <PulsePost>[];
      for (final post in state.posts) {
        if (post.id == postId) {
          updatedPosts.add(post.copyWith(replyCount: post.replyCount + 1));
        } else {
          updatedPosts.add(post);
        }
      }

      state = state.copyWith(
        posts: List<PulsePost>.unmodifiable(updatedPosts),
        isSubmitting: false,
      );
      return true;
    } on DioException catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _errorMessage(
          error,
          'Yanıt gönderilemedi. Taslağınız korundu.',
        ),
      );
      return false;
    } on FormatException {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Yanıt gönderilemedi. Taslağınız korundu.',
      );
      return false;
    }
  }

  Future<void> toggleLike(PulsePost post) async {
    final nextIsLiked = !post.isLiked;
    final nextLikeCount = nextIsLiked
        ? post.likeCount + 1
        : (post.likeCount > 0 ? post.likeCount - 1 : 0);

    _replacePost(post.copyWith(isLiked: nextIsLiked, likeCount: nextLikeCount));

    try {
      if (nextIsLiked) {
        await _repository.likePost(post.id);
      } else {
        await _repository.unlikePost(post.id);
      }
    } on DioException catch (error) {
      _replacePost(post);
      state = state.copyWith(
        errorMessage: _errorMessage(error, 'Beğeni güncellenemedi.'),
      );
    }
  }

  Future<bool> deletePost(int postId) async {
    state = state.copyWith(clearError: true);

    try {
      await _repository.deletePost(postId);

      final remainingPosts = state.posts
          .where((post) => post.id != postId)
          .toList(growable: false);

      state = state.copyWith(posts: remainingPosts);
      return true;
    } on DioException catch (error) {
      state = state.copyWith(
        errorMessage: _errorMessage(error, 'Gönderi silinemedi.'),
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void _replacePost(PulsePost replacement) {
    final updatedPosts = <PulsePost>[];

    for (final post in state.posts) {
      updatedPosts.add(post.id == replacement.id ? replacement : post);
    }

    state = state.copyWith(posts: List<PulsePost>.unmodifiable(updatedPosts));
  }

  static List<PulsePost> _sortPosts(Iterable<PulsePost> posts) {
    final sortedPosts = List<PulsePost>.of(posts);
    sortedPosts.sort(
      (left, right) => right.createdAt.compareTo(left.createdAt),
    );
    return List<PulsePost>.unmodifiable(sortedPosts);
  }

  static String _errorMessage(DioException exception, String fallback) {
    final data = exception.response?.data;

    if (data is Map) {
      final json = Map<String, dynamic>.from(data);
      final message = json['error'] ?? json['message'];

      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    return fallback;
  }
}
