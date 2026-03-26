import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/contact_milestone.dart';
import '../../utils/display_formatters.dart';
import '../common/section_card.dart';

class ContactDetailMilestonesSection extends StatelessWidget {
  final List<ContactMilestone> milestones;
  final VoidCallback onAdd;
  final ValueChanged<ContactMilestone> onEdit;
  final ValueChanged<ContactMilestone> onDelete;

  const ContactDetailMilestonesSection({
    super.key,
    required this.milestones,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SectionCard(
      icon: Icons.cake_outlined,
      title: '重要日期',
      collapsible: true,
      initiallyExpanded: false,
      trailing: IconButton(
        icon: const Icon(Icons.add),
        tooltip: '添加重要日期',
        onPressed: onAdd,
      ),
      child: milestones.isEmpty
          ? Text(
              '暂无重要日期，可以添加生日、纪念日等重要日期。',
              style: TextStyle(color: colorScheme.outline),
            )
          : Column(
              children: milestones
                  .map(
                    (milestone) => _MilestoneRow(
                      milestone: milestone,
                      onEdit: () => onEdit(milestone),
                      onDelete: () => onDelete(milestone),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final ContactMilestone milestone;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MilestoneRow({
    required this.milestone,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateLabel = _formatMilestoneDate(milestone.milestoneDate);
    final daysInfo = _getDaysInfo(milestone);

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Text(
              milestone.type.icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    milestone.displayName,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        dateLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      if (daysInfo != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          daysInfo,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (milestone.reminderEnabled)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: Icon(
                  Icons.notifications_active_outlined,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
              tooltip: '删除',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  String _formatMilestoneDate(DateTime date) {
    return formatDateTimeLabel(date).split(' ').first;
  }

  String? _getDaysInfo(ContactMilestone milestone) {
    if (!milestone.isRecurring) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisYear = DateTime(now.year, milestone.milestoneDate.month, milestone.milestoneDate.day);

    DateTime nextOccurrence;
    if (thisYear.isAfter(today) || thisYear.isAtSameMomentAs(today)) {
      nextOccurrence = thisYear;
    } else {
      nextOccurrence = DateTime(now.year + 1, milestone.milestoneDate.month, milestone.milestoneDate.day);
    }

    final daysUntil = nextOccurrence.difference(today).inDays;

    if (daysUntil == 0) return '今天';
    if (daysUntil == 1) return '明天';
    if (daysUntil <= 30) return '还有 $daysUntil 天';
    return null;
  }
}
