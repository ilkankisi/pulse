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
  }

  void _scrollToReplies() {
    final repliesContext = _repliesKey.currentContext;

    if (repliesContext == null) {
      return;
    }

    Scrollable.ensureVisible(
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
      _post = _post.copyWith(
        isLiked: !_post.isLiked,
        likeCount: _post.isLiked
            ? (_post.likeCount > 0 ? _post.likeCount - 1 : 0)
            : _post.likeCount + 1,
      );
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(pulseRepositoryProvider);

      if (previous.isLiked) {
        await repository.unlikePost(previous.id);
      } else {
        await repository.likePost(previous.id);
      }

      if (!mounted) {
        return;
      }

      setState(() {
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

      final createdReply = await repository.createReply(
        postId: _post.id,
        request: CreateReplyRequest(content: _replyController.text),
      );

      List<PulsePost>? canonicalReplies;

      try {
        canonicalReplies = await repository.getReplies(_post.id);
      } on DioException catch (error) {
        if (error.response?.statusCode == 401) {
          await widget.onUnauthorized();
          return;
        }
      } on FormatException {
        canonicalReplies = null;
      }

      if (!mounted) {
        return;
      }

      _replyController.clear();

      final nextReplies =
          canonicalReplies ?? <PulsePost>[..._replies, createdReply];

      setState(() {
        _replies = List<PulsePost>.unmodifiable(nextReplies);
        _post = _post.copyWith(replyCount: nextReplies.length);
        _repliesError = null;
        _isLoadingReplies = false;
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
        _errorMessage = 'Yanıt bilgisi okunamadı.';
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

    if (!mounted || confirmed != true) {
      return;
    }

    try {
      await ref.read(pulseRepositoryProvider).deletePost(_post.id);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
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

  String _initialForName(String displayName) {
    final normalized = displayName.trim();

    if (normalized.isEmpty) {
      return '?';
    }

    return normalized.substring(0, 1).toUpperCase();
  }

  Widget _buildPostCard(ThemeData theme) {
    final avatarUrl = _post.author.avatarUrl;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 24,
                  backgroundImage: avatarUrl == null
                      ? null
                      : NetworkImage(avatarUrl),
                  child: avatarUrl == null
                      ? Text(_initialForName(_post.author.displayName))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
            Text(_post.content, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: <Widget>[
                IconButton(
                  tooltip: _post.isLiked ? 'Beğeniyi kaldır' : 'Beğen',
                  onPressed: _isSubmitting ? null : _toggleLike,
                  icon: Icon(
                    _post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _post.isLiked ? theme.colorScheme.tertiary : null,
                  ),
                ),
                TextButton(
                  onPressed: _openLikes,
                  child: Text('${_post.likeCount} beğeni'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Yanıtlara git',
                  onPressed: _scrollToReplies,
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                ),
                TextButton(
                  onPressed: _scrollToReplies,
                  child: Text('${_post.replyCount} yanıt'),
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
    );
  }

  Widget _buildReplyForm(ThemeData theme) {
    return Form(
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

            decoration: const InputDecoration(hintText: 'Yanıtını yaz'),

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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: const Text('Yanıtla'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyCard(PulsePost reply, ThemeData theme) {
    final avatarUrl = reply.author.avatarUrl;

    final isPostOwner = reply.author.username == _post.author.username;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
              backgroundImage: avatarUrl == null
                  ? null
                  : NetworkImage(avatarUrl),
              child: avatarUrl == null
                  ? Text(_initialForName(reply.author.displayName))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        reply.author.displayName,
                        style: theme.textTheme.titleSmall,
                      ),
                      if (isPostOwner)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            child: Text(
                              'Gönderi sahibi',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${reply.author.username}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(reply.content, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReplyCollectionSlivers(ThemeData theme) {
    if (_isLoadingReplies) {
      return <Widget>[
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32),

            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ];
    }

    if (_repliesError != null) {
      return <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: <Widget>[
                Icon(
                  Icons.error_outline,
                  size: 40,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  _repliesError!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadReplies,
                  child: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (_replies.isEmpty) {
      return <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: <Widget>[
                Icon(
                  Icons.chat_bubble_outline,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text('Henüz yanıt yok', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text('İlk yanıtı sen yaz.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _replyFocusNode.requestFocus(),
                  child: const Text('Yanıtla'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: SliverList.builder(
          itemCount: _replies.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == _replies.length - 1 ? 0 : 8,
              ),
              child: _buildReplyCard(_replies[index], theme),
            );
          },
        ),
      ),
    ];
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
                  sliver: SliverToBoxAdapter(child: _buildPostCard(theme)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverToBoxAdapter(child: _buildReplyForm(theme)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  sliver: SliverToBoxAdapter(
                    key: _repliesKey,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Yanıtlar',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        if (!_isLoadingReplies && _repliesError == null)
                          Text(
                            '${_replies.length}',
                            style: theme.textTheme.titleMedium,
                          ),
                      ],
                    ),
                  ),
                ),
                ..._buildReplyCollectionSlivers(theme),
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

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _load();
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await widget.repository.getPostLikes(widget.postId);
      final users = _PostLikeUser.fromResponse(response);

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
        _errorMessage = _readError(error, 'Beğenenler yüklenemedi.');
      });
    } on FormatException {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Beğenenler yüklenemedi.';
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
            child: _buildBody(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Tekrar dene')),
            ],
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.favorite_border,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text('Henüz beğeni yok', style: theme.textTheme.titleLarge),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      separatorBuilder: (context, index) {
        return const Divider(height: 1);
      },
      itemBuilder: (context, index) {
        final user = _users[index];
        final avatarUrl = user.avatarUrl;

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl),
            child: avatarUrl == null
                ? Text(_initialForName(user.displayName))
                : null,
          ),
          title: Text(user.displayName),
          subtitle: Text('@${user.username}'),
        );
      },
    );
  }

  static String _initialForName(String displayName) {
    final normalized = displayName.trim();

    if (normalized.isEmpty) {
      return '?';
    }

    return normalized.substring(0, 1).toUpperCase();
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

class _PostLikeUser {
  const _PostLikeUser({
    required this.username,

    required this.displayName,

    this.avatarUrl,
  });

  final String username;

  final String displayName;

  final String? avatarUrl;

  static List<_PostLikeUser> fromResponse(dynamic data) {
    dynamic items = data;

    if (data is Map) {
      final json = Map<String, dynamic>.from(data);

      items =
          json['items'] ??
          json['users'] ??
          json['likes'] ??
          json['data'] ??
          json['results'];
    }

    if (items is! List) {
      throw const FormatException('Beğenenler yanıtı geçerli değil.');
    }

    final users = <_PostLikeUser>[];

    for (final item in items) {
      if (item is! Map) {
        throw const FormatException('Beğenen kullanıcı verisi geçerli değil.');
      }

      var json = Map<String, dynamic>.from(item);
      final nestedUser = json['user'];

      if (nestedUser is Map) {
        json = Map<String, dynamic>.from(nestedUser);
      }

      final usernameValue =
          json['username'] ?? json['userName'] ?? json['handle'];
      final displayNameValue = json['displayName'] ?? json['name'];
      final avatarValue =
          json['avatarUrl'] ?? json['profilePhotoUrl'] ?? json['photoUrl'];

      if (usernameValue is! String || usernameValue.trim().isEmpty) {
        throw const FormatException('Beğenen kullanıcı adı geçerli değil.');
      }

      final username = usernameValue.trim();

      final displayName =
          displayNameValue is String && displayNameValue.trim().isNotEmpty
          ? displayNameValue.trim()
          : username;

      final avatarUrl = avatarValue is String && avatarValue.trim().isNotEmpty
          ? avatarValue.trim()
          : null;

      users.add(
        _PostLikeUser(
          username: username,
          displayName: displayName,
          avatarUrl: avatarUrl,
        ),
      );
    }

    return List<_PostLikeUser>.unmodifiable(users);
  }
}
