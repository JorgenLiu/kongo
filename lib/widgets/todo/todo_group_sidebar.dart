import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../services/read/todo_read_service.dart';

class TodoGroupSidebar extends StatelessWidget {
  final List<TodoGroupListItemReadModel> groups;
  final String? selectedGroupId;
  final VoidCallback onCreateGroup;
  final ValueChanged<String> onSelectGroup;
  final void Function(TodoGroupListItemReadModel item) onEditGroup;
  final void Function(TodoGroupListItemReadModel item) onArchiveGroup;
  final void Function(TodoGroupListItemReadModel item) onDeleteGroup;

  const TodoGroupSidebar({
    super.key,
    required this.groups,
    required this.selectedGroupId,
    required this.onCreateGroup,
    required this.onSelectGroup,
    required this.onEditGroup,
    required this.onArchiveGroup,
    required this.onDeleteGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '待办组',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onCreateGroup,
                  icon: const Icon(Icons.add_rounded),
                  tooltip: '新建待办组',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: groups.isEmpty
                  ? Center(
                      child: Text(
                        '暂无待办组',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      itemCount: groups.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final item = groups[index];
                        final selected = item.group.id == selectedGroupId;
                        final colorScheme = Theme.of(context).colorScheme;
                        return Material(
                          color: selected
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            onTap: () => onSelectGroup(item.group.id),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.group.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          '${item.completedItems}/${item.totalItems} 已完成',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: colorScheme.outline,
                                              ),
                                        ),
                                        if (item.totalItems > 0) ...[
                                          const SizedBox(height: AppSpacing.xs),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(2),
                                            child: LinearProgressIndicator(
                                              value: item.completedItems / item.totalItems,
                                              minHeight: 4,
                                              backgroundColor: colorScheme.surfaceContainerHighest,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                item.completedItems == item.totalItems
                                                    ? const Color(0xFF4F7A54)
                                                    : colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (item.group.archivedAt != null) ...[
                                          const SizedBox(height: AppSpacing.xs),
                                          Text(
                                            '已归档',
                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                  color: colorScheme.primary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        onEditGroup(item);
                                      } else if (value == 'archive') {
                                        onArchiveGroup(item);
                                      } else {
                                        onDeleteGroup(item);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'edit', child: Text('编辑')),
                                      PopupMenuItem(
                                        value: 'archive',
                                        child: Text(item.group.archivedAt == null ? '归档' : '取消归档'),
                                      ),
                                      const PopupMenuItem(value: 'delete', child: Text('删除')),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}