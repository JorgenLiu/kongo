import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/attachment.dart';
import '../../utils/display_formatters.dart';
import '../files/file_preview_thumbnail.dart';

class FileLibraryItemCard extends StatelessWidget {
  final Attachment attachment;
  final int linkCount;
  final VoidCallback? onTap;
  final VoidCallback? onPreview;
  final VoidCallback? onDelete;
  final VoidCallback? onReveal;
  final VoidCallback? onRelink;
  final VoidCallback? onConvertToManaged;
  final bool selectionMode;
  final bool selected;
  final ValueChanged<bool>? onSelectedChanged;

  const FileLibraryItemCard({
    super.key,
    required this.attachment,
    required this.linkCount,
    this.onTap,
    this.onPreview,
    this.onDelete,
    this.onReveal,
    this.onRelink,
    this.onConvertToManaged,
    this.selectionMode = false,
    this.selected = false,
    this.onSelectedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final previewText = attachment.previewText?.trim();
    final secondaryName = attachment.originalFileName?.trim();
    final sourcePath = attachment.sourcePath?.trim();
    final storageModeLabel = _resolveStorageModeLabel();
    final sourceStatusLabel = _resolveSourceStatusLabel();
    final sourceStatusColor = _resolveSourceStatusColor(colorScheme);
    final previewStatusLabel = _resolvePreviewStatusLabel();
    final hasContextMenuActions =
        onDelete != null || onReveal != null || onRelink != null || onConvertToManaged != null;

    return Semantics(
      label: '文件 ${attachment.fileName}，$storageModeLabel，${formatFileSizeLabel(attachment.sizeBytes)}',
      button: true,
      selected: selected,
      child: Card(
        child: GestureDetector(
          onSecondaryTapDown: hasContextMenuActions
              ? (details) => _showContextMenu(context, details.globalPosition)
              : null,
          child: InkWell(
            onTap: selectionMode ? () => onSelectedChanged?.call(!selected) : onTap,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            hoverColor: colorScheme.primary.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectionMode) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Checkbox(
                        value: selected,
                        onChanged: (value) => onSelectedChanged?.call(value ?? false),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  GestureDetector(
                    onTap: onPreview,
                    child: FilePreviewThumbnail(attachment: attachment),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                      attachment.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (secondaryName != null && secondaryName.isNotEmpty && secondaryName != attachment.fileName) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        secondaryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                    if (sourcePath != null && sourcePath.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        sourcePath,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                    if (previewText != null && previewText.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        previewText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    // 状态行：存储模式 + 来源状态 + 关联数
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _MetaPill(
                          icon: attachment.storageMode == AttachmentStorageMode.managed
                              ? Icons.inventory_2_outlined
                              : Icons.link_outlined,
                          label: storageModeLabel,
                        ),
                        if (sourceStatusLabel != null)
                          _MetaPill(
                            icon: _resolveSourceStatusIcon(),
                            label: sourceStatusLabel,
                            foregroundColor: sourceStatusColor,
                            borderColor: sourceStatusColor.withValues(alpha: AppOpacity.medium),
                          ),
                        if (previewStatusLabel != null)
                          _MetaPill(
                            icon: _resolvePreviewStatusIcon(),
                            label: previewStatusLabel,
                          ),
                        _MetaPill(
                          icon: linkCount == 0 ? Icons.cleaning_services_outlined : Icons.linked_camera_outlined,
                          label: linkCount == 0 ? '孤立附件' : '关联 $linkCount 条',
                          foregroundColor: linkCount == 0 ? colorScheme.error : null,
                          borderColor: linkCount == 0 ? colorScheme.error.withValues(alpha: AppOpacity.medium) : null,
                        ),
                      ],
                    ),
                    // 信息行：文件大小 · 日期 · MIME 类型
                    const SizedBox(height: AppSpacing.xs),
                    _FileInfoLine(
                      items: [
                        formatFileSizeLabel(attachment.sizeBytes),
                        formatDateTimeLabel(attachment.updatedAt),
                        if (attachment.mimeType != null && attachment.mimeType!.isNotEmpty)
                          attachment.mimeType!,
                      ],
                    ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    children: [
                      IconButton(
                        tooltip: '预览',
                        onPressed: onPreview,
                        icon: Icon(
                          Icons.visibility_outlined,
                          color: colorScheme.outline,
                        ),
                      ),
                      if (!selectionMode)
                        Icon(
                          Icons.open_in_new_outlined,
                          color: colorScheme.outline,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final colorScheme = Theme.of(context).colorScheme;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(
          value: 'preview',
          child: Row(
            children: [
              Icon(Icons.visibility_outlined, size: 18, color: colorScheme.onSurface),
              const SizedBox(width: AppSpacing.sm),
              const Text('预览'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'open',
          child: Row(
            children: [
              Icon(Icons.open_in_new_outlined, size: 18, color: colorScheme.onSurface),
              const SizedBox(width: AppSpacing.sm),
              const Text('打开'),
            ],
          ),
        ),
        if (onReveal != null)
          PopupMenuItem(
            value: 'reveal',
            child: Row(
              children: [
                Icon(Icons.folder_open_outlined, size: 18, color: colorScheme.onSurface),
                const SizedBox(width: AppSpacing.sm),
                const Text('显示所在位置'),
              ],
            ),
          ),
        if (onRelink != null)
          PopupMenuItem(
            value: 'relink',
            child: Row(
              children: [
                Icon(Icons.link_outlined, size: 18, color: colorScheme.onSurface),
                const SizedBox(width: AppSpacing.sm),
                const Text('重新定位原文件'),
              ],
            ),
          ),
        if (onConvertToManaged != null)
          PopupMenuItem(
            value: 'convert',
            child: Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 18, color: colorScheme.onSurface),
                const SizedBox(width: AppSpacing.sm),
                const Text('转为托管附件'),
              ],
            ),
          ),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
                const SizedBox(width: AppSpacing.sm),
                Text('删除', style: TextStyle(color: colorScheme.error)),
              ],
            ),
          ),
      ],
    ).then((value) {
      if (value == 'preview') onPreview?.call();
      if (value == 'open') onTap?.call();
      if (value == 'reveal') onReveal?.call();
      if (value == 'relink') onRelink?.call();
      if (value == 'convert') onConvertToManaged?.call();
      if (value == 'delete') onDelete?.call();
    });
  }

  String _resolveStorageModeLabel() {
    switch (attachment.storageMode) {
      case AttachmentStorageMode.managed:
        return '已托管';
      case AttachmentStorageMode.linked:
        return '外部引用';
    }
  }

  String? _resolvePreviewStatusLabel() {
    if (!attachment.supportsPreview) {
      return null;
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

  IconData _resolvePreviewStatusIcon() {
    switch (attachment.previewStatus) {
      case AttachmentPreviewStatus.none:
        return attachment.isPdfFile ? Icons.picture_as_pdf_outlined : Icons.image_outlined;
      case AttachmentPreviewStatus.pending:
        return Icons.hourglass_top_rounded;
      case AttachmentPreviewStatus.ready:
        return Icons.image_search_outlined;
      case AttachmentPreviewStatus.failed:
        return Icons.broken_image_outlined;
    }
  }

  String? _resolveSourceStatusLabel() {
    if (attachment.storageMode != AttachmentStorageMode.linked) {
      return null;
    }

    switch (attachment.sourceStatus) {
      case AttachmentSourceStatus.available:
        return '原文件可用';
      case AttachmentSourceStatus.missing:
        return '原文件缺失';
      case AttachmentSourceStatus.inaccessible:
        return '访问受限';
    }
  }

  IconData _resolveSourceStatusIcon() {
    switch (attachment.sourceStatus) {
      case AttachmentSourceStatus.available:
        return Icons.check_circle_outline;
      case AttachmentSourceStatus.missing:
        return Icons.error_outline;
      case AttachmentSourceStatus.inaccessible:
        return Icons.lock_outline;
    }
  }

  Color _resolveSourceStatusColor(ColorScheme colorScheme) {
    switch (attachment.sourceStatus) {
      case AttachmentSourceStatus.available:
        return colorScheme.primary;
      case AttachmentSourceStatus.missing:
        return colorScheme.error;
      case AttachmentSourceStatus.inaccessible:
        return colorScheme.tertiary;
    }
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? foregroundColor;
  final Color? borderColor;

  const _MetaPill({
    required this.icon,
    required this.label,
    this.foregroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: AppOpacity.elevated),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: borderColor ?? colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: foregroundColor ?? colorScheme.outline,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foregroundColor ?? colorScheme.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 紧凑信息行：用中点分隔的纯文本行
class _FileInfoLine extends StatelessWidget {
  final List<String> items;

  const _FileInfoLine({required this.items});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      items.join(' · '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: colorScheme.outline,
      ),
    );
  }
}