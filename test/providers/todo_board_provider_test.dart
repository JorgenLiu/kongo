import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/models/todo_board_view_options.dart';
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

  test('TodoBoardProvider loads empty board', () async {
    final provider = harness.dependencies.todoBoardProvider;

    await provider.load();

    expect(provider.error, isNull);
    expect(provider.initialized, isTrue);
    expect(provider.data?.groups, isEmpty);
  });

  test('TodoBoardProvider creates group and item then refreshes selection', () async {
    final provider = harness.dependencies.todoBoardProvider;

    await provider.createGroup(const TodoGroupDraft(title: '招聘推进'));

    final groupId = provider.data!.selectedGroup!.group.id;
    await provider.createItem(
      groupId,
      const TodoItemDraft(title: '筛第一轮候选人'),
    );

    expect(provider.error, isNull);
    expect(provider.data?.groups, hasLength(1));
    expect(provider.data?.selectedGroup?.rootItems, hasLength(1));
    expect(provider.data?.selectedGroup?.rootItems.first.item.title, '筛第一轮候选人');
  });

  test('TodoBoardProvider toggles completion status', () async {
    final provider = harness.dependencies.todoBoardProvider;

    await provider.createGroup(const TodoGroupDraft(title: '客户跟进'));
    final groupId = provider.data!.selectedGroup!.group.id;
    await provider.createItem(groupId, const TodoItemDraft(title: '给客户发会后纪要'));

    final item = provider.data!.selectedGroup!.rootItems.first.item;
    await provider.toggleItemCompleted(item, true);

    expect(provider.error, isNull);
    expect(provider.data?.selectedGroup?.rootItems.first.item.status, TodoItemStatus.completed);
  });

  test('TodoBoardProvider hides archived groups by default and can reveal them', () async {
    final provider = harness.dependencies.todoBoardProvider;

    await provider.createGroup(const TodoGroupDraft(title: '归档测试'));
    final groupId = provider.data!.selectedGroup!.group.id;

    await provider.archiveGroup(groupId);

    expect(provider.error, isNull);
    expect(provider.data?.groups, isEmpty);

    await provider.setGroupVisibility(TodoGroupVisibility.all);

    expect(provider.data?.groups, hasLength(1));
    expect(provider.data?.groups.first.group.archivedAt, isNotNull);
  });

  test('TodoBoardProvider filters linked items and sorts by updatedAt', () async {
    final provider = harness.dependencies.todoBoardProvider;
    final contacts = await harness.dependencies.contactService.getContacts();

    await provider.createGroup(const TodoGroupDraft(title: '筛选排序'));
    final groupId = provider.data!.selectedGroup!.group.id;

    await provider.createItem(
      groupId,
      const TodoItemDraft(
        title: '普通事项',
      ),
    );
    await provider.createItem(
      groupId,
      TodoItemDraft(
        title: '已关联事项',
        contactIds: [contacts.first.id],
      ),
    );

    await provider.setItemSort(TodoItemSort.updatedAt);
    await provider.setItemFilter(TodoItemFilter.linkedOnly);

    expect(provider.error, isNull);
    expect(provider.data?.selectedGroup?.rootItems, hasLength(1));
    expect(provider.data?.selectedGroup?.rootItems.first.item.title, '已关联事项');
  });

  test('TodoBoardProvider supports batch selection and completion', () async {
    final provider = harness.dependencies.todoBoardProvider;

    await provider.createGroup(const TodoGroupDraft(title: '批量完成 Provider'));
    final groupId = provider.data!.selectedGroup!.group.id;
    await provider.createItem(groupId, const TodoItemDraft(title: '事项 A'));
    await provider.createItem(groupId, const TodoItemDraft(title: '事项 B'));

    final rootItems = provider.data!.selectedGroup!.rootItems;
    provider.enterSelectionMode(rootItems.first.item.id);
    provider.toggleItemSelection(rootItems[1].item.id);

    expect(provider.selectionMode, isTrue);
    expect(provider.selectedItemIds, hasLength(2));

    await provider.batchSetSelectedItemsCompleted(true);

    final updatedItems = provider.data!.selectedGroup!.rootItems.map((node) => node.item).toList(growable: false);
    expect(provider.error, isNull);
    expect(updatedItems.every((item) => item.status == TodoItemStatus.completed), isTrue);
    expect(provider.selectedItemIds, hasLength(2));
  });

  test('TodoBoardProvider batch delete clears selection', () async {
    final provider = harness.dependencies.todoBoardProvider;

    await provider.createGroup(const TodoGroupDraft(title: '批量删除 Provider'));
    final groupId = provider.data!.selectedGroup!.group.id;
    await provider.createItem(groupId, const TodoItemDraft(title: '事项 A'));
    await provider.createItem(groupId, const TodoItemDraft(title: '事项 B'));
    await provider.createItem(groupId, const TodoItemDraft(title: '独立项'));

    final rootItems = provider.data!.selectedGroup!.rootItems;
    provider.enterSelectionMode(rootItems.first.item.id);
    provider.toggleItemSelection(rootItems[1].item.id);

    await provider.batchDeleteSelectedItems();

    expect(provider.error, isNull);
    expect(provider.selectionMode, isFalse);
    expect(provider.selectedItemIds, isEmpty);
    expect(provider.data?.selectedGroup?.rootItems, hasLength(1));
    expect(provider.data?.selectedGroup?.rootItems.first.item.title, '独立项');
  });
}