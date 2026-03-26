import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/models/todo_group_draft.dart';
import 'package:kongo/models/todo_item.dart';
import 'package:kongo/models/todo_item_draft.dart';

import '../test_helpers/test_app_harness.dart';

void main() {
  late TestAppHarness harness;

  setUp(() async {
    harness = await createTestAppHarness();
  });

  tearDown(() async {
    await harness.dispose();
  });

  test('Todo read service returns empty board by default', () async {
    final board = await harness.dependencies.todoReadService.loadBoard();

    expect(board.groups, isEmpty);
    expect(board.selectedGroup, isNull);
    expect(board.availableContacts, isNotEmpty);
    expect(board.availableEvents, isNotEmpty);
  });

  test('Todo service creates group and item with contact/event links', () async {
    final contacts = await harness.dependencies.contactService.getContacts();
    final events = await harness.dependencies.eventService.getEvents();

    final group = await harness.dependencies.todoService.createGroup(
      const TodoGroupDraft(title: '本周推进', description: '推进重点事项'),
    );

    await harness.dependencies.todoService.createItem(
      group.id,
      TodoItemDraft(
        title: '确认报价方案',
        notes: '先和张三对齐，再同步客户。',
        contactIds: [contacts.first.id, contacts[1].id],
        eventIds: [events.first.id],
      ),
    );

    final board = await harness.dependencies.todoReadService.loadBoard(selectedGroupId: group.id);

    expect(board.groups, hasLength(1));
    expect(board.selectedGroup, isNotNull);
    expect(board.selectedGroup?.rootItems, hasLength(1));
    final itemNode = board.selectedGroup!.rootItems.first;
    expect(itemNode.item.title, '确认报价方案');
    expect(itemNode.contacts.map((item) => item.name), containsAll([contacts.first.name, contacts[1].name]));
    expect(itemNode.events.map((item) => item.title), contains(events.first.title));
  });

  test('Todo service supports item completion toggle', () async {
    final group = await harness.dependencies.todoService.createGroup(
      const TodoGroupDraft(title: '渠道合作'),
    );
    final item = await harness.dependencies.todoService.createItem(
      group.id,
      const TodoItemDraft(title: '推进合作意向'),
    );

    final completed = await harness.dependencies.todoService.setItemCompleted(item.id, true);
    expect(completed.status, TodoItemStatus.completed);
    expect(completed.completedAt, isNotNull);

    final board = await harness.dependencies.todoReadService.loadBoard(selectedGroupId: group.id);
    expect(board.selectedGroup?.rootItems, hasLength(1));
    expect(board.selectedGroup?.rootItems.first.item.status, TodoItemStatus.completed);
  });

  test('Todo service archives and restores group', () async {
    final group = await harness.dependencies.todoService.createGroup(
      const TodoGroupDraft(title: '归档恢复测试'),
    );

    final archived = await harness.dependencies.todoService.archiveGroup(group.id);
    expect(archived.archivedAt, isNotNull);

    final restored = await harness.dependencies.todoService.restoreGroup(group.id);
    expect(restored.archivedAt, isNull);
  });

  test('Todo service batch completes items with deduplicated ids', () async {
    final group = await harness.dependencies.todoService.createGroup(
      const TodoGroupDraft(title: '批量完成测试'),
    );
    final first = await harness.dependencies.todoService.createItem(
      group.id,
      const TodoItemDraft(title: '整理线索'),
    );
    final second = await harness.dependencies.todoService.createItem(
      group.id,
      const TodoItemDraft(title: '发送回访邮件'),
    );

    await harness.dependencies.todoService.setItemsCompleted(
      [first.id, first.id, second.id],
      true,
    );

    final board = await harness.dependencies.todoReadService.loadBoard(selectedGroupId: group.id);
    final items = board.selectedGroup!.rootItems.map((node) => node.item).toList(growable: false);
    expect(items, hasLength(2));
    expect(items.every((item) => item.status == TodoItemStatus.completed), isTrue);
    expect(items.every((item) => item.completedAt != null), isTrue);
  });

  test('Todo service batch delete removes all selected items', () async {
    final group = await harness.dependencies.todoService.createGroup(
      const TodoGroupDraft(title: '批量删除测试'),
    );
    final first = await harness.dependencies.todoService.createItem(
      group.id,
      const TodoItemDraft(title: '准备方案初稿'),
    );
    final second = await harness.dependencies.todoService.createItem(
      group.id,
      const TodoItemDraft(title: '补充报价明细'),
    );
    await harness.dependencies.todoService.createItem(
      group.id,
      const TodoItemDraft(title: '保留项'),
    );

    await harness.dependencies.todoService.deleteItems([first.id, second.id]);

    final board = await harness.dependencies.todoReadService.loadBoard(selectedGroupId: group.id);
    expect(board.selectedGroup?.rootItems, hasLength(1));
    expect(board.selectedGroup?.rootItems.first.item.title, '保留项');
  });
}