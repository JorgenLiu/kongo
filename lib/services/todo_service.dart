import 'package:uuid/uuid.dart';

import '../exceptions/app_exception.dart';
import '../models/todo_group.dart';
import '../models/todo_group_draft.dart';
import '../models/todo_item.dart';
import '../models/todo_item_draft.dart';
import '../repositories/contact_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/todo_group_repository.dart';
import '../repositories/todo_item_repository.dart';
import '../utils/text_normalize.dart';

abstract class TodoService {
  Future<TodoGroup> createGroup(TodoGroupDraft draft);
  Future<TodoGroup> updateGroup(TodoGroup group);
  Future<TodoGroup> archiveGroup(String groupId);
  Future<TodoGroup> restoreGroup(String groupId);
  Future<void> deleteGroup(String groupId);
  Future<TodoItem> createItem(String groupId, TodoItemDraft draft);
  Future<TodoItem> updateItem(
    TodoItem item, {
    List<String> contactIds = const [],
    List<String> eventIds = const [],
  });
  Future<void> deleteItem(String itemId);
  Future<void> deleteItems(List<String> itemIds);
  Future<TodoItem> setItemCompleted(String itemId, bool completed);
  Future<void> setItemsCompleted(List<String> itemIds, bool completed);
}

class DefaultTodoService implements TodoService {
  final TodoGroupRepository _todoGroupRepository;
  final TodoItemRepository _todoItemRepository;
  final ContactRepository _contactRepository;
  final EventRepository _eventRepository;
  final Uuid _uuid;

  DefaultTodoService(
    this._todoGroupRepository,
    this._todoItemRepository,
    this._contactRepository,
    this._eventRepository, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  @override
  Future<TodoGroup> createGroup(TodoGroupDraft draft) async {
    final normalizedTitle = draft.title.trim();
    if (normalizedTitle.isEmpty) {
      throw const ValidationException(message: '待办组名称不能为空', code: 'todo_group_title_required');
    }

    final existingGroups = await _todoGroupRepository.getAll();
    final now = DateTime.now();
    return _todoGroupRepository.insert(
      TodoGroup(
        id: _uuid.v4(),
        title: normalizedTitle,
        description: normalizeOptionalText(draft.description),
        sortOrder: existingGroups.length,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<TodoGroup> updateGroup(TodoGroup group) async {
    final normalizedTitle = group.title.trim();
    if (normalizedTitle.isEmpty) {
      throw const ValidationException(message: '待办组名称不能为空', code: 'todo_group_title_required');
    }

    final existing = await _todoGroupRepository.getById(group.id);
    return _todoGroupRepository.update(
      group.copyWith(
        title: normalizedTitle,
        description: normalizeOptionalText(group.description),
        clearDescription: normalizeOptionalText(group.description) == null,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<TodoGroup> archiveGroup(String groupId) async {
    final existing = await _todoGroupRepository.getById(groupId);
    if (existing.archivedAt != null) {
      return existing;
    }

    return _todoGroupRepository.update(
      existing.copyWith(
        archivedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<TodoGroup> restoreGroup(String groupId) async {
    final existing = await _todoGroupRepository.getById(groupId);
    if (existing.archivedAt == null) {
      return existing;
    }

    return _todoGroupRepository.update(
      existing.copyWith(
        clearArchivedAt: true,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    await _todoGroupRepository.getById(groupId);
    await _todoGroupRepository.delete(groupId);
  }

  @override
  Future<TodoItem> createItem(String groupId, TodoItemDraft draft) async {
    await _todoGroupRepository.getById(groupId);
    await _validateLinks(
      contactIds: draft.contactIds,
      eventIds: draft.eventIds,
    );

    final normalizedTitle = draft.title.trim();
    if (normalizedTitle.isEmpty) {
      throw const ValidationException(message: '待办项标题不能为空', code: 'todo_item_title_required');
    }

    final existingItems = await _todoItemRepository.getByGroupId(groupId);
    final sortOrder = existingItems.length;
    final now = DateTime.now();
    final item = await _todoItemRepository.insert(
      TodoItem(
        id: _uuid.v4(),
        groupId: groupId,
        title: normalizedTitle,
        notes: normalizeOptionalText(draft.notes),
        status: draft.status,
        completedAt: draft.status == TodoItemStatus.completed ? now : null,
        sortOrder: sortOrder,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await _todoItemRepository.replaceContactLinks(item.id, draft.contactIds);
    await _todoItemRepository.replaceEventLinks(item.id, draft.eventIds);
    return _todoItemRepository.getById(item.id);
  }

  @override
  Future<TodoItem> updateItem(
    TodoItem item, {
    List<String> contactIds = const [],
    List<String> eventIds = const [],
  }) async {
    final existing = await _todoItemRepository.getById(item.id);
    await _todoGroupRepository.getById(item.groupId);
    await _validateLinks(
      contactIds: contactIds,
      eventIds: eventIds,
    );

    final normalizedTitle = item.title.trim();
    if (normalizedTitle.isEmpty) {
      throw const ValidationException(message: '待办项标题不能为空', code: 'todo_item_title_required');
    }

    final nextStatus = item.status;
    final updated = await _todoItemRepository.update(
      item.copyWith(
        title: normalizedTitle,
        notes: normalizeOptionalText(item.notes),
        clearNotes: normalizeOptionalText(item.notes) == null,
        completedAt: nextStatus == TodoItemStatus.completed
            ? (item.completedAt ?? DateTime.now())
            : null,
        clearCompletedAt: nextStatus != TodoItemStatus.completed,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      ),
    );

    await _todoItemRepository.replaceContactLinks(updated.id, contactIds);
    await _todoItemRepository.replaceEventLinks(updated.id, eventIds);
    return _todoItemRepository.getById(updated.id);
  }

  @override
  Future<void> deleteItem(String itemId) async {
    await _todoItemRepository.getById(itemId);
    await _todoItemRepository.delete(itemId);
  }

  @override
  Future<void> deleteItems(List<String> itemIds) async {
    final normalizedIds = await _normalizeDeleteItemIds(itemIds);
    for (final itemId in normalizedIds) {
      await _todoItemRepository.delete(itemId);
    }
  }

  @override
  Future<TodoItem> setItemCompleted(String itemId, bool completed) async {
    final item = await _todoItemRepository.getById(itemId);
    return _todoItemRepository.update(
      item.copyWith(
        status: completed ? TodoItemStatus.completed : TodoItemStatus.pending,
        completedAt: completed ? DateTime.now() : null,
        clearCompletedAt: !completed,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> setItemsCompleted(List<String> itemIds, bool completed) async {
    for (final itemId in itemIds.toSet()) {
      await setItemCompleted(itemId, completed);
    }
  }

  Future<List<String>> _normalizeDeleteItemIds(List<String> itemIds) async {
    final distinctIds = itemIds.toSet().toList(growable: false);
    for (final itemId in distinctIds) {
      await _todoItemRepository.getById(itemId);
    }
    return distinctIds;
  }

  Future<void> _validateLinks({
    List<String> contactIds = const [],
    List<String> eventIds = const [],
  }) async {
    for (final contactId in contactIds.toSet()) {
      await _contactRepository.getById(contactId);
    }

    for (final eventId in eventIds.toSet()) {
      await _eventRepository.getById(eventId);
    }
  }
}