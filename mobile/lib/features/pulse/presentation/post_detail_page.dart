import 'package:dio/dio.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pulse_repository.dart';

import '../domain/pulse_models.dart';

class PostDetailPage extends ConsumerStatefulWidget {
  const PostDetailPage({
    required this.post,

    required this.onUnauthorized,

    super.key,
  });

  final PulsePost post;

  final Future<void> Function() onUnauthorized;

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  static const int _maxLength = 280;

  final _formKey = GlobalKey<FormState>();

  final _replyController = TextEditingController();

  final _replyFocusNode = FocusNode();

  final _repliesKey = GlobalKey();

  late PulsePost _post;

  List<PulsePost> _replies = const <PulsePost>[];

  List<_PostLikeUser>? _likeUsers;

  bool _isLoadingReplies = true;

  bool _isSubmitting = false;

  bool _changed = false;

  String? _errorMessage;

  String? _repliesError;

  @override
  void initState() {
    super.initState();

    _post = widget.post;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadReplies();
      }
    });
  }

  @override
  void dispose() {
    _replyController.dispose();

    _replyFocusNode.dispose();

    super.dispose();
  }

  Future<void> _loadReplies() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingReplies = true;
      _repliesError = null;
    });

    try {
      final replies = await ref
          .read(pulseRepositoryProvider)
          .getReplies(_post.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _replies = List<PulsePost>.unmodifiable(replies);
        _post = _post.copyWith(replyCount: replies.length);
        _isLoadingReplies = false;
      });
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await widget.onUnauthorized();
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingReplies = false;
        _repliesError = _readError(error, 'Yanıtlar yüklenemedi.');
      });
    } on FormatException {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingReplies = false;
        _repliesError = 'Yanıtlar yüklenemedi.';
      });
    }
  }

  Future<void> _openLikes() async {
    if (!mounted) {
      return;
    }

    final repository = ref.read(pulseRepositoryProvider);

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => _PostLikesPage(
          postId: _post.id,
          repository: repository,
          onUnauthorized: widget.onUnauthorized,
        ),
      ),
    );

    try {
      final rawLikes = await repository.getPostLikes(_post.id);
      final canonicalLikes = _PostLikeUser.fromResponse(rawLikes);

      if (!mounted) {
        return;
      }

      setState(() {
        _likeUsers = List<_PostLikeUser>.unmodifiable(canonicalLikes);
      });
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await widget.onUnauthorized();
      }
    } on FormatException {
      // Beğenenler sayfası kendi hata durumunu gösterir.
    }
  }

  Future<void> _scrollToReplies() async {
    await _loadReplies();

    if (!mounted) {
      return;
    }

    final repliesContext = _repliesKey.currentContext;

    if (repliesContext == null) {
      return;
    }

    await Scrollable.ensureVisible(
      repliesContext,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _toggleLike() async {
    if (_isSubmitting) {
      return;
    }

    final previous = _post;

    setState(() {
      _post = _post.copyWith(isLiked: !_post.isLiked);
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(pulseRepositoryProvider);

      dynamic refreshedLikePayload;

      if (previous.isLiked) {
        refreshedLikePayload = await repository.unlikePost(previous.id);
      } else {
        refreshedLikePayload = await repository.likePost(previous.id);
      }

      final refreshedLikeUsers = _PostLikeUser.fromResponse(
        refreshedLikePayload,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _likeUsers = List<_PostLikeUser>.unmodifiable(refreshedLikeUsers);
        _isSubmitting = false;
        _changed = true;
      });
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await widget.onUnauthorized();
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _post = previous;
        _isSubmitting = false;
        _errorMessage = _readError(error, 'Beğeni güncellenemedi.');
      });
    } on FormatException {
      if (!mounted) {
        return;
      }

      setState(() {
        _post = previous;
        _isSubmitting = false;
        _errorMessage = 'Beğeni güncellenemedi.';
      });
    }
  }

  Future<void> _submitReply() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(pulseRepositoryProvider);

      await repository.createReply(
        postId: _post.id,
        request: CreateReplyRequest(content: _replyController.text),
      );

      final canonicalReplies = await repository.getReplies(_post.id);

      if (!mounted) {
        return;
      }

      _replyController.clear();

      setState(() {
        _replies = List<PulsePost>.unmodifiable(canonicalReplies);
        _post = _post.copyWith(replyCount: canonicalReplies.length);
        _isLoadingReplies = false;
        _repliesError = null;
        _changed = true;
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Yanıt gönderildi.')));
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await widget.onUnauthorized();
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _errorMessage = _readError(error, 'Yanıt gönderilemedi.');
      });
    } on FormatException {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Yanıt gönderilemedi.';
      });
    }
  }

  Future<void> _deletePost() async {
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
      await ref.read(pulseRepositoryProvider).deletePost(_post.id);

      if (mounted) {
        Navigator.of(context).pop(true);
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
        _errorMessage = _readError(error, 'Gönderi silinemedi.');
      });
    }
  }

  void _close() {
    Navigator.of(context).pop(_changed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Geri',
          onPressed: _close,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Gönderi'),
        actions: <Widget>[
          if (_post.canDelete)
            IconButton(
              tooltip: 'Gönderiyi sil',
              onPressed: _isSubmitting ? null : _deletePost,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                _Avatar(
                                  displayName: _post.author.displayName,
                                  avatarUrl: _post.author.avatarUrl,
                                  radius: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        _post.author.displayName,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      Text(
                                        '@${_post.author.username}',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _post.content,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: <Widget>[
                                IconButton(
                                  tooltip: _post.isLiked
                                      ? 'Beğeniyi kaldır'
                                      : 'Beğen',
                                  onPressed: _isSubmitting ? null : _toggleLike,
                                  icon: Icon(
                                    _post.isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: _post.isLiked
                                        ? theme.colorScheme.tertiary
                                        : null,
                                  ),
                                ),
                                _CountAction(
                                  tooltip: 'Beğenenleri göster',
                                  label:
                                      '${_likeUsers?.length ?? _post.likeCount} beğeni',
                                  onTap: _openLikes,
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Yanıtları göster',
                                  onPressed: _scrollToReplies,
                                  icon: const Icon(Icons.chat_bubble_outline),
                                ),
                                _CountAction(
                                  tooltip: 'Yanıtları göster',
                                  label: '${_post.replyCount} yanıt',
                                  onTap: _scrollToReplies,
                                ),
                              ],
                            ),
                            if (_errorMessage != null) ...<Widget>[
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverToBoxAdapter(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text('Yanıtla', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _replyController,
                            focusNode: _replyFocusNode,
                            enabled: !_isSubmitting,
                            minLines: 3,
                            maxLines: 6,
                            maxLength: _maxLength,
                            decoration: const InputDecoration(
                              hintText: 'Yanıtını yaz',
                            ),
                            validator: (value) {
                              final content = value?.trim() ?? '';

                              if (content.isEmpty) {
                                return 'Yanıt metnini yazın.';
                              }

                              if (content.characters.length > _maxLength) {
                                return 'Yanıt en fazla 280 karakter olabilir.';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: _isSubmitting ? null : _submitReply,
                              icon: _isSubmitting
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.send_outlined),
                              label: const Text('Yanıtla'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  key: _repliesKey,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Text('Yanıtlar', style: theme.textTheme.titleLarge),
                  ),
                ),
                if (_isLoadingReplies)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (_repliesError != null)
                  SliverToBoxAdapter(
                    child: _CollectionState(
                      icon: Icons.wifi_off_outlined,
                      title: 'Yanıtlar yüklenemedi',
                      description: _repliesError!,
                      actionLabel: 'Tekrar Dene',
                      onAction: _loadReplies,
                    ),
                  )
                else if (_replies.isEmpty)
                  SliverToBoxAdapter(
                    child: _CollectionState(
                      icon: Icons.chat_bubble_outline,
                      title: 'Henüz yanıt yok',
                      description: 'İlk yanıtı sen yaz.',
                      actionLabel: 'Yanıtla',
                      onAction: () {
                        _replyFocusNode.requestFocus();
                      },
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: _replies.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final reply = _replies[index];

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                _Avatar(
                                  displayName: reply.author.displayName,
                                  avatarUrl: reply.author.avatarUrl,
                                  radius: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Text(
                                              reply.author.displayName,
                                              style: theme.textTheme.titleSmall,
                                            ),
                                          ),
                                          Text(
                                            '@${reply.author.username}',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(reply.content),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
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

class _CountAction extends StatelessWidget {
  const _CountAction({
    required this.tooltip,

    required this.label,

    required this.onTap,
  });

  final String tooltip;

  final String label;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,

      child: InkWell(
        borderRadius: BorderRadius.circular(22),

        onTap: onTap,

        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),

          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),

            child: Center(child: Text(label)),
          ),
        ),
      ),
    );
  }
}

class _CollectionState extends StatelessWidget {
  const _CollectionState({
    required this.icon,

    required this.title,

    required this.description,

    this.actionLabel,

    this.onAction,
  });

  final IconData icon;

  final String title;

  final String description;

  final String? actionLabel;

  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(description, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.displayName,

    required this.avatarUrl,

    required this.radius,
  });

  final String displayName;

  final String? avatarUrl;

  final double radius;

  @override
  Widget build(BuildContext context) {
    final normalizedAvatarUrl = avatarUrl?.trim();

    return CircleAvatar(
      radius: radius,
      backgroundImage:
          normalizedAvatarUrl == null || normalizedAvatarUrl.isEmpty
          ? null
          : NetworkImage(normalizedAvatarUrl),
      child: normalizedAvatarUrl == null || normalizedAvatarUrl.isEmpty
          ? Text(_initial(displayName))
          : null,
    );
  }

  static String _initial(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return '?';
    }

    return normalized.substring(0, 1).toUpperCase();
  }
}

class _PostLikesPage extends StatefulWidget {
  const _PostLikesPage({
    required this.postId,

    required this.repository,

    required this.onUnauthorized,
  });

  final int postId;

  final PulseRepository repository;

  final Future<void> Function() onUnauthorized;

  @override
  State<_PostLikesPage> createState() => _PostLikesPageState();
}

class _PostLikesPageState extends State<_PostLikesPage> {
  List<_PostLikeUser> _users = const <_PostLikeUser>[];

  bool _isLoading = true;

  String? _error;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rawLikes = await widget.repository.getPostLikes(widget.postId);
      final users = _PostLikeUser.fromResponse(rawLikes);

      if (!mounted) {
        return;
      }

      setState(() {
        _users = List<_PostLikeUser>.unmodifiable(users);
        _isLoading = false;
      });
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await widget.onUnauthorized();
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _error = _PostDetailPageState._readError(
          error,
          'Beğenenler yüklenemedi.',
        );
      });
    } on FormatException {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _error = 'Beğenenler yüklenemedi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Beğenenler')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Builder(
              builder: (context) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_error != null) {
                  return _CollectionState(
                    icon: Icons.wifi_off_outlined,
                    title: 'Beğenenler yüklenemedi',
                    description: _error!,
                    actionLabel: 'Tekrar Dene',
                    onAction: _load,
                  );
                }

                if (_users.isEmpty) {
                  return const _CollectionState(
                    icon: Icons.favorite_border,
                    title: 'Henüz beğeni yok',
                    description: 'Bu gönderiyi henüz kimse beğenmedi.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _users.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = _users[index];

                    return ListTile(
                      minVerticalPadding: 12,
                      leading: _Avatar(
                        displayName: user.displayName,
                        avatarUrl: user.avatarUrl,
                        radius: 22,
                      ),
                      title: Text(
                        user.displayName,
                        style: theme.textTheme.titleMedium,
                      ),
                      subtitle: Text('@${user.username}'),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PostLikeUser {
  const _PostLikeUser({
    required this.username,

    required this.displayName,

    required this.avatarUrl,
  });

  final String username;

  final String displayName;

  final String? avatarUrl;

  static List<_PostLikeUser> fromResponse(dynamic data) {
    dynamic items = data;

    if (data is Map) {
      final json = Map<String, dynamic>.from(data);

      items = json['items'] ?? json['users'] ?? json['likes'] ?? json['data'];
    }

    if (items is! List) {
      throw const FormatException('Beğenenler yanıtı geçerli değil.');
    }

    final users = <_PostLikeUser>[];

    for (final item in items) {
      if (item is! Map) {
        throw const FormatException('Beğenen kullanıcı geçerli değil.');
      }

      final raw = Map<String, dynamic>.from(item);
      final nestedUser = raw['user'];

      final json = nestedUser is Map
          ? Map<String, dynamic>.from(nestedUser)
          : raw;

      final usernameValue = json['username'];
      final displayNameValue =
          json['displayName'] ?? json['name'] ?? usernameValue;
      final avatarValue = json['avatarUrl'] ?? json['profileImageUrl'];

      if (usernameValue is! String ||
          usernameValue.trim().isEmpty ||
          displayNameValue is! String ||
          displayNameValue.trim().isEmpty) {
        throw const FormatException('Beğenen kullanıcı geçerli değil.');
      }

      users.add(
        _PostLikeUser(
          username: usernameValue.trim(),
          displayName: displayNameValue.trim(),
          avatarUrl: avatarValue is String && avatarValue.trim().isNotEmpty
              ? avatarValue.trim()
              : null,
        ),
      );
    }

    return List<_PostLikeUser>.unmodifiable(users);
  }
}
