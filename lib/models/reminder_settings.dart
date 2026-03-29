import 'reminder_default_offset.dart';

class ReminderSettings {
  final bool remindersEnabled;
  final bool eventRemindersEnabled;
  final bool milestoneRemindersEnabled;
  final bool postEventFollowUpEnabled;
  final bool dailyBriefReminderEnabled;
  final int dailyBriefReminderHour;
  final int dailyBriefReminderMinute;
  final ReminderDefaultOffset eventDefaultOffset;
  final int milestoneDefaultReminderDaysBefore;

  const ReminderSettings({
    this.remindersEnabled = true,
    this.eventRemindersEnabled = true,
    this.milestoneRemindersEnabled = true,
    this.postEventFollowUpEnabled = true,
    this.dailyBriefReminderEnabled = false,
    this.dailyBriefReminderHour = 9,
    this.dailyBriefReminderMinute = 0,
    this.eventDefaultOffset = ReminderDefaultOffset.minutes30,
    this.milestoneDefaultReminderDaysBefore = 1,
  });

  ReminderSettings copyWith({
    bool? remindersEnabled,
    bool? eventRemindersEnabled,
    bool? milestoneRemindersEnabled,
    bool? postEventFollowUpEnabled,
    bool? dailyBriefReminderEnabled,
    int? dailyBriefReminderHour,
    int? dailyBriefReminderMinute,
    ReminderDefaultOffset? eventDefaultOffset,
    int? milestoneDefaultReminderDaysBefore,
  }) {
    return ReminderSettings(
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      eventRemindersEnabled: eventRemindersEnabled ?? this.eventRemindersEnabled,
      milestoneRemindersEnabled: milestoneRemindersEnabled ?? this.milestoneRemindersEnabled,
      postEventFollowUpEnabled: postEventFollowUpEnabled ?? this.postEventFollowUpEnabled,
      dailyBriefReminderEnabled:
          dailyBriefReminderEnabled ?? this.dailyBriefReminderEnabled,
      dailyBriefReminderHour: dailyBriefReminderHour ?? this.dailyBriefReminderHour,
      dailyBriefReminderMinute:
          dailyBriefReminderMinute ?? this.dailyBriefReminderMinute,
      eventDefaultOffset: eventDefaultOffset ?? this.eventDefaultOffset,
      milestoneDefaultReminderDaysBefore:
          milestoneDefaultReminderDaysBefore ?? this.milestoneDefaultReminderDaysBefore,
    );
  }
}