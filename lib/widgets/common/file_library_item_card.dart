import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/attachment.dart';
import '../../utils/display_formatters.dart';

class FileLibraryItemCard extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const FileLibraryItemCard({
    super.key,
    required this.attachment,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final extensionLabel = _resolveExtensionLabel();
    final previewText = attachment.previewText?.trim();
    final secondaryName = attachment.originalFileName?.trim();

    return Card(
      child: GestureDetector(
        onSecondaryTapDown: onDelete != null
            ? (details) => _showContextMenu(context, details.globalPosition)
            : null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          hoverColor: colorScheme.primary.withValues(alpha: AppOpacity.subtle),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                  ),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.insert_drive_file_outlined,
                      size: 20,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      extensionLabel,
                      style: TextStyle(
                        fontSize: AppFontSize.labelSmall,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
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
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _MetaPill(
                          icon: Icons.data_object_outlined,
                          label: formatFileSizeLabel(attachment.sizeBytes),
                        ),
                        _MetaPill(
                          icon: Icons.schedule_outlined,
                          label: formatDateTimeLabel(attachment.updatedAt),
                        ),
                        if (attachment.mimeType != null && attachment.mimeType!.isNotEmpty)
                          _MetaPill(
                            icon: Icons.category_outlined,
                            label: attachment.mimeType!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.open_in_new_outlined,
                color: colorScheme.outline,
              ),
            ],
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
          value: 'open',
          child: Row(
            children: [
              Icon(Icons.open_in_new_outlined, size: 18, color: colorScheme.onSurface),
              const SizedBox(width: AppSpacing.sm),
              const Text('打开'),
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
      if (value == 'open') onTap?.call();
      if (value == 'delete') onDelete?.call();
    });
  }

  String _resolveExtensionLabel() {
    final rawExtension = attachment.extension?.trim();
    if (rawExtension != null && rawExtension.isNotEmpty) {
      return rawExtension.replaceFirst('.', '').toUpperCase();
    }

    final segments = attachment.fileName.split('.');
    if (segments.length > 1) {
      final suffix = segments.last.trim();
      if (suffix.isNotEmpty) {
        return suffix.toUpperCase();
      }
    }

    return 'FILE';
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({
    required this.icon,
    required this.label,
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
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: colorScheme.outline,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}