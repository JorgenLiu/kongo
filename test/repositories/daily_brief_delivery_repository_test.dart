import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/models/calendar_time_node_settings.dart';
import 'package:kongo/models/daily_brief_delivery_status.dart';
import 'package:kongo/models/reminder_settings.dart';
import 'package:kongo/repositories/daily_brief_delivery_repository.dart';
import 'package:kongo/services/settings_preferences_store.dart';

void main() {
  late _InMemorySettingsPreferencesStore preferencesStore;
  late SettingsDailyBriefDeliveryRepository repository;

  setUp(() {
    preferencesStore = _InMemorySettingsPreferencesStore();
    repository = SettingsDailyBriefDeliveryRepository(preferencesStore);
  });

  test('saveStatus persists and reloads a delivery record', () async {
    final status = DailyBriefDeliveryStatus(
      dateKey: '2026-03-27',
      channel: DailyBriefDeliveryChannel.systemReminder,
      deliveredAt: DateTime(2026, 3, 27, 9, 0),
      briefStatus: 'ready',
      summaryHash: 'abc123',
    );

    await repository.saveStatus(status);

    final reloaded = await repository.getStatus(
      dateKey: '2026-03-27',
      channel: DailyBriefDeliveryChannel.systemReminder,
    );

    expect(reloaded, isNotNull);
    expect(reloaded!.dateKey, '2026-03-27');
    expect(reloaded.channel, DailyBriefDeliveryChannel.systemReminder);
    expect(reloaded.summaryHash, 'abc123');
  });

  test('pruneOldStatuses removes records older than max age', () async {
    await repository.saveStatus(
      DailyBriefDeliveryStatus(
        dateKey: '2026-01-01',
        channel: DailyBriefDeliveryChannel.systemReminder,
        deliveredAt: DateTime(2026, 1, 1, 9, 0),
        briefStatus: 'ready',
        summaryHash: 'old',
      ),
    );
    await repository.saveStatus(
      DailyBriefDeliveryStatus(
        dateKey: '2026-03-27',
        channel: DailyBriefDeliveryChannel.systemReminder,
        deliveredAt: DateTime(2026, 3, 27, 9, 0),
        briefStatus: 'ready',
        summaryHash: 'new',
      ),
    );

    await repository.pruneOldStatuses(
      maxAge: const Duration(days: 30),
      now: DateTime(2026, 3, 27, 12),
    );

    final oldStatus = await repository.getStatus(
      dateKey: '2026-01-01',
      channel: DailyBriefDeliveryChannel.systemReminder,
    );
    final newStatus = await repository.getStatus(
      dateKey: '2026-03-27',
      channel: DailyBriefDeliveryChannel.systemReminder,
    );

    expect(oldStatus, isNull);
    expect(newStatus, isNotNull);
    expect(newStatus!.summaryHash, 'new');
  });
}

class _InMemorySettingsPreferencesStore implements SettingsPreferencesStore {
  ReminderSettings _reminderSettings = const ReminderSettings();
  ThemeMode _themeMode = ThemeMode.system;
  CalendarTimeNodeSettings _calendarSettings = const CalendarTimeNodeSettings();
  final Map<String, String> _values = <String, String>{};

  @override
  Future<CalendarTimeNodeSettings> getCalendarTimeNodeSettings() async => _calendarSettings;

  @override
  Future<ReminderSettings> getReminderSettings() async => _reminderSettings;

  @override
  Future<String?> getString(String key) async => _values[key];

  @override
  Future<ThemeMode> getThemeMode() async => _themeMode;

  @override
  Future<void> removeKey(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> setCalendarTimeNodeSettings(CalendarTimeNodeSettings settings) async {
    _calendarSettings = settings;
  }

  @override
  Future<void> setReminderSettings(ReminderSettings settings) async {
    _reminderSettings = settings;
  }

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
  }

  @override
  Future<bool> getQuickCaptureAiEnabled() async => false;

  @override
  Future<void> setQuickCaptureAiEnabled(bool enabled) async {}
}