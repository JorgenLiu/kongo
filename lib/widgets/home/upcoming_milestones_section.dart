import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/contact_upcoming_milestone.dart';
import '../../utils/display_formatters.dart';
import 'home_dashboard_section_card.dart';

/// 近期里程碑卡片。
class UpcomingMilestonesSection extends StatelessWidget {
  final List<ContactUpcomingMilestone> milestones;
  final ValueChanged<String> onContactTap;

  const UpcomingMilestonesSection({
    super.key,
    required this.milestones,
    required this.onContactTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final visible = milestones.take(3).toList(growable: false);

    return HomeDashboardSectionCard(
      icon: Icons.cake_outlined,
      title: '近期里程碑',
      minHeight: visible.isEmpty ? null : 200,
      child: visible.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(Icons.cake_outlined, size: 18, color: colorScheme.outlineVariant),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '未来 30 天内暂无重要日期',
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: visible
                  .map(
                    (item) => _MilestoneRow(
                      item: item,
                      onTap: () => onContactTap(item.contact.id),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final ContactUpcomingMilestone item;
  final VoidCallback onTap;

  const _MilestoneRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final countdownLabel = _buildCountdown(item.daysUntil);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
          children: [
            Text(item.milestone.type.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.contact.name} · ${item.milestone.displayName}',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${formatDateTimeLabel(item.nextOccurrence).split(' ').first} · $countdownLabel',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  String _buildCountdown(int daysUntil) {
    if (daysUntil <= 0) return '今天';
    if (daysUntil == 1) return '明天';
    return '还有 $daysUntil 天';
  }
}
