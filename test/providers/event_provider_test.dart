import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/exceptions/app_exception.dart';
import 'package:kongo/models/event_draft.dart';

import '../test_helpers/test_app_harness.dart';

void main() {
  late TestAppHarness harness;

  setUp(() async {
    harness = await createTestAppHarness();
  });

  tearDown(() async {
    await harness.dispose();
  });

  test('EventProvider loads form options from sqlite', () async {
    final provider = harness.dependencies.eventProvider;

    await provider.loadFormOptions();

    expect(provider.error, isNull);
    expect(provider.availableContacts.length, 7);
    expect(provider.eventTypes, isNotEmpty);
  });

  test('EventProvider creates an event with participants', () async {
    final provider = harness.dependencies.eventProvider;
    final contacts = await harness.dependencies.contactService.getContacts();

    await provider.createEvent(
      EventDraft(
        title: '客户复访安排',
        eventTypeId: 'evt-followup',
        createdByContactId: contacts.first.id,
        participantIds: [contacts.first.id, contacts[1].id],
      ),
    );

    expect(provider.error, isNull);
    expect(provider.currentEvent, isNotNull);
    expect(provider.currentEvent?.title, '客户复访安排');
    expect(provider.participants.map((item) => item.id), containsAll([contacts.first.id, contacts[1].id]));
  });

  test('EventProvider updates event fields and participant list', () async {
    final provider = harness.dependencies.eventProvider;
    final contacts = await harness.dependencies.contactService.getContacts();
    final created = await harness.dependencies.eventService.createEvent(
      EventDraft(
        title: '待更新事件',
        eventTypeId: 'evt-meeting',
        createdByContactId: contacts.first.id,
        participantIds: [contacts.first.id, contacts[1].id],
      ),
    );

    await provider.updateEvent(
      created.copyWith(
        title: '已更新事件',
        location: '线上会议',
      ),
      [contacts.first.id, contacts[2].id],
    );

    expect(provider.error, isNull);
    expect(provider.currentEvent?.title, '已更新事件');
    expect(provider.currentEvent?.location, '线上会议');
    expect(provider.participants.map((item) => item.id), containsAll([contacts.first.id, contacts[2].id]));
    expect(provider.participants.map((item) => item.id), isNot(contains(contacts[1].id)));
  });

  test('EventProvider deletes current event and clears cached detail', () async {
    final provider = harness.dependencies.eventProvider;
    final contacts = await harness.dependencies.contactService.getContacts();
    await provider.createEvent(
      EventDraft(
        title: '删除目标事件',
        participantIds: [contacts.first.id],
        createdByContactId: contacts.first.id,
      ),
    );

    final eventId = provider.currentEvent!.id;
    await provider.deleteEvent(eventId);

    expect(provider.error, isNull);
    expect(provider.currentEvent, isNull);
    expect(provider.participants, isEmpty);
    await expectLater(
      harness.dependencies.eventService.getEvent(eventId),
      throwsA(isA<AppException>()),
    );
  });
}