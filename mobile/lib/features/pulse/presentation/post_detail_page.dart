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

  late PulsePost _post;
  bool _isSubmitting = false;
  bool _replyCreated = false;
  bool _changed = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
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

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _changed = true;
        });
      }
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await widget.onUnauthorized();
        return;
      }

      if (mounted) {
        setState(() {
          _post = previous;
          _isSubmitting = false;
          _errorMessage = _readError(error, 'Beğeni güncellenemedi.');
        });
      }
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
      await ref
          .read(pulseRepositoryProvider)
          .createReply(
            postId: _post.id,
            request: CreateReplyRequest(content: _replyController.text),
          );

      if (!mounted) {
        return;
      }

      _replyController.clear();

      setState(() {
        _post = _post.copyWith(replyCount: _post.replyCount + 1);
        _replyCreated = true;
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

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = _readError(error, 'Yanıt gönderilemedi.');
        });
      }
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

      if (mounted) {
        setState(() {
          _errorMessage = _readError(error, 'Gönderi silinemedi.');
        });
      }
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
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage:
                                      _post.author.avatarUrl == null
                                      ? null
                                      : NetworkImage(_post.author.avatarUrl!),
                                  child: _post.author.avatarUrl == null
                                      ? Text(
                                          _post.author.displayName
                                              .substring(0, 1)
                                              .toUpperCase(),
                                        )
                                      : null,
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
                                Text('${_post.likeCount} beğeni'),
                                const SizedBox(width: 16),
                                const Icon(Icons.chat_bubble_outline, size: 20),
                                const SizedBox(width: 6),
                                Text('${_post.replyCount} yanıt'),
                              ],
                            ),
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
                          if (_errorMessage != null) ...<Widget>[
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
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
                if (!_replyCreated)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz yanıt yok',
                              style: theme.textTheme.titleLarge,
                            ),
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
