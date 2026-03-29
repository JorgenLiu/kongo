import 'package:flutter_test/flutter_test.dart';
import 'package:kongo/models/contact_milestone.dart';
import 'package:kongo/models/contact_milestone_draft.dart';
import 'package:kongo/models/event_draft.dart';
import 'package:kongo/models/reminder_authorization_status.dart';
import 'package:kongo/models/reminder_interaction.dart';
import 'package:kongo/models/reminder_request.dart';
import 'package:kongo/models/reminder_snooze_action.dart';
import 'package:kongo/services/reminder_platform_gateway.dart';

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

  test('Event service schedules reminder after creating event', () async {
    final contacts = await harness.dependencies.contactService.getContacts();
    final now = DateTime.now().add(const Duration(days: 1));

    final event = await harness.dependencies.eventService.createEvent(
      EventDraft(
        title: '提醒测试会议',
        startAt: now,
        reminderEnabled: true,
        reminderAt: now.subtract(const Duration(minutes: 30)),
        participantIds: [contacts.first.id],
        participantRoles: {contacts.first.id: 'participant'},
      ),
    );

    final request = reminderGateway.scheduledById['kongo.event.${event.id}'];

    expect(request, isNotNull);
    expect(request!.title, '即将开始：提醒测试会议');
    expect(request.payload['targetType'], 'event');
    expect(request.payload['targetId'], event.id);
  });

  test('Event service cancels reminder after deleting event', () async {
    final events = await harness.dependencies.eventService.getEvents();
    final seeded = events.firstWhere((event) => event.startAt != null);
    final target = await harness.dependencies.eventService.updateEvent(
      seeded.copyWith(
        reminderEnabled: true,
        reminderAt: seeded.startAt!.subtract(const Duration(minutes: 15)),
      ),
    );

    await harness.dependencies.eventService.deleteEvent(target.id);

    expect(reminderGateway.cancelledIds, contains('kongo.event.${target.id}'));
    expect(reminderGateway.cancelledIds, contains('kongo.event_snooze.${target.id}'));
  });

  test('Milestone service schedules reminder after creating milestone', () async {
    final contacts = await harness.dependencies.contactService.getContacts();
    final contact = contacts.first;
    final tomorrow = DateTime.now().add(const Duration(days: 1));

    final milestone = await harness.dependencies.contactMilestoneService.createMilestone(
      contact.id,
      ContactMilestoneDraft(
        type: ContactMilestoneType.birthday,
        milestoneDate: DateTime(2020, tomorrow.month, tomorrow.day),
        reminderEnabled: true,
        reminderDaysBefore: 0,
      ),
    );

    final request = reminderGateway.scheduledById['kongo.milestone.${milestone.id}'];

    expect(request, isNotNull);
    expect(request!.title, contains(contact.name));
    expect(request.payload['targetType'], 'contactMilestone');
    expect(request.payload['targetId'], milestone.id);
  });

  test('Reminder service rebuilds only supported future reminders', () async {
    final contacts = await harness.dependencies.contactService.getContacts();
    final contact = contacts.first;
    final startAt = DateTime.now().add(const Duration(days: 2));

    await harness.dependencies.eventService.createEvent(
      EventDraft(
        title: '未来会议',
        startAt: startAt,
        reminderEnabled: true,
        reminderAt: startAt.subtract(const Duration(hours: 1)),
        participantIds: [contact.id],
        participantRoles: {contact.id: 'participant'},
      ),
    );
    await harness.dependencies.contactMilestoneService.createMilestone(
      contact.id,
      ContactMilestoneDraft(
        type: ContactMilestoneType.custom,
        label: '农历提醒',
        milestoneDate: DateTime(2020, startAt.month, startAt.day),
        isLunar: true,
        reminderEnabled: true,
        reminderDaysBefore: 0,
      ),
    );

    await harness.dependencies.reminderService.rebuildPendingReminders();

    expect(reminderGateway.cancelAllCount, greaterThanOrEqualTo(1));
    expect(
      reminderGateway.scheduledById.keys.any((id) => id.startsWith('kongo.event.')),
      isTrue,
    );
    expect(
      reminderGateway.scheduledById.keys.any((id) => id.startsWith('kongo.milestone.')),
      isFalse,
    );
  });

  test('Event service schedules post-event follow-up reminder for ended-event capture', () async {
    final contacts = await harness.dependencies.contactService.getContacts();
    final startAt = DateTime.now().add(const Duration(days: 1));
    final endAt = startAt.add(const Duration(hours: 1));

    final event = await harness.dependencies.eventService.createEvent(
      EventDraft(
        title: '会后补充测试会议',
        startAt: startAt,
        endAt: endAt,
        reminderEnabled: false,
        participantIds: [contacts.first.id],
        participantRoles: {contacts.first.id: 'participant'},
      ),
    );

    final request = reminderGateway.scheduledById['kongo.event_follow_up.${event.id}'];

    expect(request, isNotNull);
    expect(request!.title, '会后补充：会后补充测试会议');
    expect(request.payload['targetType'], 'eventFollowUp');
    expect(request.payload['targetId'], event.id);
  });

  test('Reminder service snoozes event reminder without mutating event', () async {
    final contacts = await harness.dependencies.contactService.getContacts();
    final startAt = DateTime.now().add(const Duration(days: 1));
    final reminderAt = startAt.subtract(const Duration(minutes: 20));

    final event = await harness.dependencies.eventService.createEvent(
      EventDraft(
        title: '稍后提醒会议',
        startAt: startAt,
        reminderEnabled: true,
        reminderAt: reminderAt,
        participantIds: [contacts.first.id],
        participantRoles: {contacts.first.id: 'participant'},
      ),
    );

    await harness.dependencies.reminderService.snoozeReminder(
      ReminderInteraction(
        targetType: ReminderInteractionTargetType.event,
        targetId: event.id,
        snoozeAction: ReminderSnoozeAction.tenMinutes,
      ),
    );

    final snoozedRequest = reminderGateway.scheduledById['kongo.event_snooze.${event.id}'];
    expect(snoozedRequest, isNotNull);

    final reloaded = await harness.dependencies.eventService.getEvent(event.id);
    expect(reloaded.reminderEnabled, isTrue);
    expect(
      reloaded.reminderAt,
      DateTime.fromMillisecondsSinceEpoch(reminderAt.millisecondsSinceEpoch),
    );
  });
}

class _FakeReminderPlatformGateway implements ReminderPlatformGateway {
  final Map<String, ReminderRequest> scheduledById = {};
  final List<String> cancelledIds = [];
  int cancelAllCount = 0;

  @override
  Future<void> cancel(String reminderId) async {
    cancelledIds.add(reminderId);
    scheduledById.remove(reminderId);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCount += 1;
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