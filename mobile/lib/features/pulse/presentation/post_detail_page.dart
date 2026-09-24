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

    try {
      final rawLikes = await repository.getPostLikes(_post.id);
      final canonicalLikes = _PostLikeUser.fromResponse(rawLikes);

      if (!mounted) {
        return;
      }

      setState(() {
        _post = _post.copyWith(likeCount: canonicalLikes.length);
      });
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await widget.onUnauthorized();
      }
    } on FormatException {
      // Beğenenler koleksiyonu kendi hata durumunu gösterir.
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
                if (_post.canDelete)
                  IconButton(
                    tooltip: 'Gönderiyi sil',
                    onPressed: _isSubmitting ? null : _deletePost,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(_post.content, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                IconButton(
                  tooltip: _post.isLiked ? 'Beğeniyi kaldır' : 'Beğen',
                  onPressed: _isSubmitting ? null : _toggleLike,
                  icon: Icon(
                    _post.isLiked ? Icons.favorite : Icons.favorite_border,
                  ),
                ),
                TextButton(
                  onPressed: _openLikes,
                  child: Text('${_post.likeCount} beğeni'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Yanıtla',
                  onPressed: () {
                    _replyFocusNode.requestFocus();
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
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
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReplyForm(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: <Widget>[
              Text('Yanıt yaz', style: theme.textTheme.titleMedium),

              const SizedBox(height: 12),

              TextFormField(
                controller: _replyController,

                focusNode: _replyFocusNode,

                maxLength: _maxLength,

                maxLines: 4,

                minLines: 2,

                enabled: !_isSubmitting,

                decoration: const InputDecoration(
                  hintText: 'Yanıtınızı yazın',

                  border: OutlineInputBorder(),
                ),

                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return 'Yanıt boş bırakılamaz.';
                  }

                  if (text.length > _maxLength) {
                    return 'Yanıt en fazla $_maxLength karakter olabilir.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submitReply,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Yanıtla'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyCard(BuildContext context, PulsePost reply) {
    final theme = Theme.of(context);

    final avatarUrl = reply.author.avatarUrl;

    final isPostOwner = reply.author.username == _post.author.username;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
              radius: 20,
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
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        reply.author.displayName,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        '@${reply.author.username}',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (isPostOwner)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Gönderi sahibi',
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(reply.content),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReplyCollectionSlivers(BuildContext context) {
    if (_isLoadingReplies) {
      return const <Widget>[
        SliverToBoxAdapter(
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
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: <Widget>[
                Text(_repliesError!, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                OutlinedButton(
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
      return const <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('Henüz yanıt yok.')),
          ),
        ),
      ];
    }

    return <Widget>[
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return _buildReplyCard(context, _replies[index]);
        }, childCount: _replies.length),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _close,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Gönderi'),
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(child: _buildPostCard(theme)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverToBoxAdapter(child: _buildReplyForm(theme)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Container(
                key: _repliesKey,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Yanıtlar',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    Text('${_post.replyCount}'),
                  ],
                ),
              ),
            ),
          ),
          ..._buildReplyCollectionSlivers(context),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  static String _readError(DioException error, String fallback) {
    final data = error.response?.data;

    if (data is Map) {
      final json = Map<String, dynamic>.from(data);
      final message = json['message'] ?? json['detail'] ?? json['error'];

      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
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
        _errorMessage = _PostDetailPageState._readError(
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
        _errorMessage = 'Beğenenler yüklenemedi.';
      });
    }
  }

  String _initialForName(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return '?';
    }

    return normalized.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beğenenler')),

      body: Builder(
        builder: (context) {
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
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _load,
                      child: const Text('Tekrar dene'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (_users.isEmpty) {
            return const Center(child: Text('Henüz beğenen yok.'));
          }

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _users.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = _users[index];
                final avatarUrl = user.avatarUrl;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: avatarUrl == null
                        ? null
                        : NetworkImage(avatarUrl),
                    child: avatarUrl == null
                        ? Text(
                            _initialForName(user.displayName ?? user.username),
                          )
                        : null,
                  ),
                  title: Text(user.displayName ?? '@${user.username}'),
                  subtitle: Text('@${user.username}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PostLikeUser {
  const _PostLikeUser({
    required this.username,

    this.displayName,

    this.avatarUrl,
  });

  final String username;

  final String? displayName;

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
        throw const FormatException('Beğenen kullanıcı bilgisi geçerli değil.');
      }

      final source = Map<String, dynamic>.from(item);
      final nestedUser = source['user'];

      final json = nestedUser is Map
          ? Map<String, dynamic>.from(nestedUser)
          : source;

      final usernameValue =
          json['username'] ?? json['userName'] ?? json['handle'];

      if (usernameValue is! String || usernameValue.trim().isEmpty) {
        throw const FormatException('Beğenen kullanıcı adı geçerli değil.');
      }

      final displayNameValue = json['displayName'] ?? json['name'];

      final avatarValue =
          json['avatarUrl'] ?? json['profilePhotoUrl'] ?? json['photoUrl'];

      users.add(
        _PostLikeUser(
          username: usernameValue.trim(),
          displayName:
              displayNameValue is String && displayNameValue.trim().isNotEmpty
              ? displayNameValue.trim()
              : null,
          avatarUrl: avatarValue is String && avatarValue.trim().isNotEmpty
              ? avatarValue.trim()
              : null,
        ),
      );
    }

    return List<_PostLikeUser>.unmodifiable(users);
  }
}
