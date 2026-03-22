import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/models/event_summary_draft.dart';
import 'package:kongo/providers/provider_error.dart';

import '../test_helpers/test_app_harness.dart';

void main() {
  late TestAppHarness harness;

  setUp(() async {
    harness = await createTestAppHarness();
  });

  tearDown(() async {
    await harness.dispose();
  });

  test('SummaryProvider creates daily summary and extracts action items', () async {
    final provider = harness.dependencies.summaryProvider;

    await provider.createSummary(
      DailySummaryDraft(
        summaryDate: DateTime(2026, 3, 22),
        todaySummary: '完成回访纪要整理。',
        tomorrowPlan: 'TODO: 整理后续报价\n- [x] 已同步关键结论',
      ),
    );

    expect(provider.currentSummary, isNotNull);
    expect(provider.currentSummary?.todaySummary, contains('回访纪要'));
    expect(provider.actionItems.map((item) => item.title), containsAll(['整理后续报价', '已同步关键结论']));
    expect(provider.error, isNull);
  });

  test('SummaryProvider updates summary content and refreshes action items', () async {
    final provider = harness.dependencies.summaryProvider;
    final summary = (await harness.dependencies.summaryService.getSummaries()).first;

    await provider.updateSummary(
      summary.copyWith(
        todaySummary: '更新后的当日结论',
        tomorrowPlan: '1. 推进下一轮演示\nTODO: 确认时间',
      ),
    );

    expect(provider.currentSummary?.todaySummary, '更新后的当日结论');
    expect(provider.actionItems.map((item) => item.title), containsAll(['推进下一轮演示', '确认时间']));
    expect(provider.error, isNull);
  });

  test('SummaryProvider deletes summary and clears cached state', () async {
    final provider = harness.dependencies.summaryProvider;

    await provider.createSummary(
      DailySummaryDraft(
        summaryDate: DateTime(2026, 3, 23),
        todaySummary: '待删除总结',
        tomorrowPlan: 'TODO: 删除我',
      ),
    );

    final summaryId = provider.currentSummary!.id;
    await provider.deleteSummary(summaryId);

    expect(provider.currentSummary, isNull);
    expect(provider.actionItems, isEmpty);
    expect(provider.error, isNull);
  });

  test('SummaryProvider loads action items for existing summary', () async {
    final provider = harness.dependencies.summaryProvider;
    final summary = (await harness.dependencies.summaryService.getSummaries()).first;

    await provider.loadActionItems(summary.id);

    expect(provider.actionItems, isNotEmpty);
    expect(provider.actionItems.map((item) => item.title), contains('下周整理报价方案。'));
    expect(provider.error, isNull);
  });

  test('SummaryProvider loads summary detail and replaces previous action items', () async {
    final provider = harness.dependencies.summaryProvider;
    final firstSummary = (await harness.dependencies.summaryService.getSummaries()).first;

    await provider.loadSummaryDetail(firstSummary.id);
    expect(provider.currentSummary?.id, firstSummary.id);
    expect(provider.actionItems, isNotEmpty);

    final secondSummary = await harness.dependencies.summaryService.createSummary(
      DailySummaryDraft(
        summaryDate: DateTime(2026, 3, 24),
        todaySummary: '本次合作方向已经确认，等待下轮推进。',
        tomorrowPlan: '',
      ),
    );

    await provider.loadSummaryDetail(secondSummary.id);

    expect(provider.currentSummary?.id, secondSummary.id);
    expect(provider.currentSummary?.todaySummary, '本次合作方向已经确认，等待下轮推进。');
    expect(provider.actionItems, isEmpty);
    expect(provider.initialized, isTrue);
    expect(provider.error, isNull);
  });

  test('SummaryProvider maps duplicate-date creation failure to structured errors', () async {
    final provider = harness.dependencies.summaryProvider;
    final existing = (await harness.dependencies.summaryService.getSummaries()).first;

    await provider.createSummary(
      DailySummaryDraft(
        summaryDate: existing.summaryDate,
        todaySummary: '不应创建',
        tomorrowPlan: 'TODO: 失败案例',
      ),
    );

    expect(provider.error, isNotNull);
    expect(provider.error?.type, ProviderErrorType.business);
    expect(provider.error?.code, 'summary_date_exists');
  });

  test('SummaryProvider supports keyword search across summary sections', () async {
    final provider = harness.dependencies.summaryProvider;

    await provider.searchByKeyword('报价');

    expect(provider.error, isNull);
    expect(provider.keyword, '报价');
    expect(provider.summaries.length, 1);
    expect(provider.summaries.first.tomorrowPlan, contains('报价方案'));
  });
}