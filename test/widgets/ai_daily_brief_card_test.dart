import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/models/home_daily_brief.dart';
import 'package:kongo/widgets/home/ai_daily_brief_card.dart';

void main() {
  testWidgets('AiDailyBriefCard shows loading state', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildCard(
        brief: null,
        loading: true,
      ),
    );

    expect(find.byKey(const Key('aiDailyBriefLoadingState')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('AiDailyBriefCard shows unavailable state message', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildCard(
        brief: HomeDailyBrief.unavailable(summary: '配置 AI 后可获得今日秘书简报。'),
      ),
    );

    expect(find.byKey(const Key('aiDailyBriefUnavailableState')), findsOneWidget);
    expect(find.text('AI 尚未启用'), findsOneWidget);
    expect(find.text('配置 AI 后可获得今日秘书简报。'), findsOneWidget);
  });

  testWidgets('AiDailyBriefCard shows error state and retry callback', (WidgetTester tester) async {
    var retried = false;

    await tester.pumpWidget(
      _buildCard(
        brief: HomeDailyBrief.failed('今日简报生成失败：provider unavailable'),
        onRetry: () => retried = true,
      ),
    );

    expect(find.byKey(const Key('aiDailyBriefErrorState')), findsOneWidget);
    expect(find.text('今日简报生成失败：provider unavailable'), findsOneWidget);

    await tester.tap(find.text('重新生成'));
    await tester.pump();

    expect(retried, isTrue);
  });

  testWidgets('AiDailyBriefCard renders summary and item actions', (WidgetTester tester) async {
    HomeDailyBriefActionType? tappedAction;
    String? tappedTargetId;

    await tester.pumpWidget(
      _buildCard(
        brief: const HomeDailyBrief(
          status: HomeDailyBriefStatus.ready,
          summary: '今天有 2 个会议，建议优先跟进张三。',
          items: [
            HomeDailyBriefItem(
              type: HomeDailyBriefItemType.followUp,
              title: '优先跟进张三',
              reason: '今天有共同会议，建议会后补跟进记录。',
              primaryAction: HomeDailyBriefActionType.openContact,
              primaryTargetId: 'contact-1',
              secondaryAction: HomeDailyBriefActionType.openEvent,
              secondaryTargetId: 'event-1',
            ),
          ],
        ),
        onActionTap: (action, targetId) {
          tappedAction = action;
          tappedTargetId = targetId;
        },
      ),
    );

    expect(find.byKey(const Key('aiDailyBriefReadyState')), findsOneWidget);
    expect(find.byKey(const Key('aiDailyBriefSummaryText')), findsOneWidget);
    expect(find.text('优先跟进张三'), findsOneWidget);
    expect(find.text('待跟进'), findsOneWidget);
    expect(find.text('查看联系人'), findsNothing);
    expect(find.text('查看事件'), findsNothing);

    await tester.tap(find.byKey(const Key('aiDailyBriefToggle_优先跟进张三')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('aiDailyBriefExpanded_优先跟进张三')), findsOneWidget);
    expect(find.text('查看联系人'), findsOneWidget);
    expect(find.text('查看事件'), findsOneWidget);

    await tester.tap(find.byKey(const Key('aiDailyBriefPrimaryAction_优先跟进张三')));
    await tester.pump();

    expect(tappedAction, HomeDailyBriefActionType.openContact);
    expect(tappedTargetId, 'contact-1');
  });
}

Widget _buildCard({
  required HomeDailyBrief? brief,
  bool loading = false,
  bool refreshing = false,
  VoidCallback? onRetry,
  HomeDailyBriefActionHandler? onActionTap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: AiDailyBriefCard(
        brief: brief,
        loading: loading,
        refreshing: refreshing,
        onRetry: onRetry,
        onActionTap: onActionTap,
      ),
    ),
  );
}