import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:uuid/uuid.dart';

import '../exceptions/app_exception.dart';
import '../models/info_tag.dart';
import '../services/database_service.dart';

abstract class InfoTagRepository {
  /// 按名称查找已有信息标签，不存在则创建。
  Future<InfoTag> findOrCreate(String name);

  /// 将信息标签关联到联系人。已存在时忽略。
  Future<void> addToContact(String contactId, String infoTagId, {String source = 'ai'});

  /// 解除联系人与信息标签的关联。
  Future<void> removeFromContact(String contactId, String infoTagId);

  /// 获取某个联系人的所有信息标签。
  Future<List<InfoTag>> getForContact(String contactId);

  /// 批量查询多个联系人的信息标签名，返回 contactId → 标签名列表的映射。
  Future<Map<String, List<String>>> getNamesByContactIds(List<String> contactIds);

  /// 按关键词搜索信息标签，返回持有匹配标签的 contactId 列表（去重）。
  Future<List<String>> findContactIdsByTagKeyword(String keyword);
}

class SqliteInfoTagRepository implements InfoTagRepository {
  final DatabaseService _databaseService;
  final Uuid _uuid;

  SqliteInfoTagRepository(this._databaseService, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  @override
  Future<InfoTag> findOrCreate(String name) async {
    return _run('查找或创建信息标签失败', (db) async {
      final existing = await db.query(
        DatabaseService.infoTagsTable,
        where: 'name = ?',
        whereArgs: [name],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        return InfoTag.fromMap(Map<String, dynamic>.from(existing.first));
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      final id = _uuid.v4();
      await db.insert(
        DatabaseService.infoTagsTable,
        {'id': id, 'name': name, 'createdAt': now},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      // 插入后重新查询（防止并发时 ignore 导致使用他人插入的行）
      final rows = await db.query(
        DatabaseService.infoTagsTable,
        where: 'name = ?',
        whereArgs: [name],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw const DatabaseException(message: '信息标签创建失败', code: 'info_tag_create_failed');
      }
      return InfoTag.fromMap(Map<String, dynamic>.from(rows.first));
    });
  }

  @override
  Future<void> addToContact(
    String contactId,
    String infoTagId, {
    String source = 'ai',
  }) async {
    return _run('关联信息标签到联系人失败', (db) async {
      await db.insert(
        DatabaseService.contactInfoTagsTable,
        {
          'id': _uuid.v4(),
          'contactId': contactId,
          'infoTagId': infoTagId,
          'source': source,
          'addedAt': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    });
  }

  @override
  Future<void> removeFromContact(String contactId, String infoTagId) async {
    return _run('解除信息标签关联失败', (db) async {
      await db.delete(
        DatabaseService.contactInfoTagsTable,
        where: 'contactId = ? AND infoTagId = ?',
        whereArgs: [contactId, infoTagId],
      );
    });
  }

  @override
  Future<List<InfoTag>> getForContact(String contactId) async {
    return _run('获取联系人信息标签失败', (db) async {
      final rows = await db.rawQuery(
        '''
SELECT it.*
FROM ${DatabaseService.infoTagsTable} it
JOIN ${DatabaseService.contactInfoTagsTable} cit ON cit.infoTagId = it.id
WHERE cit.contactId = ?
ORDER BY it.name COLLATE NOCASE ASC
''',
        [contactId],
      );
      return rows.map((r) => InfoTag.fromMap(Map<String, dynamic>.from(r))).toList();
    });
  }

  @override
  Future<Map<String, List<String>>> getNamesByContactIds(
    List<String> contactIds,
  ) async {
    if (contactIds.isEmpty) return const {};
    return _run('批量获取联系人信息标签失败', (db) async {
      final placeholders = List.filled(contactIds.length, '?').join(', ');
      final rows = await db.rawQuery(
        '''
SELECT cit.contactId, it.name
FROM ${DatabaseService.contactInfoTagsTable} cit
JOIN ${DatabaseService.infoTagsTable} it ON it.id = cit.infoTagId
WHERE cit.contactId IN ($placeholders)
ORDER BY it.name COLLATE NOCASE ASC
''',
        contactIds,
      );
      final result = <String, List<String>>{};
      for (final row in rows) {
        final contactId = row['contactId'] as String;
        final name = row['name'] as String;
        result.putIfAbsent(contactId, () => <String>[]).add(name);
      }
      return result;
    });
  }

  @override
  Future<List<String>> findContactIdsByTagKeyword(String keyword) async {
    if (keyword.trim().isEmpty) return const [];
    return _run('按关键词搜索信息标签持有者失败', (db) async {
      final rows = await db.rawQuery(
        '''
SELECT DISTINCT cit.contactId
FROM ${DatabaseService.infoTagsTable} it
JOIN ${DatabaseService.contactInfoTagsTable} cit ON cit.infoTagId = it.id
WHERE it.name LIKE ?
''',
        ['%${keyword.trim()}%'],
      );
      return rows.map((r) => r['contactId'] as String).toList();
    });
  }

  Future<T> _run<T>(String errorMessage, Future<T> Function(Database db) action) async {
    try {
      final db = await _databaseService.database;
      return await action(db);
    } on DatabaseException {
      rethrow;
    } catch (e) {
      throw DatabaseException(message: errorMessage, code: 'info_tag_db_error');
    }
  }
}
