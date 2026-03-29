import 'package:flutter_test/flutter_test.dart';

import '../test_helpers/test_app_harness.dart';

void main() {
  late TestAppHarness harness;

  setUp(() async {
    harness = await createTestAppHarness();
  });

  tearDown(() async {
    await harness.dispose();
  });

  test('Contact service returns related events for seeded contacts', () async {
    final contacts = await harness.dependencies.contactService.getContacts();

    final relatedEventCounts = <String, int>{};
    for (final contact in contacts) {
      final events = await harness.dependencies.contactService.getContactEvents(contact.id);
      relatedEventCounts[contact.id] = events.length;
    }

    expect(relatedEventCounts.values.any((count) => count > 0), isTrue);
  });

  test('Event detail dependencies return participants summaries and attachments', () async {
    final events = await harness.dependencies.eventService.getEvents();
    expect(events, isNotEmpty);

    final event = events.first;
    final participants = await harness.dependencies.eventService.getParticipants(event.id);
    final summaries = await harness.dependencies.summaryService.getSummaries();
    final attachments = await harness.dependencies.attachmentService.getEventAttachments(event.id);

    expect(participants, isNotEmpty);
    expect(summaries, isNotEmpty);
    expect(attachments, isA<List>());
  });

  test('Event service persists reminder fields', () async {
    final events = await harness.dependencies.eventService.getEvents();
    final target = events.firstWhere((event) => event.startAt != null);
    final reminderAt = target.startAt!.subtract(const Duration(minutes: 45));

    final updated = await harness.dependencies.eventService.updateEvent(
      target.copyWith(
        reminderEnabled: true,
        reminderAt: reminderAt,
      ),
    );

    expect(updated.reminderEnabled, isTrue);
    expect(updated.reminderAt, reminderAt);

    final reloaded = await harness.dependencies.eventService.getEvent(updated.id);
    expect(reloaded.reminderEnabled, isTrue);
    expect(reloaded.reminderAt, reminderAt);
  });
}