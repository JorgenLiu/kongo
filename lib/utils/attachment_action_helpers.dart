import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../models/attachment.dart';

Future<String?> pickAttachmentSourcePath() async {
  final file = await openFile();
  return file?.path;
}

Future<bool> showUnlinkAttachmentConfirmDialog(
  BuildContext context, {
  required Attachment attachment,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('移除附件关联'),
      content: Text('确定要将“${attachment.fileName}”从当前记录中移除吗？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('移除'),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}

Future<bool> showDeleteAttachmentConfirmDialog(
  BuildContext context, {
  required Attachment attachment,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('删除附件'),
      content: Text('确定要删除“${attachment.fileName}”吗？这会同时删除本地文件，且不可撤销。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('删除'),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}