import 'package:flutter/foundation.dart';

import 'provider_error.dart';

abstract class BaseProvider extends ChangeNotifier {
  bool _loading = false;
  ProviderError? _error;
  bool _initialized = false;
  bool _disposed = false;

  bool get loading => _loading;
  ProviderError? get error => _error;
  bool get initialized => _initialized;

  @protected
  void markInitialized([bool value = true]) {
    _initialized = value;
  }

  void clearError() {
    if (_error == null) {
      return;
    }

    _error = null;
    _notifyListenersSafely();
  }

  @protected
  Future<void> execute(Future<void> Function() action) async {
    _loading = true;
    _error = null;
    _notifyListenersSafely();

    try {
      await action();
    } catch (error) {
      _error = ProviderError.fromObject(error);
    } finally {
      _loading = false;
      _notifyListenersSafely();
    }
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