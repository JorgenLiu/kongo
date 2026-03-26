import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/todo_item.dart';
import '../../services/read/todo_read_service.dart';
import '../common/visual_strikethrough_text.dart';

class RelatedTodoSection extends StatelessWidget {
  final String title;
  final String emptyMessage;
  final List<TodoLinkedItemSummaryReadModel> items;
  final VoidCallback onCreate;
  final void Function(TodoLinkedItemSummaryReadModel item) onOpenGroup;

  const RelatedTodoSection({
    super.key,
    required this.title,
    required this.emptyMessage,
    required this.items,
    required this.onCreate,
    required this.onOpenGroup,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.checklist_rtl_outlined, size: 20, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('新建关联待办'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (items.isEmpty)
              Text(
                emptyMessage,
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
              )
            else
              Column(
                children: items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: _RelatedTodoRow(
                          item: item,
                          onOpenGroup: () => onOpenGroup(item),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
          ],
        ),
      ),
    );
  }
}

class _RelatedTodoRow extends StatelessWidget {
  final TodoLinkedItemSummaryReadModel item;
  final VoidCallback onOpenGroup;

  const _RelatedTodoRow({
    required this.item,
    required this.onOpenGroup,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final completed = item.item.status == TodoItemStatus.completed;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onOpenGroup,
      child: Ink(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(
              completed ? Icons.check_circle_outline_rounded : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: completed ? colorScheme.primary : colorScheme.outline,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (completed)
                    VisualStrikethroughText(
                      text: item.item.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.outline,
                          ),
                    )
                  else
                    Text(
                      item.item.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      Text(
                        item.group.title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                      ),
                      Text(
                        '${item.contactCount} 联系人 / ${item.eventCount} 事件',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}