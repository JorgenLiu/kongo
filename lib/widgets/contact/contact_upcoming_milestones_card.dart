import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/contact.dart';
import '../../models/contact_upcoming_milestone.dart';
import '../../utils/display_formatters.dart';
import '../common/section_card.dart';

class ContactUpcomingMilestonesCard extends StatelessWidget {
  final List<ContactUpcomingMilestone> items;
  final ValueChanged<Contact> onContactTap;

  const ContactUpcomingMilestonesCard({
    super.key,
    required this.items,
    required this.onContactTap,
  });

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(5).toList(growable: false);

    return SectionCard(
      icon: Icons.celebration_outlined,
      title: '即将到来的重要日期',
      child: items.isEmpty
          ? Text(
              '未来 30 天内暂无重要日期。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < visibleItems.length; index++) ...[
                  _UpcomingMilestoneRow(
                    item: visibleItems[index],
                    onTap: () => onContactTap(visibleItems[index].contact),
                  ),
                  if (index < visibleItems.length - 1)
                    const Divider(height: AppSpacing.sm),
                ],
                if (items.length > visibleItems.length) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '还有 ${items.length - visibleItems.length} 条重要日期未展开显示。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _UpcomingMilestoneRow extends StatelessWidget {
  final ContactUpcomingMilestone item;
  final VoidCallback onTap;

  const _UpcomingMilestoneRow({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: AppSpacing.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.milestone.type.icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.contact.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${item.milestone.displayName} · ${formatDateTimeLabel(item.nextOccurrence).split(' ').first} · ${_buildCountdownLabel(item.daysUntil)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            if (item.milestone.reminderEnabled)
              Icon(
                Icons.notifications_active_outlined,
                size: 18,
                color: colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  String _buildCountdownLabel(int daysUntil) {
    if (daysUntil <= 0) {
      return '今天';
    }
    if (daysUntil == 1) {
      return '明天';
    }
    return '还有 $daysUntil 天';
  }
}