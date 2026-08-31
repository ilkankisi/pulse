import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_models.dart';
import '../data/pulse_repository.dart';
import '../domain/pulse_models.dart';
import 'composer_sheet.dart';
import 'post_detail_page.dart';
import 'profile_page.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({
    required this.currentUser,
    required this.onUnauthorized,
    super.key,
  });

  final AuthUser currentUser;
  final Future<void> Function() onUnauthorized;

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  static const int _initialChildCount = 39;
  static const int _scrollChunk = 40;

  final ScrollController _scrollController = ScrollController();

  List<PulsePost> _posts = const <PulsePost>[];
  bool _isLoading = true;
  String? _errorMessage;
  int _renderedChildCount = _initialChildCount;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeExpandRenderedWindow);
    Future<void>.microtask(_loadFeed);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int _maxChildCount() {
    if (_posts.isEmpty) {
      return 0;
    }

    return (_posts.length * 2) - 1;
  }

  void _maybeExpandRenderedWindow() {
    if (!_scrollController.hasClients || _posts.isEmpty) {
      return;
    }

    final maxChildCount = _maxChildCount();
    if (_renderedChildCount >= maxChildCount) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 240) {
      return;
    }

    setState(() {
      _renderedChildCount = (_renderedChildCount + _scrollChunk).clamp(
        _initialChildCount,
        maxChildCount,
      );
    });
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final posts = await ref.read(pulseRepositoryProvider).getFeed();

      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
          _renderedChildCount = _initialChildCount.clamp(
            0,
            _maxChildCountFor(posts),
          );
        });
      }
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await widget.onUnauthorized();
        return;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _readError(error, 'Akış yüklenemedi');
        });
      }
    } on FormatException {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Akış yüklenemedi';
        });
      }
    }
  }

  Future<void> _openComposer() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      elevation: 3,
      builder: (context) =>
          ComposerSheet(onUnauthorized: widget.onUnauthorized),
    );

    if (created == true) {
      await _loadFeed();
    }
  }

  Future<void> _openPost(PulsePost post) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) =>
            PostDetailPage(post: post, onUnauthorized: widget.onUnauthorized),
      ),
    );

    if (changed == true) {
      await _loadFeed();
    }
  }

  void _openProfile(PulsePost post) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ProfilePage(
          username: post.author.username,
          isCurrentUser: post.author.id == widget.currentUser.id,
          showAppBar: true,
          onUnauthorized: widget.onUnauthorized,
        ),
      ),
    );
  }

  Future<void> _toggleLike(PulsePost post) async {
    final index = _posts.indexWhere((item) => item.id == post.id);

    if (index < 0) {
      return;
    }

    final optimistic = post.copyWith(
      isLiked: !post.isLiked,
      likeCount: post.isLiked
          ? (post.likeCount > 0 ? post.likeCount - 1 : 0)
          : post.likeCount + 1,
    );

    setState(() {
      final posts = List<PulsePost>.from(_posts);
      posts[index] = optimistic;
      _posts = posts;
    });

    try {
      final repository = ref.read(pulseRepositoryProvider);

      if (post.isLiked) {
        await repository.unlikePost(post.id);
      } else {
        await repository.likePost(post.id);
      }
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await widget.onUnauthorized();
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        final posts = List<PulsePost>.from(_posts);
        posts[index] = post;
        _posts = posts;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_readError(error, 'Beğeni güncellenemedi.'))),
      );
    }
  }

  Future<void> _deletePost(PulsePost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gönderi silinsin mi?'),
        content: const Text('Bu işlem geri alınamaz.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(pulseRepositoryProvider).deletePost(post.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _posts = _posts
            .where((item) => item.id != post.id)
            .toList(growable: false);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gönderi silindi.')));
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await widget.onUnauthorized();
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_readError(error, 'Gönderi silinemedi.'))),
        );
      }
    }
  }

  Widget _statePanel({
    required IconData icon,
    required String title,
    required String description,
    required String actionLabel,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 48, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton(onPressed: onPressed, child: Text(actionLabel)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadFeed,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          if (_isLoading && _posts.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null && _posts.isEmpty)
            _statePanel(
              icon: Icons.cloud_off_outlined,
              title: 'Akış yüklenemedi',
              description: _errorMessage!,
              actionLabel: 'Tekrar Dene',
              onPressed: _loadFeed,
            )
          else if (_posts.isEmpty)
            _statePanel(
              icon: Icons.forum_outlined,
              title: 'Akış henüz boş',
              description: 'İlk gönderini paylaşarak konuşmayı başlat.',
              actionLabel: 'Gönderi Oluştur',
              onPressed: _openComposer,
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final postIndex = index ~/ 2;

                  if (index.isOdd) {
                    return const SizedBox(height: 12);
                  }

                  final post = _posts[postIndex];

                  return _PostCard(
                    post: post,
                    onOpen: () => _openPost(post),
                    onAuthorTap: () => _openProfile(post),
                    onLike: () => _toggleLike(post),
                    onReply: () => _openPost(post),
                    onDelete: post.canDelete ? () => _deletePost(post) : null,
                  );
                }, childCount: _renderedChildCount.clamp(0, _maxChildCount())),
              ),
            ),
        ],
      ),
    );
  }

  static int _maxChildCountFor(List<PulsePost> posts) {
    if (posts.isEmpty) {
      return 0;
    }

    return (posts.length * 2) - 1;
  }

  static String _readError(DioException exception, String fallback) {
    final data = exception.response?.data;

    if (data is Map) {
      final json = Map<String, dynamic>.from(data);
      final message = json['error'] ?? json['message'];

      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    return fallback;
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.onOpen,
    required this.onAuthorTap,
    required this.onLike,
    required this.onReply,
    this.onDelete,
  });

  final PulsePost post;
  final VoidCallback onOpen;
  final VoidCallback onAuthorTap;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onAuthorTap,
                child: CircleAvatar(
                  radius: 22,
                  backgroundImage: post.author.avatarUrl == null
                      ? null
                      : NetworkImage(post.author.avatarUrl!),
                  child: post.author.avatarUrl == null
                      ? Text(
                          post.author.displayName.substring(0, 1).toUpperCase(),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: InkWell(
                            onTap: onAuthorTap,
                            child: Wrap(
                              spacing: 6,
                              children: <Widget>[
                                Text(
                                  post.author.displayName,
                                  style: theme.textTheme.titleMedium,
                                ),
                                Text(
                                  '@${post.author.username}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (onDelete != null)
                          IconButton(
                            tooltip: 'Gönderiyi sil',
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(post.content, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        _ActionButton(
                          tooltip: 'Yanıtla',
                          icon: Icons.chat_bubble_outline,
                          label: post.replyCount.toString(),
                          onPressed: onReply,
                        ),
                        const SizedBox(width: 12),
                        _ActionButton(
                          tooltip: post.isLiked ? 'Beğeniyi kaldır' : 'Beğen',
                          icon: post.isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          label: post.likeCount.toString(),
                          selected: post.isLiked,
                          onPressed: onLike,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.tooltip,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final String tooltip;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.tertiary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onPressed,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
