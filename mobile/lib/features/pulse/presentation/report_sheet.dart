import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/safety_moderation_api.dart';
import '../domain/moderation_models.dart';

class ReportSheet extends ConsumerStatefulWidget {
  const ReportSheet({
    super.key,
    required this.targetType,
    required this.targetId,
    this.onUnauthorized,
  });

  final ReportTargetType targetType;
  final int targetId;
  final VoidCallback? onUnauthorized;

  static Future<bool> show(
    BuildContext context, {
    required ReportTargetType targetType,
    required int targetId,
    VoidCallback? onUnauthorized,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) {
        return ReportSheet(
          targetType: targetType,
          targetId: targetId,
          onUnauthorized: onUnauthorized,
        );
      },
    );

    return result ?? false;
  }

  @override
  ConsumerState<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<ReportSheet> {
  final TextEditingController _detailsController = TextEditingController();

  ReportReason? _reason;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;

    if (reason == null || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(safetyModerationApiProvider)
          .createReport(
            CreateReportRequest(
              targetType: widget.targetType,
              targetId: widget.targetId,
              reason: reason,
              details: _detailsController.text,
            ),
          );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.response?.statusCode == 401) {
        Navigator.of(context).pop(false);
        widget.onUnauthorized?.call();
        return;
      }

      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Şikâyet gönderilemedi. Tekrar deneyin.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Şikâyet gönderilemedi. Tekrar deneyin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.targetType.label} şikâyet et',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Şikâyet nedenini seçin.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ReportReason>(
                  initialValue: _reason,
                  decoration: const InputDecoration(
                    labelText: 'Şikâyet nedeni',
                    border: OutlineInputBorder(),
                  ),
                  items: ReportReason.values
                      .map(
                        (reason) => DropdownMenuItem<ReportReason>(
                          value: reason,
                          child: Text(reason.label),
                        ),
                      )
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (reason) {
                          setState(() {
                            _reason = reason;
                            _errorMessage = null;
                          });
                        },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _detailsController,
                  enabled: !_isSubmitting,
                  maxLength: 500,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    hintText: 'İsterseniz ek bilgi paylaşabilirsiniz.',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _reason == null || _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Şikâyeti gönder'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
