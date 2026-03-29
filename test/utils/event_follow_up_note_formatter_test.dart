import 'package:flutter_test/flutter_test.dart';
import 'package:kongo/utils/event_follow_up_note_formatter.dart';

void main() {
  test('appendEventFollowUpNote appends a timestamped follow-up block', () {
    final result = appendEventFollowUpNote(
      '原始描述',
      '客户答应周三前确认预算',
      timestamp: DateTime(2026, 3, 27, 14, 30),
    );

    expect(result, contains('原始描述'));
    expect(result, contains('会后补充（2026-03-27 14:30）'));
    expect(result, contains('- 客户答应周三前确认预算'));
  });

  test('appendEventFollowUpNote creates a standalone block when description is empty', () {
    final result = appendEventFollowUpNote(
      null,
      '补报价给客户',
      timestamp: DateTime(2026, 3, 27, 15, 0),
    );

    expect(result.startsWith('会后补充（2026-03-27 15:00）'), isTrue);
    expect(result, contains('- 补报价给客户'));
  });
}