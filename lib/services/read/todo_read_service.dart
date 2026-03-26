import '../../models/contact.dart';
import '../../models/event.dart';
import '../../models/todo_board_view_options.dart';
import '../../models/todo_group.dart';
import '../../models/todo_item.dart';
import '../../repositories/contact_repository.dart';
import '../../repositories/event_repository.dart';
import '../../repositories/todo_group_repository.dart';
import '../../repositories/todo_item_repository.dart';

abstract class TodoReadService {
  Future<TodoBoardReadModel> loadBoard({
    String? selectedGroupId,
    TodoGroupVisibility groupVisibility,
    TodoItemFilter itemFilter,
    TodoItemSort itemSort,
  });
  Future<List<TodoLinkedItemSummaryReadModel>> getItemsLinkedToContact(String contactId);
  Future<List<TodoLinkedItemSummaryReadModel>> getItemsLinkedToEvent(String eventId);
}

class DefaultTodoReadService implements TodoReadService {
  final TodoGroupRepository _todoGroupRepository;
  final TodoItemRepository _todoItemRepository;
  final ContactRepository _contactRepository;
  final EventRepository _eventRepository;

  DefaultTodoReadService(
    this._todoGroupRepository,
    this._todoItemRepository,
    this._contactRepository,
    this._eventRepository,
  );

  @override
  Future<TodoBoardReadModel> loadBoard({
    String? selectedGroupId,
    TodoGroupVisibility groupVisibility = TodoGroupVisibility.activeOnly,
    TodoItemFilter itemFilter = TodoItemFilter.all,
    TodoItemSort itemSort = TodoItemSort.manual,
  }) async {
    final includeArchived = groupVisibility != TodoGroupVisibility.activeOnly;
    final allGroups = await _todoGroupRepository.getAll(includeArchived: includeArchived);
    final groups = allGroups.where((group) {
      switch (groupVisibility) {
        case TodoGroupVisibility.activeOnly:
          return group.archivedAt == null;
        case TodoGroupVisibility.all:
          return true;
        case TodoGroupVisibility.archivedOnly:
          return group.archivedAt != null;
      }
    }).toList(growable: false);
    final selectedGroup = _resolveSelectedGroup(groups, selectedGroupId);

    TodoGroupDetailReadModel? selectedGroupDetail;
    if (selectedGroup != null) {
      selectedGroupDetail = await _buildGroupDetail(
        selectedGroup,
        itemFilter: itemFilter,
        itemSort: itemSort,
      );
    }

    final groupSummaries = <TodoGroupListItemReadModel>[];
    for (final group in groups) {
      final items = await _todoItemRepository.getByGroupId(group.id);
      groupSummaries.add(
        TodoGroupListItemReadModel(
          group: group,
          totalItems: items.length,
          completedItems: items.where((item) => item.status == TodoItemStatus.completed).length,
        ),
      );
    }

    final availableContacts = await _contactRepository.getAll();
    final availableEvents = await _eventRepository.getAll();

    return TodoBoardReadModel(
      groups: groupSummaries,
      selectedGroup: selectedGroupDetail,
      availableContacts: availableContacts,
      availableEvents: availableEvents,
    );
  }

  @override
  Future<List<TodoLinkedItemSummaryReadModel>> getItemsLinkedToContact(String contactId) async {
    final items = await _todoItemRepository.getByContactId(contactId);
    return _buildLinkedSummaries(items);
  }

  @override
  Future<List<TodoLinkedItemSummaryReadModel>> getItemsLinkedToEvent(String eventId) async {
    final items = await _todoItemRepository.getByEventId(eventId);
    return _buildLinkedSummaries(items);
  }

  Future<TodoGroupDetailReadModel> _buildGroupDetail(
    TodoGroup group, {
    required TodoItemFilter itemFilter,
    required TodoItemSort itemSort,
  }) async {
    final items = await _todoItemRepository.getByGroupId(group.id);
    final itemIds = items.map((item) => item.id).toList(growable: false);
    final contactIdsByItemId = await _todoItemRepository.getContactIdsByItemIds(itemIds);
    final eventIdsByItemId = await _todoItemRepository.getEventIdsByItemIds(itemIds);

    final contactIds = contactIdsByItemId.values.expand((ids) => ids).toSet();
    final eventIds = eventIdsByItemId.values.expand((ids) => ids).toSet();

    final contactsById = <String, Contact>{};
    for (final contactId in contactIds) {
      try {
        contactsById[contactId] = await _contactRepository.getById(contactId);
      } catch (_) {}
    }

    final eventsById = <String, Event>{};
    for (final eventId in eventIds) {
      try {
        eventsById[eventId] = await _eventRepository.getById(eventId);
      } catch (_) {}
    }

    final sortedItems = [...items]..sort((left, right) => _compareTodoItems(left, right, itemSort));

    final nodes = sortedItems
        .map(
          (item) => TodoItemTreeNodeReadModel(
            item: item,
            contacts: (contactIdsByItemId[item.id] ?? const <String>[])
                .map((id) => contactsById[id])
                .whereType<Contact>()
                .toList(growable: false),
            events: (eventIdsByItemId[item.id] ?? const <String>[])
                .map((id) => eventsById[id])
                .whereType<Event>()
                .toList(growable: false),
          ),
        )
        .toList(growable: false);

    final filteredNodes = _filterNodes(nodes, itemFilter);

    return TodoGroupDetailReadModel(
      group: group,
      rootItems: filteredNodes,
    );
  }

