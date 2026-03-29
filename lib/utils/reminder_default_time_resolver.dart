import '../models/reminder_default_offset.dart';
import '../models/reminder_snooze_action.dart';

DateTime? resolveEventReminderAtFromDefaultOffset({
  required DateTime? startAt,
  required ReminderDefaultOffset offset,
}) {
  if (!offset.isEnabled || startAt == null) {
    return null;
  }

  return startAt.subtract(offset.durationBefore!);
}

bool isReminderSnoozeActionAvailable({
  required DateTime now,
  required ReminderSnoozeAction action,
}) {
  switch (action) {
    case ReminderSnoozeAction.tenMinutes:
      return true;
    case ReminderSnoozeAction.laterToday:
      return _todayAt20(now).isAfter(now);
  }
}

DateTime? resolveSnoozeReminderAt({
  required DateTime now,
  required ReminderSnoozeAction action,
}) {
  switch (action) {
    case ReminderSnoozeAction.tenMinutes:
      return now.add(const Duration(minutes: 10));
    case ReminderSnoozeAction.laterToday:
      final cutoff = _todayAt20(now);
      if (!cutoff.isAfter(now)) {
        return null;
      }

      final candidate = now.add(const Duration(hours: 3));
      return candidate.isAfter(cutoff) ? cutoff : candidate;
  }
}

DateTime _todayAt20(DateTime now) {
  return DateTime(now.year, now.month, now.day, 20);
}