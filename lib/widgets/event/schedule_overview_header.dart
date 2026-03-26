import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/calendar_time_node.dart';
import '../../services/read/event_read_service.dart';
import 'monthly_event_calendar.dart';
import 'schedule_week_calendar.dart';

enum ScheduleCalendarMode { week, month }

class ScheduleOverviewHeader extends StatelessWidget {
  final List<EventListItemReadModel> items;
  final List<CalendarTimeNodeReadModel> calendarTimeNodes;
  final ScheduleCalendarMode calendarMode;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateSelected;
  final ValueChanged<EventListItemReadModel>? onItemTap;
  final DateTime? referenceDate;

  const ScheduleOverviewHeader({
    super.key,
    required this.items,
    this.calendarTimeNodes = const [],
    required this.calendarMode,
    required this.selectedDate,
    required this.onDateSelected,
    this.onItemTap,
    this.referenceDate,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactMonthCalendar = constraints.maxWidth < AppBreakpoints.monthCalendarCompact;
        final calendarViewport = _buildCalendarViewport(
          context,
          compactMonthCalendar,
          parentMaxWidth: constraints.maxWidth,
          parentMaxHeight: constraints.maxHeight,
        );
        final hasFiniteHeight = constraints.maxHeight.isFinite;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisSize: hasFiniteHeight ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasFiniteHeight)
                Expanded(child: calendarViewport)
              else
                calendarViewport,
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarViewport(
    BuildContext context,
    bool compactMonthCalendar, {
    required double parentMaxWidth,
    required double parentMaxHeight,
  }) {
    final calendar = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      layoutBuilder: (currentChild, _) => currentChild ?? const SizedBox.shrink(),
      child: calendarMode == ScheduleCalendarMode.week
          ? ScheduleWeekCalendar(
              key: const ValueKey('schedule-calendar-week'),
              items: items,
              calendarTimeNodes: calendarTimeNodes,
              selectedDate: selectedDate,
              referenceDate: referenceDate,
              onDateSelected: onDateSelected,
              onItemTap: onItemTap,
            )
          : MonthlyEventCalendar(
              key: const ValueKey('schedule-calendar-month'),
              events: items.map((item) => item.event).toList(),
              calendarTimeNodes: calendarTimeNodes,
              selectedDate: selectedDate,
              onDateSelected: onDateSelected,
              showFrame: false,
              compact: compactMonthCalendar,
            ),
    );

    if (calendarMode != ScheduleCalendarMode.month) {
      return calendar;
    }

    return Align(
      alignment: Alignment.topLeft,
      child: FractionallySizedBox(
        widthFactor: _resolveMonthCalendarWidthFactor(parentMaxWidth),
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: _resolveMonthCalendarHeight(
              context,
              parentMaxHeight: parentMaxHeight,
            ),
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: calendar,
          ),
        ),
      ),
    );
  }

  double _resolveMonthCalendarWidthFactor(double parentMaxWidth) {
    if (parentMaxWidth >= AppBreakpoints.desktopShell) {
      return 0.5;
    }

    return 1.0;
  }

  double _resolveMonthCalendarHeight(
    BuildContext context, {
    required double parentMaxHeight,
  }) {
    final viewportHeight = MediaQuery.sizeOf(context).height - MediaQuery.paddingOf(context).vertical;
    final preferredHeight = viewportHeight * 0.46;
    if (!parentMaxHeight.isFinite) {
      return preferredHeight.clamp(280.0, 430.0);
    }

    final availableHeight = (parentMaxHeight - 148.0).clamp(140.0, 430.0);
    return preferredHeight.clamp(140.0, availableHeight);
  }
}