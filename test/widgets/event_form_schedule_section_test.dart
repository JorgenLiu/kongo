import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/widgets/event/event_form_schedule_section.dart';

void main() {
  testWidgets('Event form schedule section syncs controller text without build exception', (
    WidgetTester tester,
  ) async {
    DateTime? startAt;
    DateTime? endAt;

    Widget buildTestWidget() {
      return MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: EventFormScheduleSection(
                startAt: startAt,
                endAt: endAt,
                onStartChanged: (value) {
                  setState(() {
                    startAt = value;
                  });
                },
                onEndChanged: (value) {
                  setState(() {
                    endAt = value;
                  });
                },
              ),
            );
          },
        ),
      );
    }

    await tester.pumpWidget(buildTestWidget());

    startAt = DateTime(2026, 3, 22, 9);
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('09:00'), findsOneWidget);
  });
}