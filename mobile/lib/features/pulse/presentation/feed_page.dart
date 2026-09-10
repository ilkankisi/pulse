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

  int _feedRequestGeneration = 0;

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

  int _maxChildCount() => _maxChildCountFor(_posts);

  int _maxChildCountFor(List<PulsePost> posts) {
    if (posts.isEmpty) {
      return 0;
    }

    return (posts.length * 2) - 1;
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
      final expandedChildCount = _renderedChildCount + _scrollChunk;
      _renderedChildCount = expandedChildCount > maxChildCount
          ? maxChildCount
          : expandedChildCount;
    });
  }

  Future<void> _loadFeed() async {
    final requestGeneration = ++_feedRequestGeneration;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final posts = await ref.read(pulseRepositoryProvider).getFeed();

      if (!mounted || requestGeneration != _feedRequestGeneration) {
        return;
      }

      setState(() {
        _posts = posts;
        _isLoading = false;

        final maxChildCount = _maxChildCountFor(posts);
        _renderedChildCount = maxChildCount < _initialChildCount
            ? maxChildCount
            : _initialChildCount;
      });
    } on DioException catch (error) {
      if (requestGeneration != _feedRequestGeneration) {
        return;
      }

      if (error.response?.statusCode == 401) {
        await widget.onUnauthorized();
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = _readError(error, 'Akış yüklenemedi');
      });
    } on FormatException {
      if (!mounted || requestGeneration != _feedRequestGeneration) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Akış yüklenemedi';
      });
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

      final currentIndex = _posts.indexWhere((item) => item.id == post.id);
      if (currentIndex >= 0) {
        setState(() {
          final posts = List<PulsePost>.from(_posts);
          posts[currentIndex] = post;
          _posts = posts;
        });
      }

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

        final maxChildCount = _maxChildCount();
        if (_renderedChildCount > maxChildCount) {
          _renderedChildCount = maxChildCount;
        }
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gönderi silindi.')));
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await widget.onUnauthorized();
        return;
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_readError(error, 'Gönderi silinemedi.'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akış'),

        actions: <Widget>[
          IconButton(
            tooltip: 'Yenile',

            onPressed: _isLoading ? null : _loadFeed,

            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _posts.isEmpty) {
      return _FeedMessage(
        icon: Icons.wifi_off_outlined,
        title: _errorMessage!,
        actionLabel: 'Tekrar Dene',
        onAction: _loadFeed,
      );
    }

    if (_posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadFeed,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            const SizedBox(height: 120),
            _EmptyFeed(onCreate: _openComposer),
          ],
        ),
      );
    }

    final maxChildCount = _maxChildCount();
    final childCount = _renderedChildCount > maxChildCount
        ? maxChildCount
        : _renderedChildCount;

    return RefreshIndicator(
      onRefresh: _loadFeed,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index.isOdd) {
                return const Divider(height: 1);
              }

              final postIndex = index ~/ 2;
              final post = _posts[postIndex];

              return _PostCard(
                post: post,
                isCurrentUser: post.author.id == widget.currentUser.id,
                onOpen: () => _openPost(post),
                onOpenProfile: () => _openProfile(post),
                onToggleLike: () => _toggleLike(post),
                onDelete: post.canDelete ? () => _deletePost(post) : null,
              );
            }, childCount: childCount),
          ),
        ],
      ),
    );
  }

  String _readError(DioException error, String fallback) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }

      final errorValue = data['error'];
      if (errorValue is String && errorValue.trim().isNotEmpty) {
        return errorValue;
      }

      if (errorValue is Map<String, dynamic>) {
        final nestedMessage = errorValue['message'];
        if (nestedMessage is String && nestedMessage.trim().isNotEmpty) {
          return nestedMessage;
        }
      }
    }

    return fallback;
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),

      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: <Widget>[
          const Icon(Icons.forum_outlined, size: 48),

          const SizedBox(height: 16),

          const Text(
            'Akış henüz boş',

            textAlign: TextAlign.center,

            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 8),

          const Text(
            'İlk gönderini paylaşarak konuşmayı başlat.',

            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: onCreate,

            icon: const Icon(Icons.edit_outlined),

            label: const Text('Gönderi Oluştur'),
          ),
        ],
      ),
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({
    required this.icon,

    required this.title,

    required this.actionLabel,

    required this.onAction,
  });

  final IconData icon;

  final String title;

  final String actionLabel;

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: <Widget>[
            Icon(icon, size: 48),

            const SizedBox(height: 16),

            Text(
              title,

              textAlign: TextAlign.center,

              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 16),

            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,

    required this.isCurrentUser,

    required this.onOpen,

    required this.onOpenProfile,

    required this.onToggleLike,

    required this.onDelete,
  });

  final PulsePost post;

  final bool isCurrentUser;

  final VoidCallback onOpen;

  final VoidCallback onOpenProfile;

  final VoidCallback onToggleLike;

  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              InkWell(
                customBorder: const CircleBorder(),
                onTap: onOpenProfile,
                child: _AuthorAvatar(post: post),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: InkWell(
                            onTap: onOpenProfile,
                            child: Row(
                              children: <Widget>[
                                Flexible(
                                  child: Text(
                                    post.author.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '@${post.author.username}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _relativeTime(post.createdAt),
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        if (onDelete != null || isCurrentUser)
                          PopupMenuButton<String>(
                            tooltip: 'Gönderi seçenekleri',
                            onSelected: (value) {
                              if (value == 'delete') {
                                onDelete?.call();
                              }
                            },
                            itemBuilder: (context) => <PopupMenuEntry<String>>[
                              if (onDelete != null)
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: <Widget>[
                                      Icon(Icons.delete_outline),
                                      SizedBox(width: 12),
                                      Text('Gönderiyi sil'),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                    if (post.content.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(post.content),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        _ActionButton(
                          tooltip: 'Yanıtla',
                          icon: Icons.chat_bubble_outline,
                          count: post.replyCount,
                          onPressed: onOpen,
                        ),
                        const SizedBox(width: 20),
                        _ActionButton(
                          tooltip: post.isLiked ? 'Beğeniyi kaldır' : 'Beğen',
                          icon: post.isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          count: post.likeCount,
                          onPressed: onToggleLike,
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

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({required this.post});

  final PulsePost post;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = post.author.avatarUrl;

    final displayName = post.author.displayName.trim();

    final fallback = displayName.isNotEmpty
        ? displayName.characters.first.toUpperCase()
        : post.author.username.characters.first.toUpperCase();

    return CircleAvatar(
      radius: 22,
      foregroundImage: avatarUrl == null || avatarUrl.trim().isEmpty
          ? null
          : NetworkImage(avatarUrl),
      child: Text(fallback),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.tooltip,

    required this.icon,

    required this.count,

    required this.onPressed,
  });

  final String tooltip;

  final IconData icon;

  final int count;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,

      label: tooltip,

      child: InkWell(
        borderRadius: BorderRadius.circular(20),

        onTap: onPressed,

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),

          child: Row(
            mainAxisSize: MainAxisSize.min,

            children: <Widget>[
              Icon(icon, size: 19),

              if (count > 0) ...<Widget>[
                const SizedBox(width: 5),

                Text('$count'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _relativeTime(DateTime value) {
  final now = DateTime.now();

  final localValue = value.toLocal();

  final difference = now.difference(localValue);

  if (difference.isNegative || difference.inSeconds < 60) {
    return 'şimdi';
  }

  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} dk';
  }

  if (difference.inHours < 24) {
    return '${difference.inHours} sa';
  }

  if (difference.inDays < 7) {
    return '${difference.inDays} g';
  }

  final day = localValue.day.toString().padLeft(2, '0');

  final month = localValue.month.toString().padLeft(2, '0');

  final year = localValue.year;

  if (year == now.year) {
    return '$day.$month';
  }

  return '$day.$month.$year';
}
