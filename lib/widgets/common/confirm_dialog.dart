import 'package:flutter/material.dart';

/// 通用二选一确认对话框，返回用户是否确认。
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  String cancelLabel = '取消',
  String confirmLabel = '确定',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
