import 'package:flutter/services.dart';

import '../exceptions/app_exception.dart';
import '../models/reminder_authorization_status.dart';
import '../models/reminder_request.dart';

abstract class ReminderPlatformGateway {
  Future<ReminderAuthorizationStatus> getAuthorizationStatus();
  Future<ReminderAuthorizationStatus> requestAuthorization();
  Future<void> schedule(ReminderRequest request);
  Future<void> cancel(String reminderId);
  Future<void> cancelAll();
}

class UnsupportedReminderPlatformGateway implements ReminderPlatformGateway {
  @override
  Future<void> cancel(String reminderId) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<ReminderAuthorizationStatus> getAuthorizationStatus() async {
    return ReminderAuthorizationStatus.unsupported;
  }

  @override
  Future<ReminderAuthorizationStatus> requestAuthorization() async {
    return ReminderAuthorizationStatus.unsupported;
  }

  @override
  Future<void> schedule(ReminderRequest request) async {}
}

class MethodChannelReminderPlatformGateway implements ReminderPlatformGateway {
  static const MethodChannel _channel = MethodChannel('kongo/reminders');

  @override
  Future<ReminderAuthorizationStatus> getAuthorizationStatus() async {
    final rawStatus = await _invoke<String>('getAuthorizationStatus');
    return _mapStatus(rawStatus);
  }

  @override
  Future<ReminderAuthorizationStatus> requestAuthorization() async {
    final rawStatus = await _invoke<String>('requestAuthorization');
    return _mapStatus(rawStatus);
  }

  @override
  Future<void> schedule(ReminderRequest request) {
    return _invoke<void>('schedule', request.toMap());
  }

  @override
  Future<void> cancel(String reminderId) {
    return _invoke<void>('cancel', {'id': reminderId});
  }

  @override
  Future<void> cancelAll() {
    return _invoke<void>('cancelAll');
  }

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      throw ReminderException(
        message: error.message ?? '系统提醒调用失败',
        code: error.code,
      );
    } catch (error) {
      throw ReminderException(
        message: '系统提醒调用失败：$error',
        code: 'reminder_platform_failed',
      );
    }
  }

  ReminderAuthorizationStatus _mapStatus(String? rawStatus) {
    switch (rawStatus) {
      case 'authorized':
        return ReminderAuthorizationStatus.authorized;
      case 'denied':
        return ReminderAuthorizationStatus.denied;
      case 'notDetermined':
        return ReminderAuthorizationStatus.notDetermined;
      case 'unsupported':
      default:
        return ReminderAuthorizationStatus.unsupported;
    }
  }
}