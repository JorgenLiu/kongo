import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kongo/models/reminder_default_offset.dart';
import 'package:kongo/models/reminder_settings.dart';
import 'package:kongo/services/settings_preferences_store.dart';

void main() {
  late Directory settingsDirectory;
  late JsonSettingsPreferencesStore store;

  setUp(() async {
    settingsDirectory = await Directory.systemTemp.createTemp('kongo_reminder_defaults_');
    store = JsonSettingsPreferencesStore(
      settingsDirectoryResolver: () async => settingsDirectory,
    );
  });

  tearDown(() async {
    if (await settingsDirectory.exists()) {
      await settingsDirectory.delete(recursive: true);
    }
  });

  test('Reminder settings fall back to default values when keys are missing', () async {
    final settings = await store.getReminderSettings();

    expect(settings.dailyBriefReminderEnabled, isFalse);
    expect(settings.dailyBriefReminderHour, 9);
    expect(settings.dailyBriefReminderMinute, 0);
    expect(settings.eventDefaultOffset, ReminderDefaultOffset.minutes30);
    expect(settings.milestoneDefaultReminderDaysBefore, 1);
  });

  test('Reminder settings persist event default offset and milestone default days', () async {
    await store.setReminderSettings(
      const ReminderSettings(
        dailyBriefReminderEnabled: true,
        dailyBriefReminderHour: 8,
        dailyBriefReminderMinute: 15,
        eventDefaultOffset: ReminderDefaultOffset.day1,
        milestoneDefaultReminderDaysBefore: 7,
      ),
    );

    final settings = await store.getReminderSettings();

    expect(settings.dailyBriefReminderEnabled, isTrue);
    expect(settings.dailyBriefReminderHour, 8);
    expect(settings.dailyBriefReminderMinute, 15);
    expect(settings.eventDefaultOffset, ReminderDefaultOffset.day1);
    expect(settings.milestoneDefaultReminderDaysBefore, 7);
  });

  test('Unsupported milestone default day falls back to 1 day', () async {
    await store.setReminderSettings(
      const ReminderSettings(milestoneDefaultReminderDaysBefore: 1),
    );
    await store.setString('reminderSettings', '{"milestoneDefaultReminderDaysBefore":14}');

    final settings = await store.getReminderSettings();

    expect(settings.milestoneDefaultReminderDaysBefore, 1);
  });
}