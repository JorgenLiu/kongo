import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/attachment.dart';
import '../../providers/files_provider.dart';
import '../../utils/attachment_action_helpers.dart';
import '../../utils/contact_action_helpers.dart';
import '../../widgets/files/file_preview_dialog.dart';

Future<void> openFileFromLibrary(BuildContext context, Attachment attachment) async {
  final provider = context.read<FilesProvider>();
  await provider.openFile(attachment);
  if (!context.mounted) {
    return;
  }

  showProviderResultSnackBar(
    context,
    error: provider.error,
    successMessage: '文件已打开',
    onErrorHandled: provider.clearError,
  );
}

Future<void> revealFileFromLibrary(BuildContext context, Attachment attachment) async {
  final provider = context.read<FilesProvider>();
  await provider.revealFile(attachment);
  if (!context.mounted) {
    return;
  }

  showProviderResultSnackBar(
    context,
    error: provider.error,
    successMessage: '已显示文件所在位置',
    onErrorHandled: provider.clearError,
  );
}

Future<void> relinkFileFromLibrary(BuildContext context, Attachment attachment) async {
  final sourcePath = await pickAttachmentSourcePath();
  if (sourcePath == null || !context.mounted) {
    return;
  }

  final provider = context.read<FilesProvider>();
  await provider.relinkFile(attachment, sourcePath);
  if (!context.mounted) {
    return;
  }

  showProviderResultSnackBar(
    context,
    error: provider.error,
    successMessage: '原文件位置已更新',
    onErrorHandled: provider.clearError,
  );
}

Future<void> convertFileToManagedFromLibrary(BuildContext context, Attachment attachment) async {
  final provider = context.read<FilesProvider>();
  await provider.convertToManaged(attachment);
  if (!context.mounted) {
    return;
  }

  showProviderResultSnackBar(
    context,
    error: provider.error,
    successMessage: '附件已转为托管模式',
    onErrorHandled: provider.clearError,
  );
}

Future<void> deleteFileFromLibrary(BuildContext context, Attachment attachment) async {
  final provider = context.read<FilesProvider>();
  final linkCount = provider.linkCountFor(attachment.id);
  if (linkCount > 0) {
    await showAttachmentDeleteBlockedDialog(
      context,
      attachment: attachment,
      linkCount: linkCount,
    );
    return;
  }

  final confirmed = await showLibraryDeleteAttachmentConfirmDialog(
    context,
    attachment: attachment,
  );
  if (!confirmed || !context.mounted) {
    return;
  }

  await provider.deleteFile(attachment);
  if (!context.mounted) {
    return;
  }

  showProviderResultSnackBar(
    context,
    error: provider.error,
    successMessage: '附件已删除',
    onErrorHandled: provider.clearError,
  );
}

Future<void> openFilePreviewFromLibrary(BuildContext context, Attachment attachment) async {
  await showFilePreviewDialog(
    context,
    attachmentId: attachment.id,
    onOpenFile: () => openFileFromLibrary(context, attachment),
    onRevealFile: () => revealFileFromLibrary(context, attachment),
    onRefreshPreview: () async {
      final provider = context.read<FilesProvider>();
      await provider.refreshPreview(attachment.id, force: true);
      if (!context.mounted) {
        return;
      }

      if (provider.error != null) {
        showProviderResultSnackBar(
          context,
          error: provider.error,
          successMessage: '预览已刷新',
          onErrorHandled: provider.clearError,
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('预览已刷新')),
      );
    },
  );
}

Future<void> deleteSelectedFilesFromLibrary(BuildContext context) async {
  final provider = context.read<FilesProvider>();
  if (provider.selectedCount == 0) {
    return;
  }

  if (provider.selectedLinkedCount > 0) {
    await showLibraryDeleteSelectedBlockedDialog(
      context,
      blockedCount: provider.selectedLinkedCount,
    );
    return;
  }

  final confirmed = await showLibraryDeleteSelectedAttachmentsConfirmDialog(
    context,
    attachmentCount: provider.selectedCount,
  );
  if (!confirmed || !context.mounted) {
    return;
  }

  final deletedCount = await provider.deleteSelectedFiles();
  if (!context.mounted) {
    return;
  }

  showProviderResultSnackBar(
    context,
    error: provider.error,
    successMessage: '已删除 $deletedCount 个附件',
    onErrorHandled: provider.clearError,
  );
}

Future<void> cleanupOrphanFilesFromLibrary(BuildContext context) async {
  final provider = context.read<FilesProvider>();
  final orphanFileCount = provider.orphanFileCount;
  if (orphanFileCount == 0) {
    return;
  }

  final confirmed = await showCleanupOrphanFilesConfirmDialog(
    context,
    orphanFileCount: orphanFileCount,
  );
  if (!confirmed || !context.mounted) {
    return;
  }

  final deletedCount = await provider.cleanupOrphanFiles();
  if (!context.mounted) {
    return;
  }

  showProviderResultSnackBar(
    context,
    error: provider.error,
    successMessage: '已清理 $deletedCount 个孤立附件',
    onErrorHandled: provider.clearError,
  );
}