import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/attachment.dart';
import '../../providers/files_provider.dart';
import '../../utils/contact_action_helpers.dart';

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