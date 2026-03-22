import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../services/read/event_read_service.dart';
import '../../utils/display_formatters.dart';

class ScheduleWeekCalendar extends StatelessWidget {
  final List<EventListItemReadModel> items;
  final DateTime? selectedDate;
  final DateTime? referenceDate;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<EventListItemReadModel>? onItemTap;

  const ScheduleWeekCalendar({
    super.key,
    required this.items,
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
  final bool selected;
  final bool today;
  final VoidCallback onDateSelected;
  final ValueChanged<EventListItemReadModel>? onItemTap;

  const _WeekDayCard({
    required this.date,
    required this.items,
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

          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: selected
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: selected
                    ? colorScheme.primary.withValues(alpha: AppOpacity.medium)
                    : colorScheme.outline.withValues(alpha: 0.22),
              ),
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
                const SizedBox(height: AppSpacing.md),
                if (displayItems.isEmpty)
                  Text(
                    items.isEmpty ? '暂无日程' : '${items.length} 个日程',
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

    const reservedHeight = 118.0;
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
              Text(
                item.event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}