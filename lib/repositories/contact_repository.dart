import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../exceptions/app_exception.dart';
import '../models/contact.dart';
import '../models/tag.dart';
import '../services/database_service.dart';

abstract class ContactRepository {
  Future<List<Contact>> getAll();
  Future<Contact> getById(String id);
  Future<bool> exists(String id);
  Future<Contact> insert(Contact contact);
  Future<Contact> update(Contact contact);
  Future<void> delete(String id);
  Future<List<Contact>> searchByKeyword(String keyword);
  Future<List<Contact>> searchByTagIds(List<String> tagIds);
  Future<List<Tag>> getTags(String contactId);
}

class SqliteContactRepository implements ContactRepository {
  final DatabaseService _databaseService;

  SqliteContactRepository(this._databaseService);

  @override
  Future<List<Contact>> getAll() async {
    return _run<List<Contact>>('获取联系人列表失败', (db) async {
      final rows = await db.query(
        DatabaseService.contactsTable,
        orderBy: 'updatedAt DESC',
      );
      return _hydrateContacts(db, rows);
    });
  }

  @override
  Future<Contact> getById(String id) async {
    return _run<Contact>('获取联系人失败', (db) async {
      final rows = await db.query(
        DatabaseService.contactsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (rows.isEmpty) {
        throw const DatabaseException(
          message: '联系人不存在',
          code: 'contact_not_found',
        );
      }

      return (await _hydrateContacts(db, rows)).first;
    });
  }

  @override
  Future<bool> exists(String id) async {
    return _run<bool>('检查联系人失败', (db) async {
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM ${DatabaseService.contactsTable} WHERE id = ?',
        [id],
      );
      return ((rows.first['count'] as num?)?.toInt() ?? 0) > 0;
    });
  }

  @override
  Future<Contact> insert(Contact contact) async {
    return _run<Contact>('创建联系人失败', (db) async {
      await db.insert(DatabaseService.contactsTable, contact.toMap());
      return getById(contact.id);
    });
  }

  @override
  Future<Contact> update(Contact contact) async {
    return _run<Contact>('更新联系人失败', (db) async {
      final count = await db.update(
        DatabaseService.contactsTable,
        contact.toMap(),
        where: 'id = ?',
        whereArgs: [contact.id],
      );

      if (count == 0) {
        throw const DatabaseException(
          message: '联系人不存在，无法更新',
          code: 'contact_not_found',
        );
      }

      return getById(contact.id);
    });
  }

  @override
  Future<void> delete(String id) async {
    await _run<void>('删除联系人失败', (db) async {
      final count = await db.delete(
        DatabaseService.contactsTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw const DatabaseException(
          message: '联系人不存在，无法删除',
          code: 'contact_not_found',
        );
      }
    });
  }

  @override
  Future<List<Contact>> searchByKeyword(String keyword) async {
    final normalizedKeyword = keyword.trim();
    if (normalizedKeyword.isEmpty) {
      return getAll();
    }

    return _run<List<Contact>>('搜索联系人失败', (db) async {
      final likeKeyword = '%$normalizedKeyword%';
      final rows = await db.query(
        DatabaseService.contactsTable,
        where: 'name LIKE ? OR phone LIKE ? OR email LIKE ? OR notes LIKE ?',
        whereArgs: [likeKeyword, likeKeyword, likeKeyword, likeKeyword],
        orderBy: 'updatedAt DESC',
      );
      return _hydrateContacts(db, rows);
    });
  }

  @override
  Future<List<Contact>> searchByTagIds(List<String> tagIds) async {
    if (tagIds.isEmpty) {
      return getAll();
    }

    return _run<List<Contact>>('按标签搜索联系人失败', (db) async {
      final placeholders = List.filled(tagIds.length, '?').join(', ');
      final rows = await db.rawQuery(
        '''
SELECT c.*, COUNT(DISTINCT ct.tagId) AS _matchCount
FROM ${DatabaseService.contactsTable} c
JOIN ${DatabaseService.contactTagsTable} ct ON ct.contactId = c.id
WHERE ct.tagId IN ($placeholders)
GROUP BY c.id
ORDER BY _matchCount DESC, c.updatedAt DESC
''',
        [...tagIds],
      );

      return _hydrateContacts(db, rows);
    });
  }

  @override
  Future<List<Tag>> getTags(String contactId) async {
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

  Future<List<Contact>> _hydrateContacts(
    Database db,
    List<Map<String, Object?>> rows,
  ) async {
    if (rows.isEmpty) {
      return const [];
    }

    final ids = rows.map((row) => row['id'] as String).toList();
    final tagsByContactId = await _loadTagsByContactIds(db, ids);
    final infoTagsByContactId = await _loadInfoTagsByContactIds(db, ids);

    return rows
        .map(
          (row) => Contact.fromMap(
            Map<String, dynamic>.from(row),
            tags: tagsByContactId[row['id'] as String] ?? const [],
            infoTags: infoTagsByContactId[row['id'] as String] ?? const [],
          ),
        )
        .toList();
  }

  Future<Map<String, List<String>>> _loadTagsByContactIds(
    Database db,
    List<String> contactIds,
  ) async {
    if (contactIds.isEmpty) {
      return const {};
    }

    final placeholders = List.filled(contactIds.length, '?').join(', ');
    final rows = await db.rawQuery(
      '''
SELECT ct.contactId, t.name
FROM ${DatabaseService.contactTagsTable} ct
JOIN ${DatabaseService.tagsTable} t ON t.id = ct.tagId
WHERE ct.contactId IN ($placeholders)
ORDER BY t.name COLLATE NOCASE ASC
''',
      contactIds,
    );

    final result = <String, List<String>>{};
    for (final row in rows) {
      final contactId = row['contactId'] as String;
      final tagName = row['name'] as String;
      result.putIfAbsent(contactId, () => <String>[]).add(tagName);
    }
    return result;
  }

  Future<Map<String, List<String>>> _loadInfoTagsByContactIds(
    Database db,
    List<String> contactIds,
  ) async {
    if (contactIds.isEmpty) {
      return const {};
    }

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
      final tagName = row['name'] as String;
      result.putIfAbsent(contactId, () => <String>[]).add(tagName);
    }
    return result;
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