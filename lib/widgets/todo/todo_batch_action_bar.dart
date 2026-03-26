import 'package:flutter/material.dart';

import '../../config/app_constants.dart';

class TodoBatchActionBar extends StatelessWidget {
  final int selectedCount;
  final int totalCount;
  final VoidCallback onSelectAll;
  final VoidCallback onMarkCompleted;
  final VoidCallback onMarkPending;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  const TodoBatchActionBar({
    super.key,
    required this.selectedCount,
    required this.totalCount,
    required this.onSelectAll,
    required this.onMarkCompleted,
    required this.onMarkPending,
    required this.onDelete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '已选 $selectedCount / $totalCount',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          OutlinedButton.icon(
            onPressed: selectedCount == totalCount ? null : onSelectAll,
            icon: const Icon(Icons.select_all_rounded, size: 18),
            label: const Text('全选'),
          ),
          OutlinedButton.icon(
            onPressed: selectedCount == 0 ? null : onMarkCompleted,
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: const Text('批量完成'),
          ),
          OutlinedButton.icon(
            onPressed: selectedCount == 0 ? null : onMarkPending,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('恢复待处理'),
          ),
          OutlinedButton.icon(
            onPressed: selectedCount == 0 ? null : onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('批量删除'),
          ),
          TextButton(
            onPressed: onCancel,
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}