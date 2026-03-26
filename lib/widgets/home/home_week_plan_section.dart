import 'package:flutter/material.dart';

import '../../models/calendar_time_node.dart';
import '../../services/read/event_read_service.dart';
import '../event/schedule_week_calendar.dart';
import 'home_dashboard_section_card.dart';

class HomeWeekPlanSection extends StatelessWidget {
  final List<EventListItemReadModel> items;
  final List<CalendarTimeNodeReadModel> calendarTimeNodes;
  final VoidCallback onViewAll;
  final ValueChanged<DateTime> onDateTap;
  final ValueChanged<String> onEventTap;

  const HomeWeekPlanSection({
    super.key,
    required this.items,
    this.calendarTimeNodes = const [],
    required this.onViewAll,
    required this.onDateTap,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final referenceDate = DateTime.now();

    return HomeDashboardSectionCard(
      icon: Icons.view_week_outlined,
      title: '本周概况',
      subtitle: items.isEmpty ? '快速浏览这周的安排密度与重要节点。' : null,
      trailing: TextButton(
        onPressed: onViewAll,
        child: const Text('查看日程'),
      ),
      minHeight: 360,
      child: ScheduleWeekCalendar(
        items: items,
        calendarTimeNodes: calendarTimeNodes,
        selectedDate: referenceDate,
        referenceDate: referenceDate,
        onDateSelected: onDateTap,
        onItemTap: (item) => onEventTap(item.event.id),
      ),
    );
  }
}