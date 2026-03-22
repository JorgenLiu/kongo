import 'package:flutter/material.dart';

import '../models/event.dart';

Future<bool> showDeleteEventConfirmDialog(
  BuildContext context, {
  required Event event,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('删除事件'),
      content: Text('确定要删除 ${event.title} 吗？该操作不可撤销。'),
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