  Future<List<TodoLinkedItemSummaryReadModel>> _buildLinkedSummaries(List<TodoItem> items) async {
    if (items.isEmpty) {
      return const [];
    }

    final groups = await _todoGroupRepository.getAll(includeArchived: true);
    final groupsById = {for (final group in groups) group.id: group};
    final itemIds = items.map((item) => item.id).toList(growable: false);
    final contactIdsByItemId = await _todoItemRepository.getContactIdsByItemIds(itemIds);
    final eventIdsByItemId = await _todoItemRepository.getEventIdsByItemIds(itemIds);

    final summaries = items
        .map((item) {
          final group = groupsById[item.groupId];
          if (group == null || group.archivedAt != null) {
            return null;
          }

          return TodoLinkedItemSummaryReadModel(
            item: item,
            group: group,
            contactCount: (contactIdsByItemId[item.id] ?? const <String>[]).length,
            eventCount: (eventIdsByItemId[item.id] ?? const <String>[]).length,
          );
        })
        .whereType<TodoLinkedItemSummaryReadModel>()
        .toList(growable: false);

    summaries.sort((left, right) => _compareTodoItems(left.item, right.item, TodoItemSort.updatedAt));
    return summaries;
  }

  List<TodoItemTreeNodeReadModel> _filterNodes(
    List<TodoItemTreeNodeReadModel> nodes,
    TodoItemFilter itemFilter,
  ) {
    return nodes
        .where((node) => _matchesItemFilter(node, itemFilter))
        .toList(growable: false);
  }

  bool _matchesItemFilter(TodoItemTreeNodeReadModel node, TodoItemFilter itemFilter) {
    switch (itemFilter) {
      case TodoItemFilter.all:
        return true;
      case TodoItemFilter.pendingOnly:
        return node.item.status == TodoItemStatus.pending;
      case TodoItemFilter.completedOnly:
        return node.item.status == TodoItemStatus.completed;
      case TodoItemFilter.linkedOnly:
        return node.contacts.isNotEmpty || node.events.isNotEmpty;
    }
  }

  int _compareTodoItems(TodoItem left, TodoItem right, TodoItemSort itemSort) {
    switch (itemSort) {
      case TodoItemSort.manual:
        final sortOrderCompare = left.sortOrder.compareTo(right.sortOrder);
        if (sortOrderCompare != 0) {
          return sortOrderCompare;
        }
        return left.createdAt.compareTo(right.createdAt);
      case TodoItemSort.updatedAt:
        return right.updatedAt.compareTo(left.updatedAt);
    }
  }

  TodoGroup? _resolveSelectedGroup(List<TodoGroup> groups, String? selectedGroupId) {
    if (groups.isEmpty) {
      return null;
    }
    if (selectedGroupId == null) {
      return groups.first;
    }
    for (final group in groups) {
      if (group.id == selectedGroupId) {
        return group;
      }
    }
    return groups.first;
  }
}

class TodoBoardReadModel {
  final List<TodoGroupListItemReadModel> groups;
  final TodoGroupDetailReadModel? selectedGroup;
  final List<Contact> availableContacts;
  final List<Event> availableEvents;

  const TodoBoardReadModel({
    required this.groups,
    required this.selectedGroup,
    required this.availableContacts,
    required this.availableEvents,
  });
}

class TodoGroupListItemReadModel {
  final TodoGroup group;
  final int totalItems;
  final int completedItems;

  const TodoGroupListItemReadModel({
    required this.group,
    required this.totalItems,
    required this.completedItems,
  });
}

class TodoGroupDetailReadModel {
  final TodoGroup group;
  final List<TodoItemTreeNodeReadModel> rootItems;

  const TodoGroupDetailReadModel({
    required this.group,
    required this.rootItems,
  });
}

class TodoItemTreeNodeReadModel {
  final TodoItem item;
  final List<Contact> contacts;
  final List<Event> events;

  const TodoItemTreeNodeReadModel({
    required this.item,
    required this.contacts,
    required this.events,
  });

  TodoItemTreeNodeReadModel copyWith({
    TodoItem? item,
    List<Contact>? contacts,
    List<Event>? events,
  }) {
    return TodoItemTreeNodeReadModel(
      item: item ?? this.item,
      contacts: contacts ?? this.contacts,
      events: events ?? this.events,
    );
  }
}

class TodoLinkedItemSummaryReadModel {
  final TodoItem item;
  final TodoGroup group;
  final int contactCount;
  final int eventCount;

  const TodoLinkedItemSummaryReadModel({
    required this.item,
    required this.group,
    required this.contactCount,
    required this.eventCount,
  });
}