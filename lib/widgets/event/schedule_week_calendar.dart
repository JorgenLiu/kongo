import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/calendar_time_node.dart';
import '../../services/read/event_read_service.dart';
import '../../utils/display_formatters.dart';
import 'calendar_time_node_presentation.dart';

class ScheduleWeekCalendar extends StatelessWidget {
  final List<EventListItemReadModel> items;
  final List<CalendarTimeNodeReadModel> calendarTimeNodes;
  final DateTime? selectedDate;
  final DateTime? referenceDate;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<EventListItemReadModel>? onItemTap;

  const ScheduleWeekCalendar({
    super.key,
    required this.items,
    this.calendarTimeNodes = const [],
    required this.selectedDate,
    this.referenceDate,
    required this.onDateSelected,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final days = _buildWeekDays();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppBreakpoints.weekCalendarScroll) {
          return SizedBox(
            height: AppDimensions.weekCalendarScrollHeight,
            child: ListView.separated(
              key: const Key('scheduleWeekCalendar'),
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final day = days[index];
                return SizedBox(
                  width: AppDimensions.weekDayCardWidth,
                  child: _WeekDayCard(
                    date: day,
                    items: _itemsForDate(day),
                    calendarTimeNodes: _nodesForDate(day),
                    selected: _isSameDate(day, selectedDate),
                    today: _isSameDate(day, referenceDate ?? DateTime.now()),
                    onDateSelected: () => onDateSelected(day),
                    onItemTap: onItemTap,
                  ),
                );
              },
            ),
          );
        }

        return Row(
          key: const Key('scheduleWeekCalendar'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < days.length; index++) ...[
              Expanded(
                child: _WeekDayCard(
                  date: days[index],
                  items: _itemsForDate(days[index]),
                  calendarTimeNodes: _nodesForDate(days[index]),
                  selected: _isSameDate(days[index], selectedDate),
                  today: _isSameDate(days[index], referenceDate ?? DateTime.now()),
                  onDateSelected: () => onDateSelected(days[index]),
                  onItemTap: onItemTap,
                ),
              ),
              if (index < days.length - 1) const SizedBox(width: AppSpacing.sm),
            ],
          ],
        );
      },
    );
  }

  List<DateTime> _buildWeekDays() {
    final now = referenceDate ?? DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - DateTime.monday));

    return List<DateTime>.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );
  }

  List<EventListItemReadModel> _itemsForDate(DateTime date) {
    final filtered = items.where((item) => _isSameDate(item.event.startAt, date)).toList()
      ..sort((left, right) {
        final leftTime = left.event.startAt?.millisecondsSinceEpoch ?? 0;
        final rightTime = right.event.startAt?.millisecondsSinceEpoch ?? 0;
        return leftTime.compareTo(rightTime);
      });
    return filtered;
  }

  List<CalendarTimeNodeReadModel> _nodesForDate(DateTime date) {
    final filtered = calendarTimeNodes.where((item) => item.occursOn(date)).toList(growable: false);
    return filtered;
  }

  bool _isSameDate(DateTime? left, DateTime? right) {
    if (left == null || right == null) {
      return false;
    }

    return left.year == right.year && left.month == right.month && left.day == right.day;
  }
}

class _WeekDayCard extends StatelessWidget {
  final DateTime date;
  final List<EventListItemReadModel> items;
  final List<CalendarTimeNodeReadModel> calendarTimeNodes;
  final bool selected;
  final bool today;
  final VoidCallback onDateSelected;
  final ValueChanged<EventListItemReadModel>? onItemTap;

  const _WeekDayCard({
    required this.date,
    required this.items,
    this.calendarTimeNodes = const [],
    required this.selected,
    required this.today,
    required this.onDateSelected,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      key: Key('scheduleWeekDay_${date.year}_${date.month}_${date.day}'),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onDateSelected,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final displayItems = _resolveDisplayItems(constraints.maxHeight);

          return ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: selected
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: selected
                        ? Border.all(
                            color: colorScheme.primary
                                .withValues(alpha: AppOpacity.medium),
                          )
                        : null,
                  ),
                  child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _weekdayLabel(date),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: today ? colorScheme.primary : colorScheme.outline,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: today || selected
                            ? colorScheme.primary.withValues(alpha: selected ? 0.18 : 0.12)
                            : colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${date.day}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: selected ? colorScheme.primary : colorScheme.onSurface,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.sm),
                if (calendarTimeNodes.isNotEmpty) ...[
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final node in calendarTimeNodes.take(2))
                        _WeekCalendarNodeChip(node: node),
                      if (calendarTimeNodes.length > 2)
                        Text(
                          '+${calendarTimeNodes.length - 2} 个节点',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: colorScheme.tertiary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (displayItems.isEmpty)
                  items.isEmpty
                      ? const SizedBox(height: 20)
                      : Text(
                          '${items.length} 个日程',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        )
                else
                  ...displayItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: _WeekScheduleSnippet(
                        item: item,
                        onTap: onItemTap == null ? null : () => onItemTap!(item),
                      ),
                    ),
                  ),
                if (items.length > displayItems.length)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: GestureDetector(
                      onTap: onDateSelected,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Text(
                          '+${items.length - displayItems.length} 个日程',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
                ),
                if (selected)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<EventListItemReadModel> _resolveDisplayItems(double maxHeight) {
    final maxPreviewCount = _resolvePreviewLimit(maxHeight);
    return items.take(maxPreviewCount).toList();
  }

  int _resolvePreviewLimit(double maxHeight) {
    if (!maxHeight.isFinite) {
      return AppDimensions.maxWeekDayEventPreview;
    }

    final reservedHeight = calendarTimeNodes.isEmpty ? 118.0 : 174.0;
    const snippetHeight = 40.0;
    const overflowHeight = 24.0;
    final availableHeight = maxHeight - reservedHeight - overflowHeight;
    final availableSlots = (availableHeight / snippetHeight).floor();
    return availableSlots.clamp(0, AppDimensions.maxWeekDayEventPreview);
  }

  String _weekdayLabel(DateTime value) {
    const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return labels[value.weekday - 1];
  }
}

class _WeekCalendarNodeChip extends StatelessWidget {
  final CalendarTimeNodeReadModel node;

  const _WeekCalendarNodeChip({required this.node});

  @override
  Widget build(BuildContext context) {
    final visualStyle = resolveCalendarTimeNodeVisualStyle(context, node.kind);
    final label = _chipLabel(node);

    return Tooltip(
      message: buildCalendarTimeNodeTooltip(node),
      waitDuration: const Duration(milliseconds: 250),
      child: Container(
        key: Key('scheduleWeekCalendar_node_${node.id}'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: visualStyle.backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: visualStyle.foregroundColor,
              ),
            ),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: visualStyle.foregroundColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _chipLabel(CalendarTimeNodeReadModel node) {
    return switch (node.kind) {
      CalendarTimeNodeKind.contactMilestone =>
        node.subtitle != null && node.subtitle!.trim().isNotEmpty
            ? '${node.subtitle!} · ${node.title}'
            : node.title,
      CalendarTimeNodeKind.publicHoliday ||
      CalendarTimeNodeKind.marketingCampaign =>
        node.title,
    };
  }
}

class _WeekScheduleSnippet extends StatelessWidget {
  final EventListItemReadModel item;
  final VoidCallback? onTap;

  const _WeekScheduleSnippet({
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final startAt = item.event.startAt;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (startAt != null)
                Text(
                  formatDateTimeLabel(startAt).split(' ').last,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              Tooltip(
                message: item.event.title,
                waitDuration: const Duration(milliseconds: 300),
                child: Text(
                  item.event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}