import 'package:flutter/material.dart';

import '../models/event.dart';
import '../widgets/common/confirm_dialog.dart';

Future<bool> showDeleteEventConfirmDialog(
  BuildContext context, {
  required Event event,
}) {
  return showConfirmDialog(
    context,
    title: '删除事件',
    content: '确定要删除 ${event.title} 吗？该操作不可撤销。',
    confirmLabel: '删除',
  );
}