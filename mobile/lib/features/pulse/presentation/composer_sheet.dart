import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pulse_repository.dart';
import '../domain/pulse_models.dart';

class ComposerSheet extends ConsumerStatefulWidget {
  const ComposerSheet({required this.onUnauthorized, super.key});

  final Future<void> Function() onUnauthorized;

  @override
  ConsumerState<ComposerSheet> createState() => _ComposerSheetState();
}

class _ComposerSheetState extends ConsumerState<ComposerSheet> {
  static const int _maxLength = 280;

  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _focusNode = FocusNode();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_rebuild);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _contentController
      ..removeListener(_rebuild)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _rebuild() {
    setState(() {});
  }

  Future<void> _submit() async {
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
          .createPost(CreatePostRequest(content: _contentController.text));

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await widget.onUnauthorized();

        if (mounted) {
          Navigator.of(context).pop(false);
        }
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _errorMessage = _readError(error, 'Gönderi paylaşılamadı.');
      });
    } on FormatException {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Sunucu yanıtı okunamadı.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = _maxLength - _contentController.text.characters.length;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        top: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, minHeight: 144),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Gönderi Oluştur',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Kapat',
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contentController,
                  focusNode: _focusNode,
                  enabled: !_isSubmitting,
                  minLines: 5,
                  maxLines: 8,
                  maxLength: _maxLength,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Neler oluyor?',
                    counterText: '',
                  ),
                  validator: (value) {
                    final content = value?.trim() ?? '';

                    if (content.isEmpty) {
                      return 'Gönderi metnini yazın.';
                    }

                    if (content.characters.length > _maxLength) {
                      return 'Gönderi en fazla 280 karakter olabilir.';
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
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '$remaining karakter kaldı',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: remaining < 0
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined),
                      label: const Text('Paylaş'),
                    ),
                  ],
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
