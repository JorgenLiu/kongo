import '../models/todo_group.dart';
import '../models/todo_board_view_options.dart';
import '../models/todo_group_draft.dart';
import '../models/todo_item.dart';
import '../models/todo_item_draft.dart';
import '../services/read/todo_read_service.dart';
import '../services/todo_service.dart';
import 'base_provider.dart';

class TodoBoardProvider extends BaseProvider {
  final TodoReadService _todoReadService;
  final TodoService _todoService;

  TodoBoardProvider(this._todoReadService, this._todoService);

  TodoBoardReadModel? _data;
  String? _selectedGroupId;
  TodoGroupVisibility _groupVisibility = TodoGroupVisibility.activeOnly;
  TodoItemFilter _itemFilter = TodoItemFilter.all;
  TodoItemSort _itemSort = TodoItemSort.manual;
  bool _selectionMode = false;
  Set<String> _selectedItemIds = <String>{};

  TodoBoardReadModel? get data => _data;
  String? get selectedGroupId => _selectedGroupId ?? _data?.selectedGroup?.group.id;
  TodoGroupVisibility get groupVisibility => _groupVisibility;
  TodoItemFilter get itemFilter => _itemFilter;
  TodoItemSort get itemSort => _itemSort;
  bool get selectionMode => _selectionMode;
  Set<String> get selectedItemIds => Set.unmodifiable(_selectedItemIds);
  int get visibleItemCount => _flattenVisibleItems(_data?.selectedGroup?.rootItems ?? const []).length;

  Future<void> load({String? selectedGroupId}) async {
    if (selectedGroupId != null) {
      _selectedGroupId = selectedGroupId;
    }
    await execute(() async {
      _data = await _todoReadService.loadBoard(
        selectedGroupId: _selectedGroupId,
        groupVisibility: _groupVisibility,
        itemFilter: _itemFilter,
        itemSort: _itemSort,
      );
      _selectedGroupId = _data?.selectedGroup?.group.id;
      _syncSelectionWithVisibleItems();
      markInitialized();
    });
  }

  Future<void> refresh() => load();

  Future<void> selectGroup(String groupId) async {
    await execute(() async {
      _selectedGroupId = groupId;
      _data = await _todoReadService.loadBoard(
        selectedGroupId: groupId,
        groupVisibility: _groupVisibility,
        itemFilter: _itemFilter,
        itemSort: _itemSort,
      );
      _syncSelectionWithVisibleItems();
      markInitialized();
    });
  }

  void enterSelectionMode([String? itemId]) {
    _selectionMode = true;
    if (itemId != null) {
      _selectedItemIds = {..._selectedItemIds, itemId};
    }
    notifyListeners();
  }

  void clearSelection() {
    final changed = _selectionMode || _selectedItemIds.isNotEmpty;
    _selectionMode = false;
    _selectedItemIds = <String>{};
    if (changed) {
      notifyListeners();
    }
  }

  void toggleItemSelection(String itemId) {
    final next = {..._selectedItemIds};
    if (!next.add(itemId)) {
      next.remove(itemId);
    }
    _selectionMode = true;
    _selectedItemIds = next;
    notifyListeners();
  }

  void selectAllVisibleItems() {
    _selectionMode = true;
    _selectedItemIds = _flattenVisibleItems(_data?.selectedGroup?.rootItems ?? const [])
        .map((node) => node.item.id)
        .toSet();
    notifyListeners();
  }

  Future<void> setGroupVisibility(TodoGroupVisibility value) async {
    if (_groupVisibility == value) {
      return;
    }
    _groupVisibility = value;
    await load();
  }

  Future<void> setItemFilter(TodoItemFilter value) async {
    if (_itemFilter == value) {
      return;
    }
    _itemFilter = value;
    await load();
  }

  Future<void> setItemSort(TodoItemSort value) async {
    if (_itemSort == value) {
      return;
    }
    _itemSort = value;
    await load();
  }

  Future<void> createGroup(TodoGroupDraft draft) async {
    await execute(() async {
      final group = await _todoService.createGroup(draft);
      _selectedGroupId = group.id;
      _data = await _todoReadService.loadBoard(
        selectedGroupId: _selectedGroupId,
        groupVisibility: _groupVisibility,
        itemFilter: _itemFilter,
        itemSort: _itemSort,
      );
      _syncSelectionWithVisibleItems();
      markInitialized();
    });
  }

  Future<void> updateGroup(TodoGroup group) async {
    await execute(() async {
      await _todoService.updateGroup(group);
      _data = await _todoReadService.loadBoard(
        selectedGroupId: selectedGroupId,
        groupVisibility: _groupVisibility,
        itemFilter: _itemFilter,
        itemSort: _itemSort,
      );
      _syncSelectionWithVisibleItems();
      markInitialized();
    });
  }

