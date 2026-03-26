import 'package:flutter/material.dart';

import '../services/settings_preferences_store.dart';

/// 全局主题模式管理。
class ThemeNotifier extends ChangeNotifier {
  final SettingsPreferencesStore _settingsPreferencesStore;
  late final Future<void> _initialLoadFuture;

  ThemeMode _mode = ThemeMode.system;
  bool _disposed = false;

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
    _notifyListenersSafely();

    try {
      await _settingsPreferencesStore.setThemeMode(mode);
    } catch (_) {
      if (_disposed) {
        return;
      }
      _mode = previousMode;
      _notifyListenersSafely();
      rethrow;
    }
  }

  Future<void> _loadMode() async {
    try {
      final persistedMode = await _settingsPreferencesStore.getThemeMode();
      if (_disposed || persistedMode == _mode) {
        return;
      }
      _mode = persistedMode;
      _notifyListenersSafely();
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notifyListenersSafely() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }
}
