import 'package:flutter/material.dart';

Future<bool> showDiscardChangesDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('放弃未保存内容？'),
      content: const Text('离开当前页面后，未保存的内容将会丢失。'),
      actions: [
        TextButton(
          key: const Key('discardChanges_continueEditingButton'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('继续编辑'),
        ),
        FilledButton(
          key: const Key('discardChanges_discardButton'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('不保存'),
        ),
      ],
    ),
  );

  return result ?? false;
}