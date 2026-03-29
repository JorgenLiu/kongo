import '../models/reminder_default_offset.dart';
import '../models/reminder_authorization_status.dart';
import '../models/reminder_settings.dart';
import '../services/reminder_service.dart';
import 'base_provider.dart';

class ReminderSettingsProvider extends BaseProvider {
  final ReminderService _reminderService;

  late final Future<void> _initialLoadFuture;

  ReminderSettings _settings = const ReminderSettings();
  ReminderAuthorizationStatus _authorizationStatus = ReminderAuthorizationStatus.notDetermined;
  bool _saving = false;
  bool _requestingAuthorization = false;
  bool _rebuilding = false;
  String? _errorMessage;

  ReminderSettingsProvider(this._reminderService) {
    _initialLoadFuture = reload();
  }

  ReminderSettings get settings => _settings;
  ReminderAuthorizationStatus get authorizationStatus => _authorizationStatus;
  bool get saving => _saving;
  bool get requestingAuthorization => _requestingAuthorization;
  bool get rebuilding => _rebuilding;
  bool get busy => _saving || _requestingAuthorization || _rebuilding;
  String? get errorMessage => _errorMessage;
  Future<void> get ready => _initialLoadFuture;

  Future<void> reload() async {
    await execute(() async {
      _errorMessage = null;
      try {
        _settings = await _reminderService.getSettings();
        _authorizationStatus = await _reminderService.getAuthorizationStatus();
      } catch (error) {
        _errorMessage = error.toString();
      }
    });
  }

  Future<void> setRemindersEnabled(bool value) {
    return _updateSettings(_settings.copyWith(remindersEnabled: value));
  }

  Future<void> setEventRemindersEnabled(bool value) {
    return _updateSettings(_settings.copyWith(eventRemindersEnabled: value));
  }

  Future<void> setMilestoneRemindersEnabled(bool value) {
    return _updateSettings(_settings.copyWith(milestoneRemindersEnabled: value));
  }

  Future<void> setPostEventFollowUpEnabled(bool value) {
    return _updateSettings(_settings.copyWith(postEventFollowUpEnabled: value));
  }

  Future<void> setDailyBriefReminderEnabled(bool value) {
    return _updateSettings(_settings.copyWith(dailyBriefReminderEnabled: value));
  }

  Future<void> setDailyBriefReminderTime({
    required int hour,
    required int minute,
  }) {
    return _updateSettings(
      _settings.copyWith(
        dailyBriefReminderHour: hour,
        dailyBriefReminderMinute: minute,
      ),
    );
  }

  Future<void> setEventDefaultOffset(ReminderDefaultOffset value) {
    return _updateSettings(_settings.copyWith(eventDefaultOffset: value));
  }

  Future<void> setMilestoneDefaultReminderDaysBefore(int value) {
    return _updateSettings(_settings.copyWith(milestoneDefaultReminderDaysBefore: value));
  }

  Future<void> requestAuthorization() async {
    _requestingAuthorization = true;
    _errorMessage = null;
    notifyListenersSafely();

    try {
      _authorizationStatus = await _reminderService.requestAuthorization();
      _settings = await _reminderService.getSettings();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _requestingAuthorization = false;
      notifyListenersSafely();
    }
  }

  Future<void> rebuildNow() async {
    _rebuilding = true;
    _errorMessage = null;
    notifyListenersSafely();

    try {
      await _reminderService.rebuildPendingReminders();
      _authorizationStatus = await _reminderService.getAuthorizationStatus();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _rebuilding = false;
      notifyListenersSafely();
    }
  }

  Future<void> _updateSettings(ReminderSettings nextSettings) async {
    _saving = true;
    _errorMessage = null;
    notifyListenersSafely();

    try {
      _settings = await _reminderService.updateSettings(nextSettings);
      _authorizationStatus = await _reminderService.getAuthorizationStatus();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _saving = false;
      notifyListenersSafely();
    }
  }
}