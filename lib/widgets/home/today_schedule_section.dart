import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../services/read/home_read_service.dart';
import '../../utils/display_formatters.dart';
import '../common/empty_state.dart';
import 'home_dashboard_section_card.dart';

/// 今日日程时间线卡片。
class TodayScheduleSection extends StatelessWidget {
  final List<TodayEventItem> events;
  final VoidCallback onViewAll;
  final VoidCallback onCreateTodayEvent;
  final ValueChanged<String> onEventTap;

  const TodayScheduleSection({
    super.key,
    required this.events,
    required this.onViewAll,
    required this.onCreateTodayEvent,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return HomeDashboardSectionCard(
      icon: Icons.today_outlined,
      title: '今日日程',
      subtitle: events.isEmpty ? '先处理今天最重要的安排，再决定这一周的推进节奏。' : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onCreateTodayEvent,
            icon: const Icon(Icons.add, size: 18),
            tooltip: '新建今日日程',
            visualDensity: VisualDensity.compact,
          ),
          TextButton(
            onPressed: onViewAll,
            child: const Text('查看全部'),
          ),
        ],
      ),
      accentBorderColor: colorScheme.primary,
      minHeight: events.isEmpty ? null : 320,
      child: events.isEmpty
          ? EmptyState(
              icon: Icons.event_busy_outlined,
              iconSize: 40,
              message: '今天暂无安排',
              subtitle: '现在就添加今天的第一条日程，保持本周节奏清晰。',
              actionLabel: '新建今日日程',
              onAction: onCreateTodayEvent,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...events.take(3).map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _TodayEventRow(
                          item: item,
                          onTap: () => onEventTap(item.event.id),
                        ),
                      ),
                    ),
                if (events.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: TextButton(
                      onPressed: onViewAll,
                      child: Text('还有 ${events.length - 3} 项安排'),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _TodayEventRow extends StatelessWidget {
  final TodayEventItem item;
  final VoidCallback onTap;

  const _TodayEventRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final timeLabel = item.event.startAt != null
        ? formatTimeOnly(item.event.startAt!)
        : '--:--';

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56,
              child: Text(
                timeLabel,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Container(
              width: 3,
              height: 44,
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.event.title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.participantNames.isEmpty
                        ? '未添加参与人'
                        : item.participantNames.join('、'),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
}