  Future<void> archiveGroup(String groupId) async {
    await execute(() async {
      await _todoService.archiveGroup(groupId);
      _data = await _todoReadService.loadBoard(
        selectedGroupId: selectedGroupId,
        groupVisibility: _groupVisibility,
        itemFilter: _itemFilter,
        itemSort: _itemSort,
      );
      _selectedGroupId = _data?.selectedGroup?.group.id;
      _syncSelectionWithVisibleItems();
      markInitialized();
    });
  }

  Future<void> restoreGroup(String groupId) async {
    await execute(() async {
      await _todoService.restoreGroup(groupId);
      _selectedGroupId = groupId;
      _data = await _todoReadService.loadBoard(
        selectedGroupId: groupId,
        groupVisibility: _groupVisibility,
        itemFilter: _itemFilter,
        itemSort: _itemSort,
      );
      _syncSelectionWithVisibleItems();
      markInitialized();
    });
  }

  Future<void> deleteGroup(String groupId) async {
    await execute(() async {
      await _todoService.deleteGroup(groupId);
      if (_selectedGroupId == groupId) {
        _selectedGroupId = null;
      }
      _data = await _todoReadService.loadBoard(
        selectedGroupId: _selectedGroupId,
        groupVisibility: _groupVisibility,
        itemFilter: _itemFilter,
        itemSort: _itemSort,
      );
      _selectedGroupId = _data?.selectedGroup?.group.id;
      markInitialized();
    });
  }

  Future<void> createItem(String groupId, TodoItemDraft draft) async {
    await execute(() async {
      await _todoService.createItem(groupId, draft);
      _selectedGroupId = groupId;
      _data = await _todoReadService.loadBoard(
        selectedGroupId: groupId,
        groupVisibility: _groupVisibility,
        itemFilter: _itemFilter,
        itemSort: _itemSort,
      );
      markInitialized();
    });
  }

  Future<void> updateItem(
    TodoItem item, {
    List<String> contactIds = const [],
    List<String> eventIds = const [],
  }) async {
    await execute(() async {
      await _todoService.updateItem(item, contactIds: contactIds, eventIds: eventIds);
      _selectedGroupId = item.groupId;
      _data = await _todoReadService.loadBoard(
        selectedGroupId: item.groupId,
        groupVisibility: _groupVisibility,
        itemFilter: _itemFilter,
        itemSort: _itemSort,
      );
      _syncSelectionWithVisibleItems();
      markInitialized();
    });
  }

  Future<void> deleteItem(String itemId) async {
    final groupId = _data?.selectedGroup?.group.id;
    if (groupId == null) {
      return;
    }

    await execute(() async {
      await _todoService.deleteItem(itemId);
      _data = await _todoReadService.loadBoard(
        selectedGroupId: groupId,
        groupVisibility: _groupVisibility,
        itemFilter: _itemFilter,
        itemSort: _itemSort,
      );
      _syncSelectionWithVisibleItems();
      markInitialized();
    });
  }

  Future<void> toggleItemCompleted(TodoItem item, bool completed) async {
    await execute(() async {
      await _todoService.setItemCompleted(item.id, completed);
      _data = await _todoReadService.loadBoard(
        selectedGroupId: item.groupId,
        groupVisibility: _groupVisibility,
        itemFilter: _itemFilter,
        itemSort: _itemSort,
      );
      _syncSelectionWithVisibleItems();
      markInitialized();
    });
  }

  Future<void> batchDeleteSelectedItems() async {
    final groupId = selectedGroupId;
    final selectedIds = _selectedItemIds.toList(growable: false);
    if (groupId == null || selectedIds.isEmpty) {
      return;
    }

    await execute(() async {
      await _todoService.deleteItems(selectedIds);
      _data = await _todoReadService.loadBoard(
        selectedGroupId: groupId,
        groupVisibility: _groupVisibility,
        itemFilter: _itemFilter,
        itemSort: _itemSort,
      );
      _selectedItemIds = <String>{};
      _selectionMode = false;
      _syncSelectionWithVisibleItems();
      markInitialized();
    });
  }

  Future<void> batchSetSelectedItemsCompleted(bool completed) async {
    final groupId = selectedGroupId;
    final selectedIds = _selectedItemIds.toList(growable: false);
    if (groupId == null || selectedIds.isEmpty) {
      return;
    }

    await execute(() async {
      await _todoService.setItemsCompleted(selectedIds, completed);
      _data = await _todoReadService.loadBoard(
        selectedGroupId: groupId,
        groupVisibility: _groupVisibility,
        itemFilter: _itemFilter,
        itemSort: _itemSort,
      );
      _syncSelectionWithVisibleItems();
      markInitialized();
    });
  }

  List<TodoItemTreeNodeReadModel> _flattenVisibleItems(List<TodoItemTreeNodeReadModel> nodes) {
    return nodes;
  }

  void _syncSelectionWithVisibleItems() {
    final visibleIds = _flattenVisibleItems(_data?.selectedGroup?.rootItems ?? const [])
        .map((node) => node.item.id)
        .toSet();
    _selectedItemIds = _selectedItemIds.where(visibleIds.contains).toSet();
    if (_selectedItemIds.isEmpty) {
      _selectionMode = false;
    }
  }
}