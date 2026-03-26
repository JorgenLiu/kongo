import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/models/event.dart';
import 'package:kongo/config/app_colors.dart';
import 'package:kongo/models/calendar_time_node.dart';
import 'package:kongo/widgets/event/monthly_event_calendar.dart';

void main() {
  testWidgets('Monthly event calendar switches month and selects date', (WidgetTester tester) async {
    final baseMonth = DateTime(2026, 12);
    final events = [
      Event(
        id: 'event-1',
        title: '年终复盘',
        startAt: DateTime(2026, 12, 3, 9),
        createdAt: DateTime(2026, 12, 1),
        updatedAt: DateTime(2026, 12, 1),
      ),
      Event(
        id: 'event-2',
        title: '预算确认',
        startAt: DateTime(2026, 12, 3, 14),
        createdAt: DateTime(2026, 12, 1),
        updatedAt: DateTime(2026, 12, 1),
      ),
      Event(
        id: 'event-3',
        title: '新年启动会',
        startAt: DateTime(2027, 1, 5, 10),
        createdAt: DateTime(2026, 12, 1),
        updatedAt: DateTime(2026, 12, 1),
      ),
    ];

    DateTime? selectedDate;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => MonthlyEventCalendar(
              events: events,
              initialMonth: baseMonth,
              selectedDate: selectedDate,
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

    expect(find.text('2026 年 12 月'), findsOneWidget);
    final decemberEventDay = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('eventsMonthlyCalendar_day_3')),
        matching: find.text('3'),
      ),
    );
    expect(decemberEventDay.style?.color, AppColors.warning);

    await tester.tap(find.byKey(const Key('eventsMonthlyCalendar_nextMonth')));
    await tester.pumpAndSettle();

    expect(find.text('2027 年 1 月'), findsOneWidget);
    final januaryEventDay = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('eventsMonthlyCalendar_day_5')),
        matching: find.text('5'),
      ),
    );
    expect(januaryEventDay.style?.color, AppColors.warning);

    await tester.tap(find.byKey(const Key('eventsMonthlyCalendar_day_5')));
    await tester.pumpAndSettle();

    expect(selectedDate, DateTime(2027, 1, 5));
    expect(find.byKey(const Key('eventsMonthlyCalendar_clearSelection')), findsOneWidget);
  });

  testWidgets('Monthly event calendar month picker supports future visible years', (WidgetTester tester) async {
    final baseMonth = DateTime(2026, 12);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MonthlyEventCalendar(
            events: const [],
            initialMonth: baseMonth,
          ),
        ),
      ),
    );

    for (var index = 0; index < 25; index++) {
      await tester.tap(find.byKey(const Key('eventsMonthlyCalendar_nextMonth')));
      await tester.pumpAndSettle();
    }

    expect(find.text('2029 年 1 月'), findsOneWidget);

    await tester.tap(find.byKey(const Key('eventsMonthlyCalendar_monthPicker')));
    await tester.pumpAndSettle();

    expect(find.text('选择年月'), findsOneWidget);
    expect(find.text('2029 年'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Monthly event calendar shows contact milestone node badge', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MonthlyEventCalendar(
            events: const [],
            initialMonth: DateTime(2026, 3),
            calendarTimeNodes: [
              CalendarTimeNodeReadModel(
                id: 'milestone-1',
                kind: CalendarTimeNodeKind.contactMilestone,
                title: '生日',
                subtitle: '张三',
                leadingText: '🎂',
                anchorDate: DateTime(2020, 3, 8),
                linkedContactId: 'contact-1',
                isRecurring: true,
                isLunar: false,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('eventsMonthlyCalendar_nodeBadge_8')), findsOneWidget);
  });
}