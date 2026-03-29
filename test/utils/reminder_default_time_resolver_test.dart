import 'package:flutter_test/flutter_test.dart';
import 'package:kongo/models/reminder_default_offset.dart';
import 'package:kongo/models/reminder_snooze_action.dart';
import 'package:kongo/utils/reminder_default_time_resolver.dart';

void main() {
  test('Default event reminder resolves from selected offset', () {
    final result = resolveEventReminderAtFromDefaultOffset(
      startAt: DateTime(2026, 3, 27, 14, 0),
      offset: ReminderDefaultOffset.hour1,
    );

    expect(result, DateTime(2026, 3, 27, 13, 0));
  });

  test('Default event reminder is null when offset is none', () {
    final result = resolveEventReminderAtFromDefaultOffset(
      startAt: DateTime(2026, 3, 27, 14, 0),
      offset: ReminderDefaultOffset.none,
    );

    expect(result, isNull);
  });

  test('Later today snooze resolves to now plus three hours before cutoff', () {
    final result = resolveSnoozeReminderAt(
      now: DateTime(2026, 3, 27, 14, 0),
      action: ReminderSnoozeAction.laterToday,
    );

    expect(result, DateTime(2026, 3, 27, 17, 0));
  });

  test('Later today snooze clamps to 20:00 cutoff', () {
    final result = resolveSnoozeReminderAt(
      now: DateTime(2026, 3, 27, 18, 30),
      action: ReminderSnoozeAction.laterToday,
    );

    expect(result, DateTime(2026, 3, 27, 20, 0));
  });

  test('Later today snooze becomes unavailable after 20:00', () {
    final now = DateTime(2026, 3, 27, 20, 30);

    expect(
      isReminderSnoozeActionAvailable(now: now, action: ReminderSnoozeAction.laterToday),
      isFalse,
    );
    expect(
      resolveSnoozeReminderAt(now: now, action: ReminderSnoozeAction.laterToday),
      isNull,
    );
  });
}