import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/models/reminder_authorization_status.dart';
import 'package:kongo/models/reminder_request.dart';
import 'package:kongo/models/reminder_settings.dart';
import 'package:kongo/providers/reminder_settings_provider.dart';
import 'package:kongo/services/reminder_service.dart';

void main() {
  test('ReminderSettingsProvider updates daily brief reminder toggle', () async {
    final service = _FakeReminderService();
    final provider = ReminderSettingsProvider(service);

    await provider.ready;
    await provider.setDailyBriefReminderEnabled(true);

    expect(provider.settings.dailyBriefReminderEnabled, isTrue);
    expect(service.settings.dailyBriefReminderEnabled, isTrue);
  });

  test('ReminderSettingsProvider updates daily brief reminder time', () async {
    final service = _FakeReminderService();
    final provider = ReminderSettingsProvider(service);

    await provider.ready;
    await provider.setDailyBriefReminderTime(hour: 8, minute: 45);

    expect(provider.settings.dailyBriefReminderHour, 8);
    expect(provider.settings.dailyBriefReminderMinute, 45);
    expect(service.settings.dailyBriefReminderHour, 8);
    expect(service.settings.dailyBriefReminderMinute, 45);
  });
}

class _FakeReminderService implements ReminderService {
  ReminderSettings settings = const ReminderSettings();

  @override
  Future<ReminderAuthorizationStatus> getAuthorizationStatus() async {
    return ReminderAuthorizationStatus.authorized;
  }

  @override
  Future<ReminderSettings> getSettings() async => settings;

  @override
  Future<void> rebuildPendingReminders({int eventDays = 30, int milestoneDays = 30}) async {}

  @override
  Future<void> removeEventReminder(String eventId) async {}

  @override
  Future<void> removeMilestoneReminder(String milestoneId) async {}

  @override
  Future<ReminderAuthorizationStatus> requestAuthorization() async {
    return ReminderAuthorizationStatus.authorized;
  }

  @override
  Future<void> scheduleDailyBriefReminder(ReminderRequest request) async {}

  @override
  Future<void> snoozeReminder(interaction) async {}

  @override
  Future<void> syncEventReminder(event) async {}

  @override
  Future<void> syncMilestoneReminder(milestone) async {}

  @override
  Future<ReminderSettings> updateSettings(ReminderSettings settings) async {
    this.settings = settings;
    return settings;
  }
}