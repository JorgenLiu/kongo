import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../models/attachment.dart';
import '../../providers/files_provider.dart';
import '../../utils/display_formatters.dart';
import 'file_preview_thumbnail.dart';

Future<void> showFilePreviewDialog(
  BuildContext context, {
  required String attachmentId,
  required Future<void> Function() onOpenFile,
  required Future<void> Function() onRevealFile,
  required Future<void> Function() onRefreshPreview,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _FilePreviewDialog(
      attachmentId: attachmentId,
      onOpenFile: onOpenFile,
      onRevealFile: onRevealFile,
      onRefreshPreview: onRefreshPreview,
    ),
  );
}

class _FilePreviewDialog extends StatelessWidget {
  final String attachmentId;
  final Future<void> Function() onOpenFile;
  final Future<void> Function() onRevealFile;
  final Future<void> Function() onRefreshPreview;

  const _FilePreviewDialog({
    required this.attachmentId,
    required this.onOpenFile,
    required this.onRevealFile,
    required this.onRefreshPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FilesProvider>(
      builder: (context, provider, _) {
        final attachment = provider.fileById(attachmentId);
        if (attachment == null) {
          return AlertDialog(
            title: const Text('附件不存在'),
            content: const Text('当前附件已不存在或已被删除。'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          );
        }

        final previewText = attachment.previewText?.trim();
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860, maxHeight: 720),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              attachment.fileName,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _subtitleFor(attachment),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: '关闭',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= AppBreakpoints.compact;
                        final previewPane = _PreviewPane(
                          attachment: attachment,
                          refreshing: provider.isRefreshingPreview(attachment.id),
                        );
                        final detailsPane = _DetailsPane(
                          attachment: attachment,
                          previewText: previewText,
                        );

                        if (wide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: previewPane),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(flex: 4, child: detailsPane),
                            ],
                          );
                        }

                        return ListView(
                          children: [
                            previewPane,
                            const SizedBox(height: AppSpacing.lg),
                            detailsPane,
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    alignment: WrapAlignment.end,
                    children: [
                      if (attachment.supportsPreview)
                        OutlinedButton.icon(
                          onPressed: provider.isRefreshingPreview(attachment.id) ? null : onRefreshPreview,
                          icon: provider.isRefreshingPreview(attachment.id)
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh_rounded),
                          label: const Text('刷新预览'),
                        ),
                      OutlinedButton.icon(
                        onPressed: onRevealFile,
                        icon: const Icon(Icons.folder_open_outlined),
                        label: const Text('显示所在位置'),
                      ),
                      FilledButton.icon(
                        onPressed: onOpenFile,
                        icon: const Icon(Icons.open_in_new_outlined),
                        label: const Text('打开文件'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _subtitleFor(Attachment attachment) {
    final items = <String>[
      formatFileSizeLabel(attachment.sizeBytes),
      formatDateTimeLabel(attachment.updatedAt),
    ];
    if (attachment.mimeType != null && attachment.mimeType!.isNotEmpty) {
      items.add(attachment.mimeType!);
    }
    return items.join(' · ');
  }
}

class _PreviewPane extends StatelessWidget {
  final Attachment attachment;
  final bool refreshing;

  const _PreviewPane({
    required this.attachment,
    required this.refreshing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '预览',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                FilePreviewThumbnail(
                  attachment: attachment,
                  width: 320,
                  height: 320,
                ),
                if (refreshing)
                  Container(
                    width: 320,
                    height: 320,
                    color: colorScheme.surface.withValues(alpha: 0.55),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsPane extends StatelessWidget {
  final Attachment attachment;
  final String? previewText;

  const _DetailsPane({
    required this.attachment,
    required this.previewText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            '文件信息',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(label: '存储模式', value: attachment.storageMode == AttachmentStorageMode.managed ? '已托管' : '外部引用'),
          _InfoRow(label: '来源状态', value: _sourceStatusLabel(attachment.sourceStatus)),
          _InfoRow(label: '预览状态', value: _previewStatusLabel(attachment)),
          _InfoRow(label: '关联数量', value: '${context.read<FilesProvider>().linkCountFor(attachment.id)} 条'),
          _InfoRow(label: '更新时间', value: formatDateTimeLabel(attachment.updatedAt)),
          if (attachment.sourcePath != null && attachment.sourcePath!.isNotEmpty)
            _InfoRow(label: '原文件位置', value: attachment.sourcePath!),
          if (attachment.snapshotPath != null && attachment.snapshotPath!.isNotEmpty)
            _InfoRow(label: '预览快照', value: attachment.snapshotPath!),
          const SizedBox(height: AppSpacing.md),
          Text(
            '预览文本',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            constraints: const BoxConstraints(minHeight: 120),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              previewText == null || previewText!.isEmpty ? '当前没有可展示的预览文本。' : previewText!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: (previewText == null || previewText!.isEmpty) ? colorScheme.outline : colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _sourceStatusLabel(AttachmentSourceStatus status) {
    switch (status) {
      case AttachmentSourceStatus.available:
        return '原文件可用';
      case AttachmentSourceStatus.missing:
        return '原文件缺失';
      case AttachmentSourceStatus.inaccessible:
        return '访问受限';
    }
  }

  String _previewStatusLabel(Attachment attachment) {
    if (!attachment.supportsPreview) {
      return '当前类型不支持预览';
    }

    switch (attachment.previewStatus) {
      case AttachmentPreviewStatus.none:
        return '待生成预览';
      case AttachmentPreviewStatus.pending:
        return '预览生成中';
      case AttachmentPreviewStatus.ready:
        return '预览可用';
      case AttachmentPreviewStatus.failed:
        return '预览失败';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}