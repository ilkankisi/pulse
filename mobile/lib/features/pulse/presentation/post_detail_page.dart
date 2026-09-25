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
      final repliesRepository = ref.read(pulseRepositoryProvider);
      final replies = await repliesRepository.getReplies(_post.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _replies = List<PulsePost>.unmodifiable(replies);
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

      if (previous.isLiked) {
        await repository.unlikePost(previous.id);
      } else {
        await repository.likePost(previous.id);
      }

      final rawLikes = await repository.getPostLikes(previous.id);
      final refreshedLikeUsers = _PostLikeUser.fromResponse(rawLikes);

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
        request: CreateReplyRequest(content: _replyController.text.trim()),
      );

      final canonicalReplies = await repository.getReplies(_post.id);

      if (!mounted) {
        return;
      }

      _replyController.clear();

      setState(() {
        _replies = List<PulsePost>.unmodifiable(canonicalReplies);
        _isLoadingReplies = false;
        _repliesError = null;
        _isSubmitting = false;
        _changed = true;
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
    if (_isSubmitting) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Gönderiyi sil'),
          content: const Text('Bu gönderiyi silmek istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

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
        _isSubmitting = false;
        _errorMessage = _readError(error, 'Gönderi silinemedi.');
      });
    }
  }

  void _close() {
    Navigator.of(context).pop(_changed);
  }

  @override
  Widget build(BuildContext context) {
    final likeCount = _likeUsers?.length ?? _post.likeCount;

    final replyCount = _isLoadingReplies ? _post.replyCount : _replies.length;

    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _close();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _close,
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('Gönderi'),
          actions: [
            if (_post.canDelete)
              IconButton(
                onPressed: _isSubmitting ? null : _deletePost,
                tooltip: 'Gönderiyi sil',
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildPostCard(likeCount: likeCount, replyCount: replyCount),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              _buildReplyComposer(),
              const SizedBox(height: 24),
              Container(
                key: _repliesKey,
                child: Row(
                  children: [
                    Text(
                      'Yanıtlar',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$replyCount',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoadingReplies)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_repliesError != null)
                _buildRepliesError()
              else if (_replies.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Henüz yanıt yok.'),
                )
              else
                ..._replies.map(_buildReplyCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard({required int likeCount, required int replyCount}) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(
                  displayName: _post.author.displayName,
                  avatarUrl: _post.author.avatarUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _post.author.displayName,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        '@${_post.author.username}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(_post.createdAt),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(_post.content, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: _isSubmitting ? null : _toggleLike,
                  icon: Icon(
                    _post.isLiked ? Icons.favorite : Icons.favorite_border,
                  ),
                  label: Text(_post.isLiked ? 'Beğenildi' : 'Beğen'),
                ),
                TextButton(
                  onPressed: _openLikes,
                  child: Text('$likeCount beğeni'),
                ),
                TextButton.icon(
                  onPressed: () {
                    _replyFocusNode.requestFocus();
                    _scrollToReplies();
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text('$replyCount yanıt'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyComposer() {
    return Form(
      key: _formKey,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          TextFormField(
            controller: _replyController,

            focusNode: _replyFocusNode,

            maxLength: _maxLength,

            minLines: 2,

            maxLines: 5,

            decoration: const InputDecoration(
              labelText: 'Yanıt yaz',

              border: OutlineInputBorder(),
            ),

            validator: (value) {
              final content = value?.trim() ?? '';

              if (content.isEmpty) {
                return 'Yanıt boş olamaz.';
              }

              if (content.length > _maxLength) {
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
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Yanıtla'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepliesError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),

      child: Column(
        children: [
          Text(
            _repliesError!,

            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),

          const SizedBox(height: 8),

          OutlinedButton(
            onPressed: _loadReplies,

            child: const Text('Tekrar dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyCard(PulsePost reply) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(
              displayName: reply.author.displayName,
              avatarUrl: reply.author.avatarUrl,
              radius: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        reply.author.displayName,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        '@${reply.author.username}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(reply.content),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(reply.createdAt),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar({
    required String displayName,

    required String? avatarUrl,

    double radius = 22,
  }) {
    final normalizedAvatar = avatarUrl?.trim();

    return CircleAvatar(
      radius: radius,
      backgroundImage: normalizedAvatar == null || normalizedAvatar.isEmpty
          ? null
          : NetworkImage(normalizedAvatar),
      child: normalizedAvatar == null || normalizedAvatar.isEmpty
          ? Text(_initialForName(displayName))
          : null,
    );
  }

  String _initialForName(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return '?';
    }

    return normalized.substring(0, 1).toUpperCase();
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();

    final day = local.day.toString().padLeft(2, '0');

    final month = local.month.toString().padLeft(2, '0');

    final year = local.year.toString();

    final hour = local.hour.toString().padLeft(2, '0');

    final minute = local.minute.toString().padLeft(2, '0');

    return '$day.$month.$year $hour:$minute';
  }

  String _readError(DioException error, String fallback) {
    final data = error.response?.data;

    if (data is Map) {
      final json = Map<String, dynamic>.from(data);
      final message =
          json['message'] ?? json['detail'] ?? json['title'] ?? json['error'];

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
    if (mounted) {
      setState(() {
        _isLoading = true;

        _errorMessage = null;
      });
    }

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
        _errorMessage = 'Beğenenler yüklenemedi.';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Beğenenler')),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!),
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

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _users.length,
      separatorBuilder: (context, index) {
        return const Divider(height: 1);
      },
      itemBuilder: (context, index) {
        final user = _users[index];
        final avatarUrl = user.avatarUrl?.trim();

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: avatarUrl == null || avatarUrl.isEmpty
                ? null
                : NetworkImage(avatarUrl),
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Text(
                    user.displayName.trim().isEmpty
                        ? '?'
                        : user.displayName.trim().substring(0, 1).toUpperCase(),
                  )
                : null,
          ),
          title: Text(user.displayName),
          subtitle: Text('@${user.username}'),
        );
      },
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
      throw const FormatException('Beğenenler listesi okunamadı.');
    }

    return items
        .map<_PostLikeUser>((item) {
          if (item is! Map) {
            throw const FormatException('Beğenen kullanıcı okunamadı.');
          }

          final json = Map<String, dynamic>.from(item);
          final nestedUser = json['user'];

          final userJson = nestedUser is Map
              ? Map<String, dynamic>.from(nestedUser)
              : json;

          final rawUsername =
              userJson['username'] ??
              userJson['userName'] ??
              json['username'] ??
              json['userName'];

          final username = rawUsername?.toString().trim() ?? '';

          final rawDisplayName =
              userJson['displayName'] ??
              userJson['name'] ??
              json['displayName'] ??
              json['name'];

          final displayName =
              rawDisplayName?.toString().trim().isNotEmpty == true
              ? rawDisplayName.toString().trim()
              : username;

          final rawAvatar =
              userJson['avatarUrl'] ??
              userJson['avatar'] ??
              json['avatarUrl'] ??
              json['avatar'];

          if (username.isEmpty && displayName.isEmpty) {
            throw const FormatException('Beğenen kullanıcı okunamadı.');
          }

          return _PostLikeUser(
            username: username,
            displayName: displayName,
            avatarUrl: rawAvatar?.toString(),
          );
        })
        .toList(growable: false);
  }
}
