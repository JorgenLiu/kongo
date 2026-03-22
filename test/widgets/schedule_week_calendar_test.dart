import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(find.textContaining('个日程'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}