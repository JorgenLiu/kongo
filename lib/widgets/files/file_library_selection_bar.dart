import 'package:flutter/material.dart';

import '../../config/app_constants.dart';

class FileLibrarySelectionBar extends StatelessWidget {
  final int selectedCount;
  final int selectedLinkedCount;
  final bool allVisibleSelected;
  final VoidCallback onToggleSelectAllVisible;
  final VoidCallback onDeleteSelected;
  final VoidCallback onCancelSelection;

  const FileLibrarySelectionBar({
    super.key,
    required this.selectedCount,
    required this.selectedLinkedCount,
    required this.allVisibleSelected,
    required this.onToggleSelectAllVisible,
    required this.onDeleteSelected,
    required this.onCancelSelection,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final deleteEnabled = selectedCount > 0 && selectedLinkedCount == 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: Card(
        color: colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '已选择 $selectedCount 项',
                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (selectedLinkedCount > 0) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '其中 $selectedLinkedCount 项仍有关联，当前不能批量删除。',
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
                      ),
                    ],
                  ],
                ),
              ),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton(
                    onPressed: onToggleSelectAllVisible,
                    child: Text(allVisibleSelected ? '取消全选当前结果' : '全选当前结果'),
                  ),
                  OutlinedButton(
                    onPressed: onCancelSelection,
                    child: const Text('退出多选'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: deleteEnabled ? onDeleteSelected : null,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('批量删除'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}