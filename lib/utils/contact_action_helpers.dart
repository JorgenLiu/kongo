import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../models/contact.dart';
import '../providers/provider_error.dart';
import '../widgets/common/confirm_dialog.dart';

Future<bool> showDeleteContactConfirmDialog(
  BuildContext context, {
  required Contact contact,
}) {
  return showConfirmDialog(
    context,
    title: '删除联系人',
    content: '确定要删除 ${contact.name} 吗？该操作不可撤销。',
    confirmLabel: '删除',
  );
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