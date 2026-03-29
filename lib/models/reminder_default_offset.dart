class ReminderDayOption {
  final int daysBefore;
  final String label;

  const ReminderDayOption({
    required this.daysBefore,
    required this.label,
  });
}

enum ReminderDefaultOffset {
  none(storageValue: 'none', label: '不提醒'),
  minutes15(storageValue: '15m', label: '提前 15 分钟', minutesBefore: 15),
  minutes30(storageValue: '30m', label: '提前 30 分钟', minutesBefore: 30),
  hour1(storageValue: '1h', label: '提前 1 小时', minutesBefore: 60),
  day1(storageValue: '1d', label: '提前 1 天', minutesBefore: 24 * 60);

  final String storageValue;
  final String label;
  final int? minutesBefore;

  const ReminderDefaultOffset({
    required this.storageValue,
    required this.label,
    this.minutesBefore,
  });

  bool get isEnabled => minutesBefore != null;

  Duration? get durationBefore =>
      minutesBefore == null ? null : Duration(minutes: minutesBefore!);

  static ReminderDefaultOffset fromStorageValue(String? rawValue) {
    for (final option in ReminderDefaultOffset.values) {
      if (option.storageValue == rawValue) {
        return option;
      }
    }

    return ReminderDefaultOffset.minutes30;
  }
}

const List<ReminderDayOption> kMilestoneReminderDayOptions = [
  ReminderDayOption(daysBefore: 0, label: '当天'),
  ReminderDayOption(daysBefore: 1, label: '提前 1 天'),
  ReminderDayOption(daysBefore: 3, label: '提前 3 天'),
  ReminderDayOption(daysBefore: 7, label: '提前 7 天'),
];

bool isSupportedMilestoneReminderDay(int daysBefore) {
  return kMilestoneReminderDayOptions.any((option) => option.daysBefore == daysBefore);
}

int fallbackMilestoneReminderDays(int? daysBefore) {
  if (daysBefore != null && isSupportedMilestoneReminderDay(daysBefore)) {
    return daysBefore;
  }

  return 1;
}