import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/home_daily_brief.dart';
import 'ai_daily_brief_card.dart';

class HomeDailyBriefExpandableItem extends StatelessWidget {
  final HomeDailyBriefItem item;
  final bool expanded;
  final VoidCallback onToggle;
  final HomeDailyBriefActionHandler? onActionTap;

  const HomeDailyBriefExpandableItem({
    super.key,
    required this.item,
    required this.expanded,
    required this.onToggle,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: expanded
            ? colorScheme.surface.withValues(alpha: 0.22)
            : colorScheme.surface.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          InkWell(
            key: Key('aiDailyBriefToggle_${item.title}'),
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Text(
                      _itemTypeLabel(item.type),
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      item.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  Icon(
                    expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.78),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                key: Key('aiDailyBriefExpanded_${item.title}'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.reason,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.86),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      FilledButton.tonal(
                        key: Key('aiDailyBriefPrimaryAction_${item.title}'),
                        onPressed: () => onActionTap?.call(
                          item.primaryAction,
                          item.primaryTargetId,
                        ),
                        child: Text(_actionLabel(item.primaryAction)),
                      ),
                      if (item.secondaryAction != null)
                        OutlinedButton(
                          key: Key('aiDailyBriefSecondaryAction_${item.title}'),
                          onPressed: () => onActionTap?.call(
                            item.secondaryAction!,
                            item.secondaryTargetId,
                          ),
                          child: Text(_actionLabel(item.secondaryAction!)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _itemTypeLabel(HomeDailyBriefItemType type) {
    switch (type) {
      case HomeDailyBriefItemType.followUp:
        return '待跟进';
      case HomeDailyBriefItemType.milestone:
        return '重要节点';
      case HomeDailyBriefItemType.pendingAction:
        return '待处理';
      case HomeDailyBriefItemType.scheduleFocus:
        return '日程重点';
    }
  }

  String _actionLabel(HomeDailyBriefActionType action) {
    switch (action) {
      case HomeDailyBriefActionType.openContact:
        return '查看联系人';
      case HomeDailyBriefActionType.openEvent:
        return '查看事件';
      case HomeDailyBriefActionType.openTodos:
        return '查看待办';
      case HomeDailyBriefActionType.openEventsToday:
        return '查看今日日程';
      case HomeDailyBriefActionType.openSummaries:
        return '查看总结';
      case HomeDailyBriefActionType.createFollowUpEvent:
        return '新建跟进事件';
    }
  }
}