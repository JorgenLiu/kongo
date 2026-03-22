import 'event_summary.dart';

/// 每日总结草稿。
class DailySummaryDraft {
  final DateTime summaryDate;
  final String todaySummary;
  final String tomorrowPlan;
  final SummarySource source;
  final String? createdByContactId;
  final String? aiJobId;

  const DailySummaryDraft({
    required this.summaryDate,
    required this.todaySummary,
    required this.tomorrowPlan,
    this.source = SummarySource.manual,
    this.createdByContactId,
    this.aiJobId,
  });
}

typedef EventSummaryDraft = DailySummaryDraft;