import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/models/calendar_time_node.dart';
import 'package:kongo/models/event.dart';
import 'package:kongo/services/read/event_read_service.dart';
import 'package:kongo/widgets/event/schedule_week_calendar.dart';

void main() {
  final referenceDate = DateTime(2026, 3, 16, 9);

  EventListItemReadModel buildItem(int index) {
    return EventListItemReadModel(
      event: Event(
        id: 'event-$index',
        title: '同日安排 $index',
        startAt: DateTime(2026, 3, 16, 9 + index),
        createdAt: referenceDate,
        updatedAt: referenceDate,
      ),
      eventTypeName: null,
      participantNames: const [],
    );
  }

  testWidgets('Schedule week calendar does not overflow when a day contains many events', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 760,
            child: ScheduleWeekCalendar(
              items: List<EventListItemReadModel>.generate(6, buildItem),
              calendarTimeNodes: [
                CalendarTimeNodeReadModel(
                  id: 'milestone-zhangsan',
                  kind: CalendarTimeNodeKind.contactMilestone,
                  title: '生日',
                  subtitle: '张三',
                  leadingText: '🎂',
                  anchorDate: DateTime(2020, 3, 16),
                  linkedContactId: 'contact-1',
                  isRecurring: true,
                  isLunar: false,
                ),
              ],
              selectedDate: referenceDate,
              referenceDate: referenceDate,
              onDateSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('scheduleWeekCalendar')), findsOneWidget);
    expect(find.text('张三 · 生日'), findsOneWidget);
    expect(find.textContaining('个日程'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Schedule week calendar prioritizes node title for public holidays and campaigns', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 760,
            child: ScheduleWeekCalendar(
              items: const [],
              calendarTimeNodes: [
                CalendarTimeNodeReadModel(
                  id: 'holiday-1',
                  kind: CalendarTimeNodeKind.publicHoliday,
                  title: '劳动节',
                  subtitle: '公共纪念日',
                  leadingText: '🛠️',
                  anchorDate: DateTime(2026, 3, 16),
                  linkedContactId: null,
                  isRecurring: false,
                  isLunar: false,
                ),
              ],
              selectedDate: referenceDate,
              referenceDate: referenceDate,
              onDateSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('劳动节'), findsOneWidget);
    expect(find.textContaining('公共纪念日'), findsNothing);
  });
}