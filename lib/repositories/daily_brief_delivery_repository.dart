import 'dart:convert';

import '../models/daily_brief_delivery_status.dart';
import '../utils/display_formatters.dart';
import '../services/settings_preferences_store.dart';

abstract class DailyBriefDeliveryRepository {
  Future<DailyBriefDeliveryStatus?> getStatus({
    required String dateKey,
    required DailyBriefDeliveryChannel channel,
  });

  Future<void> saveStatus(DailyBriefDeliveryStatus status);

  Future<void> pruneOldStatuses({
    Duration maxAge,
    DateTime? now,
  });
}

class SettingsDailyBriefDeliveryRepository implements DailyBriefDeliveryRepository {
  static const String _storageKey = 'dailyBriefDeliveryStatuses';

  final SettingsPreferencesStore _preferencesStore;

  SettingsDailyBriefDeliveryRepository(this._preferencesStore);

  @override
  Future<DailyBriefDeliveryStatus?> getStatus({
    required String dateKey,
    required DailyBriefDeliveryChannel channel,
  }) async {
    final payload = await _loadPayload();
    final entry = payload[_storageEntryKey(dateKey, channel)];
    if (entry is! Map<String, dynamic>) {
      return null;
    }

    try {
      return DailyBriefDeliveryStatus.fromJson(entry);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> saveStatus(DailyBriefDeliveryStatus status) async {
    final payload = await _loadPayload();
    payload[_storageEntryKey(status.dateKey, status.channel)] = status.toJson();
    _removeExpiredEntries(
      payload,
      now: status.deliveredAt,
      maxAge: const Duration(days: 45),
    );
    await _writePayload(payload);
  }

  @override
  Future<void> pruneOldStatuses({
    Duration maxAge = const Duration(days: 45),
    DateTime? now,
  }) async {
    final payload = await _loadPayload();
    final changed = _removeExpiredEntries(
      payload,
      now: now ?? DateTime.now(),
      maxAge: maxAge,
    );
    if (!changed) {
      return;
    }

    if (payload.isEmpty) {
      await _preferencesStore.removeKey(_storageKey);
      return;
    }

    await _writePayload(payload);
  }

  Future<Map<String, dynamic>> _loadPayload() async {
    final raw = await _preferencesStore.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    return <String, dynamic>{};
  }

  Future<void> _writePayload(Map<String, dynamic> payload) {
    return _preferencesStore.setString(_storageKey, jsonEncode(payload));
  }

  bool _removeExpiredEntries(
    Map<String, dynamic> payload, {
    required DateTime now,
    required Duration maxAge,
  }) {
    final cutoffKey = formatIsoDate(now.subtract(maxAge));
    final keysToRemove = <String>[];

    for (final entry in payload.entries) {
      final value = entry.value;
      if (value is! Map<String, dynamic>) {
        keysToRemove.add(entry.key);
        continue;
      }

      try {
        final status = DailyBriefDeliveryStatus.fromJson(value);
        if (status.dateKey.compareTo(cutoffKey) < 0) {
          keysToRemove.add(entry.key);
        }
      } on FormatException {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      payload.remove(key);
    }

    return keysToRemove.isNotEmpty;
  }

  String _storageEntryKey(String dateKey, DailyBriefDeliveryChannel channel) {
    return '${channel.value}|$dateKey';
  }
}