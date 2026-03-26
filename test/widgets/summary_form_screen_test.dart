import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kongo/screens/summaries/summary_form_screen.dart';

void main() {
  testWidgets('Summary form renders Markdown preview from input', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SummaryFormScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, '当日总结'),
      '# 今日复盘\n- 完成客户回访',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '明日计划'),
      'TODO: 跟进报价',
    );
    await tester.pumpAndSettle();

    expect(find.text('Markdown 预览'), findsOneWidget);
    expect(find.text('今日复盘'), findsOneWidget);
    expect(find.text('完成客户回访'), findsOneWidget);
    expect(find.textContaining('跟进报价'), findsWidgets);
  });
}