import 'package:flutter/foundation.dart';

import '../models/calendar_time_node.dart';
import '../models/calendar_time_node_settings.dart';
import '../services/calendar_time_node_settings_service.dart';

class CalendarTimeNodeSettingsProvider extends ChangeNotifier {
  final CalendarTimeNodeSettingsService _service;

  CalendarTimeNodeSettingsProvider(this._service) {
    load();
  }

  CalendarTimeNodeSettings _settings = const CalendarTimeNodeSettings();
  bool _loading = false;
  bool _disposed = false;

  CalendarTimeNodeSettings get settings => _settings;
  bool get loading => _loading;

  bool isEnabled(CalendarTimeNodeKind kind) => _settings.isEnabled(kind);

  Future<void> load() async {
    _loading = true;
    _notifyListenersSafely();

    try {
      _settings = await _service.getSettings();
    } catch (_) {
      if (_disposed) {
        return;
      }
      _settings = const CalendarTimeNodeSettings();
    } finally {
      if (!_disposed) {
        _loading = false;
        _notifyListenersSafely();
      }
    }
  }

  Future<void> setKindEnabled(CalendarTimeNodeKind kind, bool enabled) async {
    if (_settings.isEnabled(kind) == enabled) {
      return;
    }

    _settings = _copySettingsFor(kind, enabled);
    _notifyListenersSafely();

    try {
      _settings = await _service.setKindEnabled(kind, enabled);
    } catch (_) {
      if (_disposed) {
        return;
      }
      _settings = const CalendarTimeNodeSettings();
      rethrow;
    } finally {
      _notifyListenersSafely();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
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

  void _notifyListenersSafely() {
    if (_disposed) {
      return;
    }
    notifyListeners();
  }
}