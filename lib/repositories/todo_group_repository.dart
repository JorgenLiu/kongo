import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../exceptions/app_exception.dart';
import '../models/todo_group.dart';
import '../services/database_service.dart';

abstract class TodoGroupRepository {
  Future<List<TodoGroup>> getAll({bool includeArchived = false});
  Future<TodoGroup> getById(String id);
  Future<TodoGroup> insert(TodoGroup group);
  Future<TodoGroup> update(TodoGroup group);
  Future<void> delete(String id);
}

class SqliteTodoGroupRepository implements TodoGroupRepository {
  final DatabaseService _databaseService;

  SqliteTodoGroupRepository(this._databaseService);

  @override
  Future<List<TodoGroup>> getAll({bool includeArchived = false}) async {
    return _run<List<TodoGroup>>('获取待办组失败', (db) async {
      final rows = await db.query(
        DatabaseService.todoGroupsTable,
        where: includeArchived ? null : 'archivedAt IS NULL',
        orderBy: 'sortOrder ASC, createdAt ASC',
      );
      return rows.map(_toGroup).toList(growable: false);
    });
  }

  @override
  Future<TodoGroup> getById(String id) async {
    return _run<TodoGroup>('获取待办组失败', (db) async {
      final rows = await db.query(
        DatabaseService.todoGroupsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw const DatabaseException(message: '待办组不存在', code: 'todo_group_not_found');
      }
      return _toGroup(rows.first);
    });
  }

  @override
  Future<TodoGroup> insert(TodoGroup group) async {
    return _run<TodoGroup>('创建待办组失败', (db) async {
      await db.insert(DatabaseService.todoGroupsTable, group.toMap());
      return getById(group.id);
    });
  }

  @override
  Future<TodoGroup> update(TodoGroup group) async {
    return _run<TodoGroup>('更新待办组失败', (db) async {
      final count = await db.update(
        DatabaseService.todoGroupsTable,
        group.toMap(),
        where: 'id = ?',
        whereArgs: [group.id],
      );
      if (count == 0) {
        throw const DatabaseException(message: '待办组不存在', code: 'todo_group_not_found');
      }
      return getById(group.id);
    });
  }

  @override
  Future<void> delete(String id) async {
    await _run<void>('删除待办组失败', (db) async {
      final count = await db.delete(
        DatabaseService.todoGroupsTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count == 0) {
        throw const DatabaseException(message: '待办组不存在', code: 'todo_group_not_found');
      }
    });
  }

  TodoGroup _toGroup(Map<String, Object?> row) {
    return TodoGroup.fromMap(Map<String, dynamic>.from(row));
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