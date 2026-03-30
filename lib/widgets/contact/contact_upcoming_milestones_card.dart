import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/contact.dart';
import '../../models/contact_upcoming_milestone.dart';
import '../../utils/display_formatters.dart';
import '../common/section_card.dart';

class ContactUpcomingMilestonesCard extends StatefulWidget {
  final List<ContactUpcomingMilestone> items;
  final ValueChanged<Contact> onContactTap;

  const ContactUpcomingMilestonesCard({
    super.key,
    required this.items,
    required this.onContactTap,
  });

  @override
  State<ContactUpcomingMilestonesCard> createState() =>
      _ContactUpcomingMilestonesCardState();
}

class _ContactUpcomingMilestonesCardState
    extends State<ContactUpcomingMilestonesCard> {
  static const int _collapsedCount = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hasMore = widget.items.length > _collapsedCount;
    final visibleItems = _expanded
        ? widget.items
        : widget.items.take(_collapsedCount).toList(growable: false);

    return SectionCard(
      icon: Icons.celebration_outlined,
      title: '即将到来的重要日期',
      child: widget.items.isEmpty
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
                    onTap: () => widget.onContactTap(visibleItems[index].contact),
                  ),
                  if (index < visibleItems.length - 1)
                    const Divider(height: AppSpacing.sm),
                ],
                if (hasMore) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _expanded = !_expanded),
                      child: Text(
                        _expanded
                            ? '收起'
                            : '展开全部（${widget.items.length} 条）',
                      ),
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