import '../models/calendar_time_node.dart';
import '../models/calendar_time_node_settings.dart';
import '../services/calendar_time_node_settings_service.dart';
import 'base_provider.dart';

class CalendarTimeNodeSettingsProvider extends BaseProvider {
  final CalendarTimeNodeSettingsService _service;

  CalendarTimeNodeSettingsProvider(this._service) {
    load();
  }

  CalendarTimeNodeSettings _settings = const CalendarTimeNodeSettings();

  CalendarTimeNodeSettings get settings => _settings;

  bool isEnabled(CalendarTimeNodeKind kind) => _settings.isEnabled(kind);

  Future<void> load() async {
    await execute(() async {
      try {
        _settings = await _service.getSettings();
      } catch (_) {
        _settings = const CalendarTimeNodeSettings();
      }
    });
  }

  Future<void> setKindEnabled(CalendarTimeNodeKind kind, bool enabled) async {
    if (_settings.isEnabled(kind) == enabled) {
      return;
    }

    _settings = _copySettingsFor(kind, enabled);
    notifyListenersSafely();

    try {
      _settings = await _service.setKindEnabled(kind, enabled);
    } catch (_) {
      if (isDisposed) {
        return;
      }
      _settings = const CalendarTimeNodeSettings();
      rethrow;
    } finally {
      notifyListenersSafely();
    }
  }

  CalendarTimeNodeSettings _copySettingsFor(
    CalendarTimeNodeKind kind,
    bool enabled,
  ) {
    switch (kind) {
      case CalendarTimeNodeKind.contactMilestone:
        return _settings.copyWith(contactMilestonesEnabled: enabled);
      case CalendarTimeNodeKind.publicHoliday:
        return _settings.copyWith(publicHolidaysEnabled: enabled);
      case CalendarTimeNodeKind.marketingCampaign:
        return _settings.copyWith(marketingCampaignsEnabled: enabled);
    }
  }
}