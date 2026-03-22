import '../models/event_summary.dart';

String formatSummarySourceLabel(SummarySource source) {
  switch (source) {
    case SummarySource.manual:
      return '人工';
    case SummarySource.ai:
      return 'AI';
    case SummarySource.mixed:
      return '人工 + AI';
  }
}