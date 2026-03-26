import 'package:flutter/services.dart';

/// 平台窗口外观服务抽象，隔离 MethodChannel 调用
abstract class PlatformWindowChromeService {
  Future<void> updateWindowChrome({
    required String title,
    required int backgroundColor,
    required bool dark,
  });
}

class DefaultPlatformWindowChromeService implements PlatformWindowChromeService {
  static const MethodChannel _channel = MethodChannel('kongo/window_chrome');

  const DefaultPlatformWindowChromeService();

  @override
  Future<void> updateWindowChrome({
    required String title,
    required int backgroundColor,
    required bool dark,
  }) async {
    try {
      await _channel.invokeMethod<void>('updateWindowChrome', {
        'title': title,
        'backgroundColor': backgroundColor,
        'dark': dark,
      });
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}
