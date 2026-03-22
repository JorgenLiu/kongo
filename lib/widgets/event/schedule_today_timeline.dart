import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../services/read/event_read_service.dart';
import '../../utils/display_formatters.dart';
import '../common/empty_state.dart';

class ScheduleTodayTimeline extends StatefulWidget {
  final List<EventListItemReadModel> items;
  final DateTime? referenceDate;
  final ValueChanged<EventListItemReadModel> onItemTap;

  const ScheduleTodayTimeline({
    super.key,
    required this.items,
    this.referenceDate,
    required this.onItemTap,
  });

  @override
  State<ScheduleTodayTimeline> createState() => _ScheduleTodayTimelineState();
}

class _ScheduleTodayTimelineState extends State<ScheduleTodayTimeline> {
  static const double _timelineHeaderOffset = 84;
  static const double _estimatedHourExtent = 92;

  final ScrollController _scrollController = ScrollController();
  bool _alignedInitialHour = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentHour();
    });
  }

  @override
  void didUpdateWidget(covariant ScheduleTodayTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameDate(oldWidget.referenceDate, widget.referenceDate)) {
      _alignedInitialHour = false;
    }

    if (!_alignedInitialHour) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentHour();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = _todayItems();
    final itemsByHour = <int, List<EventListItemReadModel>>{};
    for (final item in today) {
      final hour = item.event.startAt?.hour;
      if (hour == null) {
        continue;
      }

      itemsByHour.putIfAbsent(hour, () => <EventListItemReadModel>[]).add(item);
    }
    final reference = widget.referenceDate ?? DateTime.now();

    return ListView.builder(
      key: const Key('scheduleTodayTimeline'),
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      itemCount: today.isEmpty ? 3 : 26,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _TimelineHeader(
            referenceDate: reference,
            itemCount: today.length,
          );
        }

        if (index == 1) {
          return const SizedBox(height: AppSpacing.md);
        }

        if (today.isEmpty) {
          return const EmptyState(
            icon: Icons.event_busy_outlined,
            message: '当日暂无日程',
            asCard: true,
          );
        }

        final hour = index - 2;
        return _TimelineHourSlot(
          hour: hour,
          items: itemsByHour[hour] ?? const <EventListItemReadModel>[],
          highlighted: hour == reference.hour,
          onItemTap: widget.onItemTap,
        );
      },
    );
  }

  List<EventListItemReadModel> _todayItems() {
    final reference = widget.referenceDate ?? DateTime.now();
    final filtered = widget.items
        .where((item) => _isSameDate(item.event.startAt, reference))
        .toList()
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

  void _scrollToCurrentHour() {
    if (!mounted || _alignedInitialHour || !_scrollController.hasClients) {
      return;
    }

    final anchorHour = _resolveAnchorHour();
    _alignedInitialHour = true;
    final targetOffset = _timelineHeaderOffset + (anchorHour * _estimatedHourExtent);
    _scrollController.jumpTo(
      targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
    );
  }

  int _resolveAnchorHour() {
    final reference = widget.referenceDate ?? DateTime.now();
    final items = _todayItems();
    final isTodayReference = _isSameDate(reference, DateTime.now());

    if (items.isNotEmpty) {
      if (isTodayReference) {
        return reference.hour > 0 ? reference.hour - 1 : 0;
      }

      final firstEventHour = items.first.event.startAt?.hour ?? 0;
      return firstEventHour > 0 ? firstEventHour - 1 : 0;
    }

    if (isTodayReference) {
      return reference.hour > 0 ? reference.hour - 1 : 0;
    }

    return 0;
  }
}

class _TimelineHeader extends StatelessWidget {
  final DateTime? referenceDate;
  final int itemCount;

  const _TimelineHeader({
    required this.referenceDate,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    final now = referenceDate ?? DateTime.now();
    final today = DateTime.now();
    final isToday =
        now.year == today.year && now.month == today.month && now.day == today.day;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? '今日日程' : '${now.month} 月 ${now.day} 日日程',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${now.month} 月 ${now.day} 日 · 共 $itemCount 项安排',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.timeline,
            color: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _TimelineHourSlot extends StatelessWidget {
  final int hour;
  final List<EventListItemReadModel> items;
  final bool highlighted;
  final ValueChanged<EventListItemReadModel> onItemTap;

  const _TimelineHourSlot({
    required this.hour,
    required this.items,
    required this.highlighted,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                key: Key('scheduleTimelineHour_${hour.toString().padLeft(2, '0')}'),
                '${hour.toString().padLeft(2, '0')}:00',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: highlighted ? colorScheme.primary : colorScheme.outline,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: highlighted ? 12 : 10,
                  height: highlighted ? 12 : 10,
                  decoration: BoxDecoration(
                    color: highlighted ? colorScheme.primary : colorScheme.outlineVariant,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 2,
                  height: items.isEmpty ? 76 : 104 + ((items.length - 1) * 74),
                  color: colorScheme.outlineVariant,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: items.isEmpty
                ? const SizedBox(height: 72)
                : Column(
                    children: items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _TimelineEventCard(
                              item: item,
                              onTap: () => onItemTap(item),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TimelineEventCard extends StatelessWidget {
  final EventListItemReadModel item;
  final VoidCallback onTap;

  const _TimelineEventCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final startAt = item.event.startAt;
    final endAt = item.event.endAt;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      startAt == null ? '待定' : formatDateTimeLabel(startAt).split(' ').last,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
              if (item.participantNames.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.participantNames.join('、'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                ),
              ],
              if (endAt != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '结束于 ${formatDateTimeLabel(endAt).split(' ').last}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}