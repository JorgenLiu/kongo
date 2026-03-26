import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/calendar_time_node.dart';
import '../../services/read/event_read_service.dart';
import '../../widgets/common/workbench_page_header.dart';
import '../../widgets/event/schedule_overview_header.dart';

/// 日程列表页面顶部栏。
///
/// 全局模式下包含日历模式切换、周导航、概览日历和新建按钮。
/// 联系人范围模式下仅显示标题和新建按钮。
class ScheduleListHeaderWidget extends StatelessWidget {
  final String? contactName;
  final ScheduleCalendarMode calendarMode;
  final DateTime selectedDate;
  final List<EventListItemReadModel> items;
  final List<CalendarTimeNodeReadModel> calendarTimeNodes;
  final ValueChanged<ScheduleCalendarMode> onCalendarModeChanged;
  final ValueChanged<DateTime> onWeekNavigate;
  final ValueChanged<DateTime?> onDateSelected;
  final VoidCallback onCreateSchedule;
  final void Function(EventListItemReadModel item) onItemTap;

  const ScheduleListHeaderWidget({
    super.key,
    this.contactName,
    required this.calendarMode,
    required this.selectedDate,
    required this.items,
    this.calendarTimeNodes = const [],
    required this.onCalendarModeChanged,
    required this.onWeekNavigate,
    required this.onDateSelected,
    required this.onCreateSchedule,
    required this.onItemTap,
  });

  bool get _isScoped => contactName != null;

  @override
  Widget build(BuildContext context) {
    if (_isScoped) {
      return _buildScopedHeader(context);
    }

    return _buildGlobalHeader(context);
  }

  Widget _buildGlobalHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: WorkbenchPageHeader(
        eyebrow: 'Schedule',
        title: '日程',
        titleKey: const Key('eventsPageHeaderTitle'),
        trailing: FilledButton.icon(
          onPressed: onCreateSchedule,
          icon: const Icon(Icons.add),
          label: const Text('新建日程'),
        ),
        metadata: [
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ScheduleCalendarControls(
                  calendarMode: calendarMode,
                  selectedDate: selectedDate,
                  onCalendarModeChanged: onCalendarModeChanged,
                  onWeekNavigate: onWeekNavigate,
                ),
                const SizedBox(height: AppSpacing.sm),
                ScheduleOverviewHeader(
                  items: items,
                  calendarTimeNodes: calendarTimeNodes,
                  calendarMode: calendarMode,
                  selectedDate: selectedDate,
                  referenceDate: selectedDate,
                  onDateSelected: onDateSelected,
                  onItemTap: onItemTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopedHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: WorkbenchPageHeader(
        eyebrow: 'Schedule',
        title: '$contactName 的日程',
        titleKey: const Key('eventsPageHeaderTitle'),
        trailing: FilledButton.icon(
          onPressed: onCreateSchedule,
          icon: const Icon(Icons.add),
          label: const Text('新建日程'),
        ),
      ),
    );
  }

  static String _formatWeekRange(DateTime referenceDate) {
    final normalized = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
    final weekStart = normalized.subtract(Duration(days: referenceDate.weekday - DateTime.monday));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final startMonth = weekStart.month.toString().padLeft(2, '0');
    final startDay = weekStart.day.toString().padLeft(2, '0');
    final endMonth = weekEnd.month.toString().padLeft(2, '0');
    final endDay = weekEnd.day.toString().padLeft(2, '0');

    if (weekStart.year == weekEnd.year) {
      return '${weekStart.year}-$startMonth-$startDay ~ $endMonth-$endDay';
    }

    return '${weekStart.year}-$startMonth-$startDay ~ ${weekEnd.year}-$endMonth-$endDay';
  }
}

/// 日历模式切换与周导航控件行，显示在日历视口上方。
class _ScheduleCalendarControls extends StatelessWidget {
  final ScheduleCalendarMode calendarMode;
  final DateTime selectedDate;
  final ValueChanged<ScheduleCalendarMode> onCalendarModeChanged;
  final ValueChanged<DateTime> onWeekNavigate;

  const _ScheduleCalendarControls({
    required this.calendarMode,
    required this.selectedDate,
    required this.onCalendarModeChanged,
    required this.onWeekNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SegmentedButton<ScheduleCalendarMode>(
          key: const Key('scheduleCalendarModeToggle'),
          segments: const [
            ButtonSegment(
              value: ScheduleCalendarMode.week,
              label: Text('本周'),
              icon: Icon(Icons.view_week_outlined),
            ),
            ButtonSegment(
              value: ScheduleCalendarMode.month,
              label: Text('本月'),
              icon: Icon(Icons.calendar_month_outlined),
            ),
          ],
          selected: <ScheduleCalendarMode>{calendarMode},
          onSelectionChanged: (selection) {
            onCalendarModeChanged(selection.first);
          },
        ),
        const Spacer(),
        if (calendarMode == ScheduleCalendarMode.week) ...[
          Text(
            ScheduleListHeaderWidget._formatWeekRange(selectedDate),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: () {
              onWeekNavigate(selectedDate.subtract(const Duration(days: 7)));
            },
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
            tooltip: '上周',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: () {
              onWeekNavigate(selectedDate.add(const Duration(days: 7)));
            },
            icon: const Icon(Icons.chevron_right_rounded, size: 20),
            tooltip: '下周',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ],
    );
  }
}
