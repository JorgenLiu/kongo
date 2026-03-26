import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/action_item.dart';
import '../common/visual_strikethrough_text.dart';
import 'home_dashboard_section_card.dart';

/// 待办事项（从最近总结提取）。
class PendingActionsSection extends StatelessWidget {
  final List<ActionItem> actions;
  final VoidCallback onViewSummaries;
  final VoidCallback onViewTodos;

  const PendingActionsSection({
    super.key,
    required this.actions,
    required this.onViewSummaries,
    required this.onViewTodos,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return HomeDashboardSectionCard(
      icon: Icons.checklist_outlined,
      title: '待办事项',
      trailing: TextButton(
        onPressed: onViewTodos,
        child: const Text('前往待办'),
      ),
      minHeight: actions.isEmpty ? null : 200,
      child: actions.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(Icons.checklist_outlined, size: 18, color: colorScheme.outlineVariant),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '暂无待处理事项',
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                    ),
                  ),
                  TextButton(
                    onPressed: onViewSummaries,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('查看总结'),
                  ),
                ],
              ),
            )
          : Column(
              children: actions.take(5).map((item) => _ActionRow(item: item)).toList(growable: false),
            ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final ActionItem item;

  const _ActionRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            item.completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: item.completed ? colorScheme.primary : colorScheme.outline,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: item.completed
                ? VisualStrikethroughText(
                    text: item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                  )
                : Text(
                    item.title,
                    style: textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }
}
