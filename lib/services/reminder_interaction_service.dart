import 'dart:async';

import 'package:flutter/services.dart';

import '../models/reminder_interaction.dart';

abstract class ReminderInteractionService {
  Stream<ReminderInteraction> get interactions;
  Future<ReminderInteraction?> consumePendingInteraction();
  Future<void> dispose();
}

class UnsupportedReminderInteractionService implements ReminderInteractionService {
  @override
  Stream<ReminderInteraction> get interactions => const Stream.empty();

  @override
  Future<ReminderInteraction?> consumePendingInteraction() async => null;

  @override
  Future<void> dispose() async {}
}

class MethodChannelReminderInteractionService implements ReminderInteractionService {
  static const MethodChannel _channel = MethodChannel('kongo/reminders');

  final StreamController<ReminderInteraction> _controller =
      StreamController<ReminderInteraction>.broadcast();

  String? _lastDeliveredFingerprint;
  DateTime? _lastDeliveredAt;
  bool _disposed = false;

  MethodChannelReminderInteractionService() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  @override
  Stream<ReminderInteraction> get interactions => _controller.stream;

  @override
  Future<ReminderInteraction?> consumePendingInteraction() async {
    try {
      final rawPayload = await _channel.invokeMethod<Object?>('consumePendingInteraction');
      final interaction = ReminderInteraction.fromMap(rawPayload as Map<Object?, Object?>?);
      if (interaction == null || _isDuplicate(interaction)) {
        return null;
      }

      _markDelivered(interaction);
      return interaction;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;
    _channel.setMethodCallHandler(null);
    await _controller.close();
  }

  Future<Object?> _handleMethodCall(MethodCall call) async {
    if (call.method != 'onReminderInteraction') {
      return null;
    }

    final interaction = ReminderInteraction.fromMap(call.arguments as Map<Object?, Object?>?);
    if (interaction == null || _disposed || _isDuplicate(interaction)) {
      return null;
    }

    _markDelivered(interaction);
    _controller.add(interaction);
    return null;
  }

  bool _isDuplicate(ReminderInteraction interaction) {
    final lastDeliveredAt = _lastDeliveredAt;
    if (_lastDeliveredFingerprint != interaction.fingerprint || lastDeliveredAt == null) {
      return false;
    }

    return DateTime.now().difference(lastDeliveredAt) <= const Duration(seconds: 2);
  }

  void _markDelivered(ReminderInteraction interaction) {
    _lastDeliveredFingerprint = interaction.fingerprint;
    _lastDeliveredAt = DateTime.now();
  }
}