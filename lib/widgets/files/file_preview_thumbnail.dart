import 'dart:io';

import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/attachment.dart';

class FilePreviewThumbnail extends StatelessWidget {
  final Attachment attachment;
  final double width;
  final double height;

  const FilePreviewThumbnail({
    super.key,
    required this.attachment,
    this.width = AppDimensions.fileIconWidth,
    this.height = AppDimensions.fileIconHeight,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final snapshotPath = attachment.snapshotPath;
    final hasSnapshot = snapshotPath != null && snapshotPath.isNotEmpty;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasSnapshot)
            Image.file(
              File(snapshotPath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _PreviewFallback(attachment: attachment),
            )
          else
            _PreviewFallback(attachment: attachment),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
              color: colorScheme.surface.withValues(alpha: 0.78),
              child: Text(
                _resolveFooterLabel(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _resolveFooterLabel() {
    final extension = attachment.normalizedExtension;
    if (attachment.isPdfFile) {
      return 'PDF';
    }
    if (extension.isNotEmpty) {
      return extension.replaceFirst('.', '').toUpperCase();
    }
    return 'FILE';
  }
}

class _PreviewFallback extends StatelessWidget {
  final Attachment attachment;

  const _PreviewFallback({required this.attachment});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconData = switch (attachment.previewStatus) {
      AttachmentPreviewStatus.pending => Icons.hourglass_top_rounded,
      AttachmentPreviewStatus.failed => Icons.broken_image_outlined,
      AttachmentPreviewStatus.ready => attachment.isPdfFile ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
      AttachmentPreviewStatus.none => attachment.isPdfFile ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
    };
    final label = switch (attachment.previewStatus) {
      AttachmentPreviewStatus.pending => '生成中',
      AttachmentPreviewStatus.failed => '失败',
      AttachmentPreviewStatus.ready => '预览',
      AttachmentPreviewStatus.none => attachment.supportsPreview ? '待生成' : '文件',
    };

    return ColoredBox(
      color: colorScheme.primaryContainer,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, size: 22, color: colorScheme.onPrimaryContainer),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}