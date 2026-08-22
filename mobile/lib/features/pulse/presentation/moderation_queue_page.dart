import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/safety_moderation_api.dart';
import '../domain/moderation_models.dart';

class ModerationQueuePage extends ConsumerStatefulWidget {
  const ModerationQueuePage({super.key, this.onUnauthorized});

  final VoidCallback? onUnauthorized;

  @override
  ConsumerState<ModerationQueuePage> createState() =>
      _ModerationQueuePageState();
}

class _ModerationQueuePageState extends ConsumerState<ModerationQueuePage> {
  List<ReportRecord> _reports = const <ReportRecord>[];
  bool _isLoading = true;
  int? _errorStatus;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorStatus = null;
    });

    try {
      final reports = await ref
          .read(safetyModerationApiProvider)
          .getModerationReports();

      if (!mounted) {
        return;
      }

      setState(() {
        _reports = reports
            .where((report) => report.status == ModerationStatus.pending)
            .toList(growable: false);
        _isLoading = false;
      });
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      final statusCode = error.response?.statusCode;

      if (statusCode == 401) {
        widget.onUnauthorized?.call();
        return;
      }

      setState(() {
        _errorStatus = statusCode;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorStatus = 500;
        _isLoading = false;
      });
    }
  }

  Future<void> _openReport(ReportRecord report) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) {
          return ModerationReportPage(
            reportId: report.id,
            onUnauthorized: widget.onUnauthorized,
          );
        },
      ),
    );

    if (changed == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moderasyon')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorStatus == 403)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ModerationStatePanel(
                    icon: Icons.lock_outline,
                    title: 'Bu alan yalnızca moderatörler için',
                  ),
                )
              else if (_errorStatus != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ModerationStatePanel(
                    icon: Icons.error_outline,
                    title: 'Şikâyetler yüklenemedi',
                    actionLabel: 'Tekrar Dene',
                    onAction: _load,
                  ),
                )
              else if (_reports.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ModerationStatePanel(
                    icon: Icons.inbox_outlined,
                    title: 'Bekleyen şikâyet yok',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final report = _reports[index];

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == _reports.length - 1 ? 0 : 12,
                        ),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _openReport(report),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '#${report.id} · '
                                    '${report.targetType.label}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    report.reason.label,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  if (report.reporterUsername != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '@${report.reporterUsername}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                  if (report.details?.trim().isNotEmpty ??
                                      false) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      report.details!.trim(),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }, childCount: _reports.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModerationReportPage extends ConsumerStatefulWidget {
  const ModerationReportPage({
    super.key,
    required this.reportId,
    this.onUnauthorized,
  });

  final int reportId;
  final VoidCallback? onUnauthorized;

  @override
  ConsumerState<ModerationReportPage> createState() =>
      _ModerationReportPageState();
}

class _ModerationReportPageState extends ConsumerState<ModerationReportPage> {
  ReportRecord? _report;
  bool _isLoading = true;
  bool _isSubmitting = false;
  int? _errorStatus;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorStatus = null;
    });

    try {
      final report = await ref
          .read(safetyModerationApiProvider)
          .getModerationReport(widget.reportId);

      if (!mounted) {
        return;
      }

      setState(() {
        _report = report;
        _isLoading = false;
      });
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      final statusCode = error.response?.statusCode;

      if (statusCode == 401) {
        widget.onUnauthorized?.call();
        return;
      }

      setState(() {
        _errorStatus = statusCode;
        _isLoading = false;
      });
    }
  }

  Future<String?> _askNote(String title) async {
    final controller = TextEditingController();

    try {
      return await showDialog<String?>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Not',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(controller.text.trim());
                },
                child: const Text('Devam Et'),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _resolve(ModerationAction action) async {
    if (_isSubmitting) {
      return;
    }

    final note = await _askNote(action.label);

    if (!mounted || note == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(safetyModerationApiProvider)
          .resolveReport(
            widget.reportId,
            ResolveReportRequest(action: action, note: note),
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
        widget.onUnauthorized?.call();
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Moderasyon işlemi tamamlanamadı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _dismiss() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(safetyModerationApiProvider)
          .dismissReport(widget.reportId);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.response?.statusCode == 401) {
        widget.onUnauthorized?.call();
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Moderasyon işlemi tamamlanamadı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;

    return Scaffold(
      appBar: AppBar(title: Text('Şikâyet #${widget.reportId}')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorStatus == 404
            ? const _ModerationStatePanel(
                icon: Icons.inbox_outlined,
                title: 'Şikâyet bulunamadı',
              )
            : _errorStatus == 403
            ? const _ModerationStatePanel(
                icon: Icons.lock_outline,
                title: 'Bu alan yalnızca moderatörler için',
              )
            : _errorStatus != null || report == null
            ? _ModerationStatePanel(
                icon: Icons.error_outline,
                title: 'Şikâyet yüklenemedi',
                actionLabel: 'Tekrar Dene',
                onAction: _load,
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  report.reason.label,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${report.targetType.label} '
                                  '#${report.targetId}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Durum: '
                                  '${report.status.label}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (report.details?.trim().isNotEmpty ??
                                    false) ...[
                                  const SizedBox(height: 16),
                                  Text(report.details!.trim()),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (report.status == ModerationStatus.pending) ...[
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => _resolve(ModerationAction.noAction),
                            child: const Text('İşlem Yok'),
                          ),
                          if (report.targetType == ReportTargetType.post) ...[
                            const SizedBox(height: 8),
                            FilledButton.tonal(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => _resolve(ModerationAction.removePost),
                              child: const Text('Gönderiyi Kaldır'),
                            ),
                          ],
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: _isSubmitting ? null : _dismiss,
                            child: const Text('Şikâyeti Reddet'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ModerationStatePanel extends StatelessWidget {
  const _ModerationStatePanel({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
