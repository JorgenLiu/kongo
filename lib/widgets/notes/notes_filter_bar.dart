import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../services/read/notes_read_service.dart';

/// 笔记页顶部的筛选条：filter 激活时展示联系人 chip + 清除按钮，
/// filter 未激活时隐藏（不占空间）。
class NotesFilterBar extends StatelessWidget {
  final NotesFilter filter;
  final VoidCallback onClear;

  const NotesFilterBar({
    super.key,
    required this.filter,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (!filter.isActive) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final label = filter.contactName != null
        ? '联系人：${filter.contactName}'
        : '联系人筛选';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: [
          Chip(
            label: Text(label),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: onClear,
            backgroundColor: colorScheme.secondaryContainer,
            labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
            deleteIconColor: colorScheme.onSecondaryContainer,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          ),
        ],
      ),
    );
  }
}
