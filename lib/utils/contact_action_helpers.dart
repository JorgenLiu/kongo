import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../models/contact.dart';
import '../providers/provider_error.dart';

Future<bool> showDeleteContactConfirmDialog(
  BuildContext context, {
  required Contact contact,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('删除联系人'),
      content: Text('确定要删除 ${contact.name} 吗？该操作不可撤销。'),
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

void showProviderResultSnackBar(
  BuildContext context, {
  required ProviderError? error,
  required String successMessage,
  VoidCallback? onErrorHandled,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(error?.message ?? successMessage),
      backgroundColor: error == null ? null : AppColors.error,
    ),
  );

  if (error != null) {
    onErrorHandled?.call();
  }
}