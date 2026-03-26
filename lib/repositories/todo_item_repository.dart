import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../exceptions/app_exception.dart';
import '../models/todo_item.dart';
import '../services/database_service.dart';

abstract class TodoItemRepository {
  Future<List<TodoItem>> getByGroupId(String groupId);
  Future<List<TodoItem>> getByContactId(String contactId);
  Future<List<TodoItem>> getByEventId(String eventId);
  Future<TodoItem> getById(String id);
  Future<TodoItem> insert(TodoItem item);
  Future<TodoItem> update(TodoItem item);
  Future<void> delete(String id);
  Future<Map<String, List<String>>> getContactIdsByItemIds(List<String> itemIds);
  Future<Map<String, List<String>>> getEventIdsByItemIds(List<String> itemIds);
  Future<void> replaceContactLinks(String itemId, List<String> contactIds);
  Future<void> replaceEventLinks(String itemId, List<String> eventIds);
}

class SqliteTodoItemRepository implements TodoItemRepository {
  final DatabaseService _databaseService;

  SqliteTodoItemRepository(this._databaseService);

  @override
  Future<List<TodoItem>> getByGroupId(String groupId) async {
    return _run<List<TodoItem>>('获取待办项失败', (db) async {
      final rows = await db.query(
        DatabaseService.todoItemsTable,
        where: 'groupId = ?',
        whereArgs: [groupId],
        orderBy: 'sortOrder ASC, createdAt ASC',
      );
      return rows.map(_toItem).toList(growable: false);
    });
  }

  @override
  Future<List<TodoItem>> getByContactId(String contactId) async {
    return _run<List<TodoItem>>('获取联系人关联待办项失败', (db) async {
      final rows = await db.rawQuery(
        'SELECT ti.* '
        'FROM ${DatabaseService.todoItemsTable} ti '
        'INNER JOIN ${DatabaseService.todoItemContactsTable} tic '
        'ON tic.itemId = ti.id '
        'WHERE tic.contactId = ? '
        'ORDER BY ti.updatedAt DESC, ti.createdAt DESC',
        [contactId],
      );
      return rows.map(_toItem).toList(growable: false);
    });
  }

  @override
  Future<List<TodoItem>> getByEventId(String eventId) async {
    return _run<List<TodoItem>>('获取事件关联待办项失败', (db) async {
      final rows = await db.rawQuery(
        'SELECT ti.* '
        'FROM ${DatabaseService.todoItemsTable} ti '
        'INNER JOIN ${DatabaseService.todoItemEventsTable} tie '
        'ON tie.itemId = ti.id '
        'WHERE tie.eventId = ? '
        'ORDER BY ti.updatedAt DESC, ti.createdAt DESC',
        [eventId],
      );
      return rows.map(_toItem).toList(growable: false);
    });
  }

  @override
  Future<TodoItem> getById(String id) async {
    return _run<TodoItem>('获取待办项失败', (db) async {
      final rows = await db.query(
        DatabaseService.todoItemsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw const DatabaseException(message: '待办项不存在', code: 'todo_item_not_found');
      }
      return _toItem(rows.first);
    });
  }

  @override
  Future<TodoItem> insert(TodoItem item) async {
    return _run<TodoItem>('创建待办项失败', (db) async {
      await db.insert(DatabaseService.todoItemsTable, item.toMap());
      return getById(item.id);
    });
  }

  @override
  Future<TodoItem> update(TodoItem item) async {
    return _run<TodoItem>('更新待办项失败', (db) async {
      final count = await db.update(
        DatabaseService.todoItemsTable,
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
      if (count == 0) {
        throw const DatabaseException(message: '待办项不存在', code: 'todo_item_not_found');
      }
      return getById(item.id);
    });
  }

  @override
  Future<void> delete(String id) async {
    await _run<void>('删除待办项失败', (db) async {
      final count = await db.delete(
        DatabaseService.todoItemsTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count == 0) {
        throw const DatabaseException(message: '待办项不存在', code: 'todo_item_not_found');
      }
    });
  }

  @override
  Future<Map<String, List<String>>> getContactIdsByItemIds(List<String> itemIds) async {
    if (itemIds.isEmpty) {
      return const {};
    }

    return _run<Map<String, List<String>>>('获取待办项联系人关联失败', (db) async {
      final placeholders = List.filled(itemIds.length, '?').join(', ');
      final rows = await db.rawQuery(
        'SELECT itemId, contactId FROM ${DatabaseService.todoItemContactsTable} WHERE itemId IN ($placeholders)',
        itemIds,
      );
      final result = <String, List<String>>{};
      for (final row in rows) {
        final itemId = row['itemId'] as String;
        final contactId = row['contactId'] as String;
        result.putIfAbsent(itemId, () => <String>[]).add(contactId);
      }
      return result;
    });
  }

  @override
  Future<Map<String, List<String>>> getEventIdsByItemIds(List<String> itemIds) async {
    if (itemIds.isEmpty) {
      return const {};
    }

    return _run<Map<String, List<String>>>('获取待办项事件关联失败', (db) async {
      final placeholders = List.filled(itemIds.length, '?').join(', ');
      final rows = await db.rawQuery(
        'SELECT itemId, eventId FROM ${DatabaseService.todoItemEventsTable} WHERE itemId IN ($placeholders)',
        itemIds,
      );
      final result = <String, List<String>>{};
      for (final row in rows) {
        final itemId = row['itemId'] as String;
        final eventId = row['eventId'] as String;
        result.putIfAbsent(itemId, () => <String>[]).add(eventId);
      }
      return result;
    });
  }

  @override
  Future<void> replaceContactLinks(String itemId, List<String> contactIds) async {
    await _run<void>('更新待办项联系人关联失败', (db) async {
      final batch = db.batch();
      batch.delete(
        DatabaseService.todoItemContactsTable,
        where: 'itemId = ?',
        whereArgs: [itemId],
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final contactId in contactIds.toSet()) {
        batch.insert(
          DatabaseService.todoItemContactsTable,
          {
            'id': '${itemId}_contact_$contactId',
            'itemId': itemId,
            'contactId': contactId,
            'addedAt': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<void> replaceEventLinks(String itemId, List<String> eventIds) async {
    await _run<void>('更新待办项事件关联失败', (db) async {
      final batch = db.batch();
      batch.delete(
        DatabaseService.todoItemEventsTable,
        where: 'itemId = ?',
        whereArgs: [itemId],
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final eventId in eventIds.toSet()) {
        batch.insert(
          DatabaseService.todoItemEventsTable,
          {
            'id': '${itemId}_event_$eventId',
            'itemId': itemId,
            'eventId': eventId,
            'addedAt': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  TodoItem _toItem(Map<String, Object?> row) {
    return TodoItem.fromMap(Map<String, dynamic>.from(row));
  }

  Future<T> _run<T>(String message, Future<T> Function(Database db) action) async {
    try {
      final db = await _databaseService.database;
      return await action(db);
    } on AppException {
      rethrow;
    } on Exception catch (error) {
      throw DatabaseException(message: message, originalException: error);
    }
  }
}