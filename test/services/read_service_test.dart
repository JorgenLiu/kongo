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

  test('Contact read service returns aggregated detail for seeded contact', () async {
    final contacts = await harness.dependencies.contactService.getContacts();
    final target = contacts.firstWhere((contact) => contact.name == '张三');

    final result = await harness.dependencies.contactReadService.getContactDetail(target.id);

    expect(result.contact.id, target.id);
    expect(result.events, hasLength(2));
    expect(result.attachments, isEmpty);
    expect(
      result.events.every((event) => result.eventTypeNames.containsKey(event.eventTypeId)),
      isTrue,
    );
  });

  test('Event read service returns event list items with participant names', () async {
    final contacts = await harness.dependencies.contactService.getContacts();
    final target = contacts.firstWhere((contact) => contact.name == '张三');

    final result = await harness.dependencies.eventReadService.getEventsList(
      contactId: target.id,
    );

    expect(result.contact?.id, target.id);
    expect(result.items, hasLength(2));
    expect(result.items.every((item) => item.participantNames.isNotEmpty), isTrue);
    expect(
      result.items.any((item) => item.participantNames.contains('李四')),
      isTrue,
    );
  });

  test('Event read service returns all seeded events when contact filter is omitted', () async {
    final events = await harness.dependencies.eventService.getEvents();

    final result = await harness.dependencies.eventReadService.getEventsList();

    expect(result.contact, isNull);
    expect(result.items.length, events.length);
    expect(result.items.map((item) => item.event.id).toSet(), events.map((event) => event.id).toSet());
  });

  test('Event read service returns event detail aggregate', () async {
    final events = await harness.dependencies.eventService.getEvents();
    final target = events.firstWhere((event) => event.title == '年度合作复盘');

    final result = await harness.dependencies.eventReadService.getEventDetail(target.id);

    expect(result.event.id, target.id);
    expect(result.eventTypeName, isNotNull);
    expect(result.createdByContact?.name, '张三');
    expect(result.participants.map((contact) => contact.name), containsAll(['张三', '李四']));
    expect(
      result.participantEntries.any(
        (entry) => entry.contact.name == '张三' && entry.role == 'initiator',
      ),
      isTrue,
    );
    expect(
      result.participantEntries.any(
        (entry) => entry.contact.name == '李四' && entry.role == 'investor',
      ),
      isTrue,
    );
    expect(result.attachments, isEmpty);
  });

  test('Batch service queries group participants and attachments by owner ids', () async {
    final events = await harness.dependencies.eventService.getEvents();
    final eventIds = events.map((event) => event.id).toList();

    final participantsByEventId = await harness.dependencies.eventService
        .getParticipantsByEventIds(eventIds);

    final completedEvent = events.firstWhere((event) => event.title == '年度合作复盘');
    final plannedEvent = events.firstWhere((event) => event.title == '产品演示预约');

    expect(participantsByEventId[completedEvent.id]?.map((item) => item.name), containsAll(['张三', '李四']));
    expect(participantsByEventId[plannedEvent.id]?.map((item) => item.name), containsAll(['张三', '王五']));
    final eventAttachmentsByEventId = await harness.dependencies.attachmentService
        .getEventAttachmentsByEventIds(eventIds);

    expect(eventAttachmentsByEventId[completedEvent.id], isEmpty);
    expect(eventAttachmentsByEventId[plannedEvent.id], isEmpty);
  });
}