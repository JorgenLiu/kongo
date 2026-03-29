import 'package:flutter/material.dart';

import '../services/settings_preferences_store.dart';
import 'base_provider.dart';

/// 全局主题模式管理。
class ThemeNotifier extends BaseProvider {
  final SettingsPreferencesStore _settingsPreferencesStore;
  late final Future<void> _initialLoadFuture;

  ThemeMode _mode = ThemeMode.system;

  ThemeNotifier(this._settingsPreferencesStore) {
    _initialLoadFuture = _loadMode();
  }

  ThemeMode get mode => _mode;
  Future<void> get ready => _initialLoadFuture;

  Future<void> setMode(ThemeMode mode) async {
    await _initialLoadFuture;

    if (_mode == mode) return;

    final previousMode = _mode;
    _mode = mode;
    notifyListenersSafely();

    try {
      await _settingsPreferencesStore.setThemeMode(mode);
    } catch (_) {
      if (isDisposed) {
        return;
      }
      _mode = previousMode;
      notifyListenersSafely();
      rethrow;
    }
  }

  Future<void> _loadMode() async {
    try {
      final persistedMode = await _settingsPreferencesStore.getThemeMode();
      if (isDisposed || persistedMode == _mode) {
        return;
      }
      _mode = persistedMode;
      notifyListenersSafely();
    } catch (_) {}
  }
}
