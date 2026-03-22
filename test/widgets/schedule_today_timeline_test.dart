import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/models/event.dart';
import 'package:kongo/services/read/event_read_service.dart';
import 'package:kongo/widgets/event/schedule_today_timeline.dart';

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
      participantNames: const ['林晨'],
    );
  }

  testWidgets('Schedule today timeline shows today events and current hour marker', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleTodayTimeline(
            referenceDate: referenceDate,
            items: [
              buildItem(
                id: 'today-1',
                title: '晨会',
                startAt: DateTime(2026, 3, 18, 9),
              ),
              buildItem(
                id: 'today-2',
                title: '午间同步',
                startAt: DateTime(2026, 3, 18, 11),
              ),
              buildItem(
                id: 'tomorrow',
                title: '明天的安排',
                startAt: DateTime(2026, 3, 19, 9),
              ),
            ],
            onItemTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('scheduleTodayTimeline')), findsOneWidget);
    expect(find.byKey(const Key('scheduleTimelineHour_09')), findsOneWidget);
    expect(find.byKey(const Key('scheduleTimelineHour_10')), findsOneWidget);
    expect(find.byKey(const Key('scheduleTimelineHour_11')), findsOneWidget);
    expect(find.text('晨会'), findsOneWidget);
    expect(find.text('午间同步'), findsOneWidget);
    expect(find.text('明天的安排'), findsNothing);
  });

  testWidgets('Schedule today timeline updates when reference date changes', (
    WidgetTester tester,
  ) async {
    Widget buildTimeline(DateTime referenceDate) {
      return MaterialApp(
        home: Scaffold(
          body: ScheduleTodayTimeline(
            referenceDate: referenceDate,
            items: [
              buildItem(
                id: 'today-1',
                title: '晨会',
                startAt: DateTime(2026, 3, 18, 9),
              ),
              buildItem(
                id: 'tomorrow',
                title: '明天的安排',
                startAt: DateTime(2026, 3, 19, 9),
              ),
            ],
            onItemTap: (_) {},
          ),
        ),
      );
    }

    await tester.pumpWidget(buildTimeline(DateTime(2026, 3, 18, 9, 30)));
    await tester.pumpAndSettle();

    expect(find.text('晨会'), findsOneWidget);
    expect(find.text('明天的安排'), findsNothing);

    await tester.pumpWidget(buildTimeline(DateTime(2026, 3, 19, 9, 30)));
    await tester.pumpAndSettle();

    expect(find.text('晨会'), findsNothing);
    expect(find.text('明天的安排'), findsOneWidget);
  });

  testWidgets('Schedule today timeline removes guidance copy from header', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleTodayTimeline(
            referenceDate: referenceDate,
            items: [
              buildItem(
                id: 'today-1',
                title: '晨会',
                startAt: DateTime(2026, 3, 18, 9),
              ),
            ],
            onItemTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('默认定位'), findsNothing);
    expect(find.text('这个时间点没有安排'), findsNothing);
  });
}