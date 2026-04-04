import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/todo_item.dart';
import '../../services/read/todo_read_service.dart';
import '../common/visual_strikethrough_text.dart';
import '../common/empty_state.dart';
import 'todo_batch_action_bar.dart';

class TodoGroupDetailPanel extends StatelessWidget {
  final TodoGroupDetailReadModel? detail;
  final bool selectionMode;
  final Set<String> selectedItemIds;
  final int visibleItemCount;
  final VoidCallback onCreateRootItem;
  final VoidCallback onStartSelection;
  final VoidCallback onClearSelection;
  final VoidCallback onSelectAll;
  final VoidCallback onBatchMarkCompleted;
  final VoidCallback onBatchMarkPending;
  final VoidCallback onBatchDelete;
  final void Function(TodoItemTreeNodeReadModel node) onEditItem;
  final void Function(TodoItemTreeNodeReadModel node) onDeleteItem;
  final void Function(TodoItemTreeNodeReadModel node, bool completed) onToggleCompleted;
  final ValueChanged<String> onToggleSelection;
  final ValueChanged<String> onOpenContact;
  final ValueChanged<String> onOpenEvent;

  const TodoGroupDetailPanel({
    super.key,
    required this.detail,
    required this.selectionMode,
    required this.selectedItemIds,
    required this.visibleItemCount,
    required this.onCreateRootItem,
    required this.onStartSelection,
    required this.onClearSelection,
    required this.onSelectAll,
    required this.onBatchMarkCompleted,
    required this.onBatchMarkPending,
    required this.onBatchDelete,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onToggleCompleted,
    required this.onToggleSelection,
    required this.onOpenContact,
    required this.onOpenEvent,
  });

  @override
  Widget build(BuildContext context) {
    if (detail == null) {
      return const EmptyState(
        icon: Icons.checklist_rtl_outlined,
        message: '还没有待办组',
        subtitle: '先创建一个待办组，再往里面添加待办项。',
        asCard: true,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    detail!.group.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${detail!.rootItems.length} 项',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
            if ((detail!.group.description ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                detail!.group.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: selectionMode ? onClearSelection : onCreateRootItem,
                  icon: Icon(selectionMode ? Icons.close_rounded : Icons.add_rounded),
                  label: Text(selectionMode ? '退出多选' : '新增待办项'),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: selectionMode ? onClearSelection : onStartSelection,
                  icon: Icon(selectionMode ? Icons.checklist_rounded : Icons.select_all_rounded),
                  label: Text(selectionMode ? '取消多选' : '批量操作'),
                ),
              ],
            ),
            if (selectionMode) ...[
              const SizedBox(height: AppSpacing.md),
              TodoBatchActionBar(
                selectedCount: selectedItemIds.length,
                totalCount: visibleItemCount,
                onSelectAll: onSelectAll,
                onMarkCompleted: onBatchMarkCompleted,
                onMarkPending: onBatchMarkPending,
                onDelete: onBatchDelete,
                onCancel: onClearSelection,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: detail!.rootItems.isEmpty
                  ? EmptyState(
                      icon: Icons.playlist_add_check_circle_outlined,
                      message: '「${detail!.group.title}」中还没有待办项',
                      subtitle: '点击上方按钮添加待办项，并关联联系人或事件。',
                      actionLabel: '新增待办项',
                      onAction: onCreateRootItem,
                      asCard: false,
                    )
                  : ListView.separated(
                      itemCount: detail!.rootItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        return _TodoItemCard(
                          node: detail!.rootItems[index],
                          onEditItem: onEditItem,
                          onDeleteItem: onDeleteItem,
                          onToggleCompleted: onToggleCompleted,
                          selectionMode: selectionMode,
                          selectedItemIds: selectedItemIds,
                          onToggleSelection: onToggleSelection,
                          onOpenContact: onOpenContact,
                          onOpenEvent: onOpenEvent,
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

class _TodoItemCard extends StatelessWidget {
  final TodoItemTreeNodeReadModel node;
  final void Function(TodoItemTreeNodeReadModel node) onEditItem;
  final void Function(TodoItemTreeNodeReadModel node) onDeleteItem;
  final void Function(TodoItemTreeNodeReadModel node, bool completed) onToggleCompleted;
  final bool selectionMode;
  final Set<String> selectedItemIds;
  final ValueChanged<String> onToggleSelection;
  final ValueChanged<String> onOpenContact;
  final ValueChanged<String> onOpenEvent;

  const _TodoItemCard({
    required this.node,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onToggleCompleted,
    required this.selectionMode,
    required this.selectedItemIds,
    required this.onToggleSelection,
    required this.onOpenContact,
    required this.onOpenEvent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final completed = node.item.status == TodoItemStatus.completed;
    final selected = selectedItemIds.contains(node.item.id);

    return Opacity(
      opacity: completed ? 0.6 : 1.0,
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: selectionMode ? () => onToggleSelection(node.item.id) : null,
        child: Container(
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primaryContainer.withValues(alpha: 0.55)
                : completed
                    ? colorScheme.surfaceContainerLow
                    : colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: selected
                ? Border.all(color: colorScheme.primary)
                : null,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: selectionMode ? selected : completed,
                    onChanged: (value) {
                      if (selectionMode) {
                        onToggleSelection(node.item.id);
                        return;
                      }
                      onToggleCompleted(node, value ?? false);
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (completed)
                          VisualStrikethroughText(
                            text: node.item.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.outline,
                                ),
                          )
                        else
                          Text(
                            node.item.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        if ((node.item.notes ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            node.item.notes!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.outline,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!selectionMode)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEditItem(node);
                            return;
                          case 'delete':
                            onDeleteItem(node);
                            return;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('编辑')),
                        PopupMenuItem(value: 'delete', child: Text('删除')),
                      ],
                    ),
                ],
              ),
              if (node.contacts.isNotEmpty || node.events.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final contact in node.contacts)
                      _ActionChip(
                        icon: Icons.person_outline_rounded,
                        label: contact.name,
                        onPressed: () => onOpenContact(contact.id),
                      ),
                    for (final event in node.events)
                      _ActionChip(
                        icon: Icons.event_outlined,
                        label: event.title,
                        onPressed: () => onOpenEvent(event.id),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 14),
      label: Text(label),
      onPressed: onPressed,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}