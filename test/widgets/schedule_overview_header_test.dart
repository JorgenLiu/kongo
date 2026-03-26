import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/models/event.dart';
import 'package:kongo/services/read/event_read_service.dart';
import 'package:kongo/widgets/event/schedule_overview_header.dart';

void main() {
  final referenceDate = DateTime(2026, 3, 18, 9, 30);

  EventListItemReadModel buildItem({
    required String id,
    required String title,
    required DateTime startAt,
  }) {
    return EventListItemReadModel(
      event: Event(
        id: id,
        title: title,
        startAt: startAt,
        createdAt: referenceDate,
        updatedAt: referenceDate,
      ),
      eventTypeName: null,
      participantNames: const [],
    );
  }

  testWidgets('Schedule overview header defaults to week view and switches to month view', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleOverviewHeader(
            items: [
              buildItem(
                id: 'monday',
                title: '周一例会',
                startAt: DateTime(2026, 3, 16, 10),
              ),
              buildItem(
                id: 'wednesday',
                title: '周三跟进',
                startAt: DateTime(2026, 3, 18, 14),
              ),
            ],
            calendarTimeNodes: const [],
            calendarMode: ScheduleCalendarMode.week,
            selectedDate: referenceDate,
            referenceDate: referenceDate,
            onDateSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('scheduleWeekCalendar')), findsOneWidget);
    expect(find.text('周一例会'), findsOneWidget);
    expect(find.text('周三跟进'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleOverviewHeader(
            items: [
              buildItem(
                id: 'monday',
                title: '周一例会',
                startAt: DateTime(2026, 3, 16, 10),
              ),
              buildItem(
                id: 'wednesday',
                title: '周三跟进',
                startAt: DateTime(2026, 3, 18, 14),
              ),
            ],
            calendarTimeNodes: const [],
            calendarMode: ScheduleCalendarMode.month,
            selectedDate: referenceDate,
            referenceDate: referenceDate,
            onDateSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('eventsMonthlyCalendar')), findsOneWidget);
  });

  testWidgets('Schedule overview header keeps month calendar stable in short viewports', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(820, 720)),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 520,
              child: ScheduleOverviewHeader(
                items: List<EventListItemReadModel>.generate(
                  8,
                  (index) => buildItem(
                    id: 'month-$index',
                    title: '月历安排 $index',
                    startAt: DateTime(2026, 3, index + 1, 10),
                  ),
                ),
                calendarTimeNodes: const [],
                calendarMode: ScheduleCalendarMode.month,
                selectedDate: referenceDate,
                referenceDate: referenceDate,
                onDateSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('eventsMonthlyCalendar')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Schedule overview header renders month calendar at half width on desktop', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleOverviewHeader(
            items: List<EventListItemReadModel>.generate(
              8,
              (index) => buildItem(
                id: 'desktop-month-$index',
                title: '桌面月历安排 $index',
                startAt: DateTime(2026, 3, index + 1, 10),
              ),
            ),
            calendarTimeNodes: const [],
            calendarMode: ScheduleCalendarMode.month,
            selectedDate: referenceDate,
            referenceDate: referenceDate,
            onDateSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('eventsMonthlyCalendar')), findsOneWidget);
    final monthCalendarWidth = tester.getSize(find.byKey(const Key('eventsMonthlyCalendar'))).width;

    expect(
      monthCalendarWidth,
      lessThan(720),
    );
  });

  testWidgets('Schedule overview header forwards date selection', (
    WidgetTester tester,
  ) async {
    DateTime? selectedDate = referenceDate;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: ScheduleOverviewHeader(
              items: [
                buildItem(
                  id: 'thursday',
                  title: '周四拜访',
                  startAt: DateTime(2026, 3, 19, 10),
                ),
              ],
              calendarTimeNodes: const [],
              calendarMode: ScheduleCalendarMode.week,
              selectedDate: selectedDate,
              referenceDate: referenceDate,
              onDateSelected: (value) {
                setState(() {
                  selectedDate = value;
                });
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('scheduleWeekDay_2026_3_19')));
    await tester.pumpAndSettle();

    expect(selectedDate, DateTime(2026, 3, 19));
  });
}