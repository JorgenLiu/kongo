import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/models/event.dart';
import 'package:kongo/models/event_draft.dart';
import 'package:kongo/models/reminder_authorization_status.dart';
import 'package:kongo/models/reminder_interaction.dart';
import 'package:kongo/models/reminder_request.dart';
import 'package:kongo/models/reminder_settings.dart';
import 'package:kongo/models/reminder_snooze_action.dart';
import 'package:kongo/repositories/contact_milestone_repository.dart';
import 'package:kongo/repositories/contact_repository.dart';
import 'package:kongo/repositories/event_repository.dart';
import 'package:kongo/services/reminder_platform_gateway.dart';
import 'package:kongo/services/reminder_service.dart';

import '../test_helpers/test_app_harness.dart';

void main() {
  late _FakeReminderPlatformGateway reminderGateway;
  late TestAppHarness harness;

  setUp(() async {
    reminderGateway = _FakeReminderPlatformGateway();
    harness = await createTestAppHarnessWithOptions(
      reminderPlatformGateway: reminderGateway,
    );
  });

  tearDown(() async {
    await harness.dispose();
  });

  test('Snoozing an event reminder schedules a one-time temporary reminder', () async {
    final event = await _createEvent(harness);
    final service = _createReminderService(
      harness,
      reminderGateway,
      now: DateTime(2026, 3, 27, 14, 0),
    );

    await service.snoozeReminder(
      ReminderInteraction(
        targetType: ReminderInteractionTargetType.event,
        targetId: event.id,
        snoozeAction: ReminderSnoozeAction.tenMinutes,
      ),
    );

    final request = reminderGateway.scheduledById['kongo.event_snooze.${event.id}'];
    expect(request, isNotNull);
    expect(request!.fireAt, DateTime(2026, 3, 27, 14, 10));
    expect(request.payload['targetType'], 'event');
  });

  test('Snoozing a follow-up reminder schedules a one-time temporary reminder', () async {
    final event = await _createEvent(harness);
    final service = _createReminderService(
      harness,
      reminderGateway,
      now: DateTime(2026, 3, 27, 18, 30),
    );

    await service.snoozeReminder(
      ReminderInteraction(
        targetType: ReminderInteractionTargetType.eventFollowUp,
        targetId: event.id,
        snoozeAction: ReminderSnoozeAction.laterToday,
      ),
    );

    final request = reminderGateway.scheduledById['kongo.event_follow_up_snooze.${event.id}'];
    expect(request, isNotNull);
    expect(request!.fireAt, DateTime(2026, 3, 27, 20, 0));
    expect(request.payload['targetType'], 'eventFollowUp');
  });

  test('Snooze is ignored when reminder settings are globally disabled', () async {
    final event = await _createEvent(harness);
    final service = _createReminderService(
      harness,
      reminderGateway,
      now: DateTime(2026, 3, 27, 14, 0),
    );

    await harness.dependencies.settingsPreferencesStore.setReminderSettings(
      const ReminderSettings(remindersEnabled: false),
    );
    reminderGateway.scheduledById.clear();

    await service.snoozeReminder(
      ReminderInteraction(
        targetType: ReminderInteractionTargetType.event,
        targetId: event.id,
        snoozeAction: ReminderSnoozeAction.tenMinutes,
      ),
    );

    expect(reminderGateway.scheduledById, isEmpty);
  });
}

DefaultReminderService _createReminderService(
  TestAppHarness harness,
  ReminderPlatformGateway gateway, {
  required DateTime now,
}) {
  return DefaultReminderService(
    gateway,
    harness.dependencies.settingsPreferencesStore,
    SqliteEventRepository(harness.dependencies.databaseService),
    SqliteContactMilestoneRepository(harness.dependencies.databaseService),
    SqliteContactRepository(harness.dependencies.databaseService),
    nowProvider: () => now,
  );
}

Future<Event> _createEvent(TestAppHarness harness) async {
  final contacts = await harness.dependencies.contactService.getContacts();
  final startAt = DateTime(2026, 3, 28, 10, 0);
  return harness.dependencies.eventService.createEvent(
    EventDraft(
      title: '一次性稍后提醒测试',
      startAt: startAt,
      endAt: startAt.add(const Duration(hours: 1)),
      reminderEnabled: true,
      reminderAt: startAt.subtract(const Duration(minutes: 30)),
      participantIds: [contacts.first.id],
      participantRoles: {contacts.first.id: 'participant'},
    ),
  );
}

class _FakeReminderPlatformGateway implements ReminderPlatformGateway {
  final Map<String, ReminderRequest> scheduledById = {};

  @override
  Future<void> cancel(String reminderId) async {
    scheduledById.remove(reminderId);
  }

  @override
  Future<void> cancelAll() async {
    scheduledById.clear();
  }

  @override
  Future<ReminderAuthorizationStatus> getAuthorizationStatus() async {
    return ReminderAuthorizationStatus.authorized;
  }

  @override
  Future<ReminderAuthorizationStatus> requestAuthorization() async {
    return ReminderAuthorizationStatus.authorized;
  }

  @override
  Future<void> schedule(ReminderRequest request) async {
    scheduledById[request.id] = request;
  }
}