import '../models/calendar_time_node.dart';
import '../models/calendar_time_node_settings.dart';
import 'settings_preferences_store.dart';

abstract class CalendarTimeNodeSettingsService {
  Future<CalendarTimeNodeSettings> getSettings();
  Future<CalendarTimeNodeSettings> setKindEnabled(
    CalendarTimeNodeKind kind,
    bool enabled,
  );
}

class DefaultCalendarTimeNodeSettingsService
    implements CalendarTimeNodeSettingsService {
  final SettingsPreferencesStore _settingsPreferencesStore;

  DefaultCalendarTimeNodeSettingsService(this._settingsPreferencesStore);

  @override
  Future<CalendarTimeNodeSettings> getSettings() async {
    return _settingsPreferencesStore.getCalendarTimeNodeSettings();
  }

  @override
  Future<CalendarTimeNodeSettings> setKindEnabled(
    CalendarTimeNodeKind kind,
    bool enabled,
  ) async {
    final currentSettings = await _settingsPreferencesStore.getCalendarTimeNodeSettings();
    final nextSettings = switch (kind) {
      CalendarTimeNodeKind.contactMilestone =>
        currentSettings.copyWith(contactMilestonesEnabled: enabled),
      CalendarTimeNodeKind.publicHoliday =>
        currentSettings.copyWith(publicHolidaysEnabled: enabled),
      CalendarTimeNodeKind.marketingCampaign =>
        currentSettings.copyWith(marketingCampaignsEnabled: enabled),
    };

    await _settingsPreferencesStore.setCalendarTimeNodeSettings(nextSettings);
    return nextSettings;
  }
}