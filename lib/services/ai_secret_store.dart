import 'package:flutter/services.dart';

import '../exceptions/app_exception.dart';

abstract class AiSecretStore {
  Future<String?> loadApiKey();
  Future<void> saveApiKey(String value);
  Future<void> clearApiKey();
  Future<bool> isSupported();
}

class UnsupportedAiSecretStore implements AiSecretStore {
  @override
  Future<void> clearApiKey() async {}

  @override
  Future<bool> isSupported() async {
    return false;
  }

  @override
  Future<String?> loadApiKey() async {
    return null;
  }

  @override
  Future<void> saveApiKey(String value) async {}
}

class MethodChannelAiSecretStore implements AiSecretStore {
  static const String channelName = 'kongo/ai_secrets';

  final MethodChannel _channel;

  MethodChannelAiSecretStore({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName);

  @override
  Future<String?> loadApiKey() {
    return _invoke<String>('loadApiKey');
  }

  @override
  Future<void> saveApiKey(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return clearApiKey();
    }
    return _invoke<void>('saveApiKey', {'value': trimmedValue});
  }

  @override
  Future<void> clearApiKey() {
    return _invoke<void>('clearApiKey');
  }

  @override
  Future<bool> isSupported() async {
    return await _invoke<bool>('isSupported') ?? false;
  }

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      throw AiException(
        message: error.message ?? 'AI 密钥安全存储调用失败',
        code: error.code,
      );
    } catch (error) {
      throw AiException(
        message: 'AI 密钥安全存储调用失败：$error',
        code: 'ai_secret_store_failed',
      );
    }
  }
}