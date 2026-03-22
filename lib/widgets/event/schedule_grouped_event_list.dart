import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../services/read/event_read_service.dart';
import '../../widgets/common/empty_state.dart';
import 'event_list_item_card.dart';

class ScheduleGroupedEventList extends StatelessWidget {
  final List<EventListItemReadModel> items;
  final DateTime? selectedDate;
  final DateTime? referenceDate;
  final ValueChanged<EventListItemReadModel> onItemTap;

  const ScheduleGroupedEventList({
    super.key,
    required this.items,
    required this.selectedDate,
    this.referenceDate,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections();
    if (sections.isEmpty) {
      return EmptyState(
        icon: Icons.event_busy_outlined,
        message: selectedDate == null ? '本周暂无可展示的日程' : '所选日期没有日程',
        asCard: true,
      );
    }

    return Column(
      children: sections
          .map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _ScheduleSection(
                title: section.title,
                count: section.items.length,
                items: section.items,
                onItemTap: onItemTap,
              ),
            ),
          )
          .toList(),
    );
  }

  List<_ScheduleSectionModel> _buildSections() {
    if (selectedDate != null) {
      final filteredItems = items
          .where((item) => _isSameDate(item.event.startAt, selectedDate))
          .toList()
        ..sort(_sortByStartAtAscending);

      if (filteredItems.isEmpty) {
        return const [];
      }

      return [
        _ScheduleSectionModel(
          title: _formatDateTitle(selectedDate!),
          items: filteredItems,
        ),
      ];
    }

    final now = referenceDate ?? DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - DateTime.monday));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day + 1);

    final weeklyItems = items.where((item) {
      final startAt = item.event.startAt;
      if (startAt == null) {
        return false;
      }

      return !startAt.isBefore(weekStart) && startAt.isBefore(weekEnd);
    }).toList();

    final todayItems = weeklyItems.where((item) => _isSameDate(item.event.startAt, now)).toList()
      ..sort(_sortByStartAtAscending);

    final upcomingItems = weeklyItems
        .where(
          (item) =>
              item.event.startAt != null &&
              !item.event.startAt!.isBefore(endOfToday) &&
              !_isSameDate(item.event.startAt, now),
        )
        .toList()
      ..sort(_sortByStartAtAscending);

    final earlierItems = weeklyItems
        .where(
          (item) =>
              item.event.startAt != null &&
              item.event.startAt!.isBefore(startOfToday) &&
              !_isSameDate(item.event.startAt, now),
        )
        .toList()
      ..sort(_sortByStartAtDescending);

    final sections = <_ScheduleSectionModel>[];
    if (todayItems.isNotEmpty) {
      sections.add(_ScheduleSectionModel(title: '今日日程', items: todayItems));
    }
    if (upcomingItems.isNotEmpty) {
      sections.add(_ScheduleSectionModel(title: '本周后续', items: upcomingItems));
    }
    if (earlierItems.isNotEmpty) {
      sections.add(_ScheduleSectionModel(title: '本周较早', items: earlierItems));
    }

    return sections;
  }

  int _sortByStartAtAscending(EventListItemReadModel left, EventListItemReadModel right) {
    final leftTime = left.event.startAt?.millisecondsSinceEpoch ?? 0;
    final rightTime = right.event.startAt?.millisecondsSinceEpoch ?? 0;
    return leftTime.compareTo(rightTime);
  }

  int _sortByStartAtDescending(EventListItemReadModel left, EventListItemReadModel right) {
    final leftTime = left.event.startAt?.millisecondsSinceEpoch ?? 0;
    final rightTime = right.event.startAt?.millisecondsSinceEpoch ?? 0;
    return rightTime.compareTo(leftTime);
  }

  bool _isSameDate(DateTime? left, DateTime? right) {
    if (left == null || right == null) {
      return false;
    }

    return left.year == right.year && left.month == right.month && left.day == right.day;
  }

  String _formatDateTitle(DateTime value) {
    return '${value.month} 月 ${value.day} 日';
  }
}

class _ScheduleSection extends StatelessWidget {
  final String title;
  final int count;
  final List<EventListItemReadModel> items;
  final ValueChanged<EventListItemReadModel> onItemTap;

  const _ScheduleSection({
    required this.title,
    required this.count,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '$count 项',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: EventListItemCard(
              event: item.event,
              eventTypeName: item.eventTypeName,
              participantNames: item.participantNames,
              onTap: () => onItemTap(item),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduleSectionModel {
  final String title;
  final List<EventListItemReadModel> items;

  const _ScheduleSectionModel({
    required this.title,
    required this.items,
  });
}