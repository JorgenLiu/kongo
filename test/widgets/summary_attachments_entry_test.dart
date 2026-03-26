import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/models/event_summary.dart';
import 'package:kongo/widgets/summary/daily_summary_list.dart';

void main() {
  testWidgets('Daily summary card exposes attachments menu item when callback is provided', (
    WidgetTester tester,
  ) async {
    final summary = DailySummary(
      id: 'summary-1',
      summaryDate: DateTime(2026, 3, 23),
      todaySummary: '完成文件库改造讨论。',
      tomorrowPlan: '继续推进总结附件入口。',
      createdAt: DateTime(2026, 3, 23),
      updatedAt: DateTime(2026, 3, 23),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailySummaryList(
            summaries: [summary],
            onManageAttachments: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('附件'), findsOneWidget);
  });
}