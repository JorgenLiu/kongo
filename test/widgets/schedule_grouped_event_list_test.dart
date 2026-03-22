import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/models/event.dart';
import 'package:kongo/services/read/event_read_service.dart';
import 'package:kongo/widgets/event/schedule_grouped_event_list.dart';

void main() {
  final referenceDate = DateTime(2026, 3, 18, 9);

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

  testWidgets('Schedule grouped event list shows weekly sections by priority', (WidgetTester tester) async {
    final items = [
      buildItem(
        id: 'today',
        title: '今天的日程',
        startAt: DateTime(2026, 3, 18, 10),
      ),
      buildItem(
        id: 'upcoming',
        title: '本周后续日程',
        startAt: DateTime(2026, 3, 20, 11),
      ),
      buildItem(
        id: 'completed',
        title: '本周较早日程',
        startAt: DateTime(2026, 3, 17, 15),
      ),
      buildItem(
        id: 'outside',
        title: '下周日程',
        startAt: DateTime(2026, 3, 25, 9),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ScheduleGroupedEventList(
              items: items,
              selectedDate: null,
              referenceDate: referenceDate,
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('今日日程'), findsOneWidget);
    expect(find.text('本周后续'), findsOneWidget);
    expect(find.text('本周较早'), findsOneWidget);
    expect(find.text('今天的日程'), findsOneWidget);
    expect(find.text('本周后续日程'), findsOneWidget);
    expect(find.text('本周较早日程'), findsOneWidget);
    expect(find.text('下周日程'), findsNothing);
  });

  testWidgets('Schedule grouped event list filters by selected date', (WidgetTester tester) async {
    final items = [
      buildItem(
        id: 'today',
        title: '今天的日程',
        startAt: DateTime(2026, 3, 18, 10),
      ),
      buildItem(
        id: 'selected',
        title: '选中日期日程',
        startAt: DateTime(2026, 3, 20, 11),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ScheduleGroupedEventList(
              items: items,
              selectedDate: DateTime(2026, 3, 20),
              referenceDate: referenceDate,
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('3 月 20 日'), findsOneWidget);
    expect(find.text('选中日期日程'), findsOneWidget);
    expect(find.text('今天的日程'), findsNothing);
    expect(find.text('今日日程'), findsNothing);
  });
}