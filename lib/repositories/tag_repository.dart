import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../exceptions/app_exception.dart';
import '../models/tag.dart';
import '../services/database_service.dart';

abstract class TagRepository {
  Future<List<Tag>> getAll();
  Future<Tag> getById(String id);
  Future<bool> exists(String id);
  Future<Tag> insert(Tag tag);
  Future<Tag> update(Tag tag);
  Future<void> delete(String id);
  Future<void> addToContact(String contactId, String tagId);
  Future<void> removeFromContact(String contactId, String tagId);
  Future<List<Tag>> getTagsForContact(String contactId);
  Future<int> getContactCountByTag(String tagId);
  Future<List<String>> getContactIdsByTagIds(List<String> tagIds, {bool matchAll = false});
}

class SqliteTagRepository implements TagRepository {
  final DatabaseService _databaseService;

  SqliteTagRepository(this._databaseService);

  @override
  Future<List<Tag>> getAll() async {
    return _run<List<Tag>>('获取标签列表失败', (db) async {
      final rows = await db.query(
        DatabaseService.tagsTable,
        orderBy: 'name COLLATE NOCASE ASC',
      );
      return rows.map(_toTag).toList();
    });
  }

  @override
  Future<Tag> getById(String id) async {
    return _run<Tag>('获取标签失败', (db) async {
      final rows = await db.query(
        DatabaseService.tagsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (rows.isEmpty) {
        throw const DatabaseException(message: '标签不存在', code: 'tag_not_found');
      }

      return _toTag(rows.first);
    });
  }

  @override
  Future<bool> exists(String id) async {
    return _run<bool>('检查标签失败', (db) async {
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM ${DatabaseService.tagsTable} WHERE id = ?',
        [id],
      );
      return ((rows.first['count'] as num?)?.toInt() ?? 0) > 0;
    });
  }

  @override
  Future<Tag> insert(Tag tag) async {
    return _run<Tag>('创建标签失败', (db) async {
      await db.insert(DatabaseService.tagsTable, tag.toMap());
      return getById(tag.id);
    });
  }

  @override
  Future<Tag> update(Tag tag) async {
    return _run<Tag>('更新标签失败', (db) async {
      final count = await db.update(
        DatabaseService.tagsTable,
        tag.toMap(),
        where: 'id = ?',
        whereArgs: [tag.id],
      );

      if (count == 0) {
        throw const DatabaseException(message: '标签不存在，无法更新', code: 'tag_not_found');
      }

      return getById(tag.id);
    });
  }

  @override
  Future<void> delete(String id) async {
    await _run<void>('删除标签失败', (db) async {
      final count = await db.delete(
        DatabaseService.tagsTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw const DatabaseException(message: '标签不存在，无法删除', code: 'tag_not_found');
      }
    });
  }

  @override
  Future<void> addToContact(String contactId, String tagId) async {
    await _run<void>('为联系人添加标签失败', (db) async {
      await db.insert(
        DatabaseService.contactTagsTable,
        {
          'id': '${contactId}_$tagId',
          'contactId': contactId,
          'tagId': tagId,
          'addedAt': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  @override
  Future<void> removeFromContact(String contactId, String tagId) async {
    await _run<void>('移除联系人标签失败', (db) async {
      await db.delete(
        DatabaseService.contactTagsTable,
        where: 'contactId = ? AND tagId = ?',
        whereArgs: [contactId, tagId],
      );
    });
  }

  @override
  Future<List<Tag>> getTagsForContact(String contactId) async {
    return _run<List<Tag>>('获取联系人标签失败', (db) async {
      final rows = await db.rawQuery(
        '''
SELECT t.*
FROM ${DatabaseService.tagsTable} t
JOIN ${DatabaseService.contactTagsTable} ct ON ct.tagId = t.id
WHERE ct.contactId = ?
ORDER BY t.name COLLATE NOCASE ASC
''',
        [contactId],
      );
      return rows.map(_toTag).toList();
    });
  }

  @override
  Future<int> getContactCountByTag(String tagId) async {
    return _run<int>('统计标签联系人数量失败', (db) async {
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM ${DatabaseService.contactTagsTable} WHERE tagId = ?',
        [tagId],
      );
      return (rows.first['count'] as num?)?.toInt() ?? 0;
    });
  }

  @override
  Future<List<String>> getContactIdsByTagIds(
    List<String> tagIds, {
    bool matchAll = false,
  }) async {
    if (tagIds.isEmpty) {
      return const [];
    }

    return _run<List<String>>('按标签查找联系人失败', (db) async {
      final placeholders = List.filled(tagIds.length, '?').join(', ');
      final sql = matchAll
          ? '''
SELECT contactId
FROM ${DatabaseService.contactTagsTable}
WHERE tagId IN ($placeholders)
GROUP BY contactId
HAVING COUNT(DISTINCT tagId) = ?
'''
          : '''
SELECT DISTINCT contactId
FROM ${DatabaseService.contactTagsTable}
WHERE tagId IN ($placeholders)
''';

      final rows = await db.rawQuery(
        sql,
        matchAll ? [...tagIds, tagIds.length] : [...tagIds],
      );
      return rows.map((row) => row['contactId'] as String).toList();
    });
  }

  Tag _toTag(Map<String, Object?> row) {
    return Tag.fromMap(Map<String, dynamic>.from(row));
  }

  Future<T> _run<T>(
    String message,
    Future<T> Function(Database db) action,
  ) async {
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