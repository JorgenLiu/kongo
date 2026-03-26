import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/models/todo_group_draft.dart';
import 'package:kongo/models/todo_item_draft.dart';
import 'package:kongo/providers/contact_detail_provider.dart';
import 'package:kongo/providers/event_detail_provider.dart';
import 'package:kongo/providers/events_list_provider.dart';

import '../test_helpers/test_app_harness.dart';

void main() {
  late TestAppHarness harness;

  setUp(() async {
    harness = await createTestAppHarness();
  });

  tearDown(() async {
    await harness.dispose();
  });

  test('ContactDetailProvider loads aggregated contact detail data', () async {
    final contacts = await harness.dependencies.contactService.getContacts();
    final target = contacts.firstWhere((contact) => contact.name == '张三');
    final group = await harness.dependencies.todoService.createGroup(
      const TodoGroupDraft(title: '联系人联动'),
    );
    await harness.dependencies.todoService.createItem(
      group.id,
      TodoItemDraft(title: '回访张三', contactIds: [target.id]),
    );

    final provider = ContactDetailProvider(
      harness.dependencies.contactReadService,
      harness.dependencies.todoReadService,
      target.id,
    );

    await provider.load();

    expect(provider.error, isNull);
    expect(provider.initialized, isTrue);
    expect(provider.data?.contact.id, target.id);
    expect(provider.data?.events.length, 2);
    expect(provider.linkedTodoItems, hasLength(1));
    expect(provider.linkedTodoItems.first.item.title, '回访张三');
  });

  test('EventsListProvider loads aggregated event list data', () async {
    final contacts = await harness.dependencies.contactService.getContacts();
    final target = contacts.firstWhere((contact) => contact.name == '张三');
    final provider = EventsListProvider(
      harness.dependencies.eventReadService,
      harness.dependencies.eventService,
      contactId: target.id,
    );

    await provider.load();

    expect(provider.error, isNull);
    expect(provider.initialized, isTrue);
    expect(provider.data?.contact?.id, target.id);
    expect(provider.data?.items.length, 2);
  });

  test('EventsListProvider supports loading all events without contact filter', () async {
    final provider = EventsListProvider(
      harness.dependencies.eventReadService,
      harness.dependencies.eventService,
    );

    await provider.load();

    expect(provider.error, isNull);
    expect(provider.initialized, isTrue);
    expect(provider.data?.contact, isNull);
    expect(provider.data?.items.length, 2);
  });

  test('EventsListProvider supports keyword search across event content', () async {
    final provider = EventsListProvider(
      harness.dependencies.eventReadService,
      harness.dependencies.eventService,
    );

    await provider.searchByKeyword('演示');

    expect(provider.error, isNull);
    expect(provider.initialized, isTrue);
    expect(provider.keyword, '演示');
    expect(provider.data?.items.length, 1);
    expect(provider.data?.items.first.event.title, '产品演示预约');
  });

  test('EventsListProvider supports filtering by event type', () async {
    final provider = EventsListProvider(
      harness.dependencies.eventReadService,
      harness.dependencies.eventService,
    );

    await provider.load();
    await provider.filterByEventType('evt-followup');

    expect(provider.error, isNull);
    expect(provider.selectedEventTypeId, 'evt-followup');
    expect(provider.data?.items.length, 1);
    expect(provider.data?.items.first.event.title, '产品演示预约');
  });

  test('EventDetailProvider loads aggregated event detail data', () async {
    final events = await harness.dependencies.eventService.getEvents();
    final target = events.firstWhere((event) => event.title == '年度合作复盘');
    final group = await harness.dependencies.todoService.createGroup(
      const TodoGroupDraft(title: '事件联动'),
    );
    await harness.dependencies.todoService.createItem(
      group.id,
      TodoItemDraft(title: '整理复盘纪要', eventIds: [target.id]),
    );

    final provider = EventDetailProvider(
      harness.dependencies.eventReadService,
      harness.dependencies.todoReadService,
      target.id,
    );

    await provider.load();

    expect(provider.error, isNull);
    expect(provider.initialized, isTrue);
    expect(provider.data?.event.id, target.id);
    expect(provider.data?.participants.length, 2);
    expect(provider.data?.attachments, isEmpty);
    expect(provider.linkedTodoItems, hasLength(1));
    expect(provider.linkedTodoItems.first.item.title, '整理复盘纪要');
  });
}