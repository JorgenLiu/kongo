import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../config/app_constants.dart';
import '../models/attachment.dart';
import '../services/platform_file_opener.dart';
import '../widgets/common/confirm_dialog.dart';
import 'display_formatters.dart';

Future<String?> pickAttachmentSourcePath() async {
  final file = await openFile();
  return file?.path;
}

class AttachmentImportSelection {
  final String sourcePath;
  final int sizeBytes;
  final AttachmentStorageMode preferredStorageMode;
  final AttachmentImportPolicy importPolicy;
  final bool allowLargeFile;

  const AttachmentImportSelection({
    required this.sourcePath,
    required this.sizeBytes,
    required this.preferredStorageMode,
    required this.importPolicy,
    required this.allowLargeFile,
  });
}

Future<AttachmentImportSelection?> pickAttachmentImportSelection(BuildContext context) async {
  final file = await openFile();
  if (file == null) {
    return null;
  }

  final sourceFile = File(file.path);
  final stat = await sourceFile.stat();
  final sizeBytes = stat.size;
  if (sizeBytes > AttachmentImportLimits.hardLimitBytes) {
    if (!context.mounted) {
      return null;
    }
    await _showAttachmentTooLargeDialog(context, file.name, sizeBytes);
    return null;
  }

  if (!supportsLinkedStorage()) {
    return AttachmentImportSelection(
      sourcePath: file.path,
      sizeBytes: sizeBytes,
      preferredStorageMode: AttachmentStorageMode.managed,
      importPolicy: AttachmentImportPolicy.auto,
      allowLargeFile: false,
    );
  }

  if (sizeBytes <= AttachmentImportLimits.managedCopyThresholdBytes) {
    return AttachmentImportSelection(
      sourcePath: file.path,
      sizeBytes: sizeBytes,
      preferredStorageMode: AttachmentStorageMode.managed,
      importPolicy: AttachmentImportPolicy.auto,
      allowLargeFile: false,
    );
  }

  if (!context.mounted) {
    return null;
  }

  final suggestedMode = sizeBytes > AttachmentImportLimits.linkedPreferredThresholdBytes
      ? AttachmentStorageMode.linked
      : AttachmentStorageMode.managed;
  final selectedMode = await showAttachmentImportModeDialog(
    context,
    fileName: file.name,
    sizeBytes: sizeBytes,
    suggestedMode: suggestedMode,
  );
  if (selectedMode == null) {
    return null;
  }

  return AttachmentImportSelection(
    sourcePath: file.path,
    sizeBytes: sizeBytes,
    preferredStorageMode: selectedMode,
    importPolicy: selectedMode == AttachmentStorageMode.linked
        ? AttachmentImportPolicy.forceLinked
        : AttachmentImportPolicy.forceManaged,
    allowLargeFile: sizeBytes > AttachmentImportLimits.linkedPreferredThresholdBytes,
  );
}

Future<AttachmentStorageMode?> showAttachmentImportModeDialog(
  BuildContext context, {
  required String fileName,
  required int sizeBytes,
  required AttachmentStorageMode suggestedMode,
}) {
  final sizeLabel = formatFileSizeLabel(sizeBytes);
  final suggestedText = suggestedMode == AttachmentStorageMode.linked
      ? '该文件较大，建议仅引用原文件，避免持续占用文件库空间。'
      : '该文件已超过小文件阈值，你可以选择复制到文件库或仅引用原文件。';

  return showDialog<AttachmentStorageMode>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('导入附件'),
      content: Text('“$fileName” 大小为 $sizeLabel。$suggestedText'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(AttachmentStorageMode.linked),
          child: const Text('仅引用原文件'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(AttachmentStorageMode.managed),
          child: const Text('复制到文件库'),
        ),
      ],
    ),
  );
}

Future<void> _showAttachmentTooLargeDialog(
  BuildContext context,
  String fileName,
  int sizeBytes,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('附件过大'),
      content: Text(
        '"$fileName" 大小为 ${formatFileSizeLabel(sizeBytes)}，当前单文件限制为 '
        '${formatFileSizeLabel(AttachmentImportLimits.hardLimitBytes)}。',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
}



Future<bool> showUnlinkAttachmentConfirmDialog(
  BuildContext context, {
  required Attachment attachment,
}) {
  return showConfirmDialog(
    context,
    title: '移除附件关联',
    content: '确定要将\u201c${attachment.fileName}\u201d从当前记录中移除吗？',
    confirmLabel: '移除',
  );
}

Future<bool> showDeleteAttachmentConfirmDialog(
  BuildContext context, {
  required Attachment attachment,
}) {
  return showConfirmDialog(
    context,
    title: '删除附件',
    content: '确定要删除\u201c${attachment.fileName}\u201d吗？这会同时删除本地文件，且不可撤销。',
    confirmLabel: '删除',
  );
}

Future<bool> showLibraryDeleteAttachmentConfirmDialog(
  BuildContext context, {
  required Attachment attachment,
}) {
  final content = attachment.storageMode == AttachmentStorageMode.managed
      ? '确定要删除\u201c${attachment.fileName}\u201d吗？这会删除文件库记录和托管文件，且不可撤销。'
      : '确定要删除\u201c${attachment.fileName}\u201d吗？这会删除文件库记录，但不会删除原始文件。';

  return showConfirmDialog(
    context,
    title: '删除文件库附件',
    content: content,
    confirmLabel: '删除',
  );
}

Future<bool> showLibraryDeleteSelectedAttachmentsConfirmDialog(
  BuildContext context, {
  required int attachmentCount,
}) {
  return showConfirmDialog(
    context,
    title: '批量删除附件',
    content: '确定要删除选中的 $attachmentCount 个附件吗？\n\n已托管附件会删除托管文件；外部引用附件只会删除文件库记录，不会删除原始文件。',
    confirmLabel: '批量删除',
  );
}

Future<void> showLibraryDeleteSelectedBlockedDialog(
  BuildContext context, {
  required int blockedCount,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('当前无法批量删除'),
      content: Text(
        '所选附件中有 $blockedCount 项仍然关联事件或总结。\n\n请先移除这些关联，或仅选择孤立附件再执行批量删除。',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
}

Future<void> showAttachmentDeleteBlockedDialog(
  BuildContext context, {
  required Attachment attachment,
  required int linkCount,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('暂时不能删除'),
      content: Text(
        '“${attachment.fileName}”仍关联 $linkCount 条记录。\n\n'
        '请先在对应事件或总结中移除关联，再回到文件库删除。',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
}

Future<bool> showCleanupOrphanFilesConfirmDialog(
  BuildContext context, {
  required int orphanFileCount,
}) {
  return showConfirmDialog(
    context,
    title: '清理孤立附件',
    content: '确定要清理 $orphanFileCount 个孤立附件吗？\n\n'
        '已托管附件会删除托管文件；外部引用附件只会删除文件库记录，不会删除原始文件。',
    confirmLabel: '清理',
  );
}