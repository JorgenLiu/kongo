import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/calendar_time_node_settings.dart';
import '../repositories/app_preference_repository.dart';

abstract class SettingsPreferencesStore {
  Future<ThemeMode> getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);
  Future<CalendarTimeNodeSettings> getCalendarTimeNodeSettings();
  Future<void> setCalendarTimeNodeSettings(CalendarTimeNodeSettings settings);
}

class JsonSettingsPreferencesStore implements SettingsPreferencesStore {
  static const String _fileName = 'settings_preferences.json';
  static const String _themeModeKey = 'themeMode';
  static const String _calendarTimeNodesKey = 'calendarTimeNodes';
  static const String _contactMilestonesKey = 'contactMilestonesEnabled';
  static const String _publicHolidaysKey = 'publicHolidaysEnabled';
  static const String _marketingCampaignsKey = 'marketingCampaignsEnabled';

  static const String _legacyContactMilestonesKey =
      'calendar_time_nodes.contact_milestone.enabled';
  static const String _legacyPublicHolidaysKey =
      'calendar_time_nodes.public_holiday.enabled';
  static const String _legacyMarketingCampaignsKey =
      'calendar_time_nodes.marketing_campaign.enabled';

  final Future<Directory> Function()? _settingsDirectoryResolver;
  final AppPreferenceRepository? _legacyPreferenceRepository;

  JsonSettingsPreferencesStore({
    Future<Directory> Function()? settingsDirectoryResolver,
    AppPreferenceRepository? legacyPreferenceRepository,
  }) : _settingsDirectoryResolver = settingsDirectoryResolver,
       _legacyPreferenceRepository = legacyPreferenceRepository;

  @override
  Future<ThemeMode> getThemeMode() async {
    final payload = await _loadPayload();
    return _decodeThemeMode(payload[_themeModeKey] as String?);
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    final payload = await _loadPayload();
    payload[_themeModeKey] = _encodeThemeMode(mode);
    await _writePayload(payload);
  }

  @override
  Future<CalendarTimeNodeSettings> getCalendarTimeNodeSettings() async {
    final payload = await _loadPayload();
    final rawCalendarSettings = payload[_calendarTimeNodesKey];
    if (rawCalendarSettings is! Map<String, dynamic>) {
      return const CalendarTimeNodeSettings();
    }

    return CalendarTimeNodeSettings(
      contactMilestonesEnabled: _readBool(
        rawCalendarSettings[_contactMilestonesKey],
        fallback: true,
      ),
      publicHolidaysEnabled: _readBool(
        rawCalendarSettings[_publicHolidaysKey],
        fallback: true,
      ),
      marketingCampaignsEnabled: _readBool(
        rawCalendarSettings[_marketingCampaignsKey],
        fallback: true,
      ),
    );
  }

  @override
  Future<void> setCalendarTimeNodeSettings(CalendarTimeNodeSettings settings) async {
    final payload = await _loadPayload();
    payload[_calendarTimeNodesKey] = {
      _contactMilestonesKey: settings.contactMilestonesEnabled,
      _publicHolidaysKey: settings.publicHolidaysEnabled,
      _marketingCampaignsKey: settings.marketingCampaignsEnabled,
    };
    await _writePayload(payload);
  }

  Future<Map<String, dynamic>> _loadPayload() async {
    final file = await _resolveFile();
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        final decoded = jsonDecode(content);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {}
    }

    return _loadLegacyPayload();
  }

  Future<Map<String, dynamic>> _loadLegacyPayload() async {
    final values = await _legacyPreferenceRepository?.getStrings(const [
          _legacyContactMilestonesKey,
          _legacyPublicHolidaysKey,
          _legacyMarketingCampaignsKey,
        ]) ??
        const <String, String>{};

    return {
      _themeModeKey: _encodeThemeMode(ThemeMode.system),
      _calendarTimeNodesKey: {
        _contactMilestonesKey: _readBool(
          values[_legacyContactMilestonesKey],
          fallback: true,
        ),
        _publicHolidaysKey: _readBool(
          values[_legacyPublicHolidaysKey],
          fallback: true,
        ),
        _marketingCampaignsKey: _readBool(
          values[_legacyMarketingCampaignsKey],
          fallback: true,
        ),
      },
    };
  }

  Future<void> _writePayload(Map<String, dynamic> payload) async {
    final file = await _resolveFile();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
  }

  Future<File> _resolveFile() async {
    final directory = await (_settingsDirectoryResolver?.call() ?? _defaultSettingsDirectory());
    await directory.create(recursive: true);
    return File(path.join(directory.path, _fileName));
  }

  Future<Directory> _defaultSettingsDirectory() async {
    final baseDirectory = await getApplicationSupportDirectory();
    return Directory(path.join(baseDirectory.path, 'kongo'));
  }

  ThemeMode _decodeThemeMode(String? rawValue) {
    switch (rawValue) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _encodeThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  bool _readBool(Object? rawValue, {required bool fallback}) {
    if (rawValue is bool) {
      return rawValue;
    }

    if (rawValue is String) {
      return rawValue == '1' || rawValue.toLowerCase() == 'true';
    }

    return fallback;
  }
}