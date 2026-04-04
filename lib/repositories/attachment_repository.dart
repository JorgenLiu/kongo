import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../exceptions/app_exception.dart';
import '../models/attachment.dart';
import '../models/attachment_link.dart';
import '../services/database_service.dart';

abstract class AttachmentRepository {
  Future<List<Attachment>> getAll();
  Future<Attachment> insert(Attachment attachment);
  Future<Attachment> update(Attachment attachment);
  Future<Attachment> getById(String id);
  Future<bool> exists(String id);
  Future<void> delete(String id);
  Future<void> link(
    String attachmentId,
    AttachmentOwnerType ownerType,
    String ownerId, {
    String? label,
  });
  Future<void> unlink(String attachmentId, AttachmentOwnerType ownerType, String ownerId);
  Future<void> unlinkAllByOwner(AttachmentOwnerType ownerType, String ownerId);
  Future<List<Attachment>> getByOwner(AttachmentOwnerType ownerType, String ownerId);
  Future<Map<String, List<Attachment>>> getByOwners(
    AttachmentOwnerType ownerType,
    List<String> ownerIds,
  );
  Future<int> getLinkCount(String attachmentId);
  Future<List<Attachment>> searchByKeyword(String keyword);
}

class SqliteAttachmentRepository implements AttachmentRepository {
  final DatabaseService _databaseService;

  SqliteAttachmentRepository(this._databaseService);

  @override
  Future<List<Attachment>> getAll() async {
    return _run<List<Attachment>>('获取附件列表失败', (db) async {
      final rows = await db.query(
        DatabaseService.attachmentsTable,
        orderBy: 'updatedAt DESC',
      );
      return rows.map(_toAttachment).toList();
    });
  }

  @override
  Future<Attachment> insert(Attachment attachment) async {
    return _run<Attachment>('创建附件失败', (db) async {
      await db.insert(DatabaseService.attachmentsTable, attachment.toMap());
      return getById(attachment.id);
    });
  }

  @override
  Future<Attachment> update(Attachment attachment) async {
    return _run<Attachment>('更新附件失败', (db) async {
      final count = await db.update(
        DatabaseService.attachmentsTable,
        attachment.toMap(),
        where: 'id = ?',
        whereArgs: [attachment.id],
      );
      if (count == 0) {
        throw const DatabaseException(message: '附件不存在，无法更新', code: 'attachment_not_found');
      }
      return getById(attachment.id);
    });
  }

  @override
  Future<Attachment> getById(String id) async {
    return _run<Attachment>('获取附件失败', (db) async {
      final rows = await db.query(
        DatabaseService.attachmentsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw const DatabaseException(message: '附件不存在', code: 'attachment_not_found');
      }
      return _toAttachment(rows.first);
    });
  }

  @override
  Future<bool> exists(String id) async {
    return _run<bool>('检查附件失败', (db) async {
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM ${DatabaseService.attachmentsTable} WHERE id = ?',
        [id],
      );
      return ((rows.first['count'] as num?)?.toInt() ?? 0) > 0;
    });
  }

  @override
  Future<void> delete(String id) async {
    await _run<void>('删除附件失败', (db) async {
      final count = await db.delete(
        DatabaseService.attachmentsTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count == 0) {
        throw const DatabaseException(message: '附件不存在，无法删除', code: 'attachment_not_found');
      }
    });
  }

  @override
  Future<void> link(
    String attachmentId,
    AttachmentOwnerType ownerType,
    String ownerId, {
    String? label,
  }) async {
    await _run<void>('关联附件失败', (db) async {
      await db.insert(
        DatabaseService.attachmentLinksTable,
        {
          'id': '$attachmentId:${ownerType.value}:$ownerId',
          'attachmentId': attachmentId,
          'ownerType': ownerType.value,
          'ownerId': ownerId,
          'label': label,
          'addedAt': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  @override
  Future<void> unlink(
    String attachmentId,
    AttachmentOwnerType ownerType,
    String ownerId,
  ) async {
    await _run<void>('取消附件关联失败', (db) async {
      await db.delete(
        DatabaseService.attachmentLinksTable,
        where: 'attachmentId = ? AND ownerType = ? AND ownerId = ?',
        whereArgs: [attachmentId, ownerType.value, ownerId],
      );
    });
  }

  @override
  Future<void> unlinkAllByOwner(AttachmentOwnerType ownerType, String ownerId) async {
    await _run<void>('清理附件关联失败', (db) async {
      await db.delete(
        DatabaseService.attachmentLinksTable,
        where: 'ownerType = ? AND ownerId = ?',
        whereArgs: [ownerType.value, ownerId],
      );
    });
  }

  @override
  Future<List<Attachment>> getByOwner(AttachmentOwnerType ownerType, String ownerId) async {
    return _run<List<Attachment>>('获取附件列表失败', (db) async {
      final rows = await db.rawQuery(
        '''
SELECT a.*
FROM ${DatabaseService.attachmentsTable} a
JOIN ${DatabaseService.attachmentLinksTable} l ON l.attachmentId = a.id
WHERE l.ownerType = ? AND l.ownerId = ?
ORDER BY l.addedAt DESC
''',
        [ownerType.value, ownerId],
      );
      return rows.map(_toAttachment).toList();
    });
  }

  @override
  Future<Map<String, List<Attachment>>> getByOwners(
    AttachmentOwnerType ownerType,
    List<String> ownerIds,
  ) async {
    return _run<Map<String, List<Attachment>>>('批量获取附件列表失败', (db) async {
      if (ownerIds.isEmpty) {
        return const {};
      }

      final placeholders = List.filled(ownerIds.length, '?').join(', ');
      final rows = await db.rawQuery(
        '''
SELECT l.ownerId AS _ownerId, a.*
FROM ${DatabaseService.attachmentsTable} a
JOIN ${DatabaseService.attachmentLinksTable} l ON l.attachmentId = a.id
WHERE l.ownerType = ? AND l.ownerId IN ($placeholders)
ORDER BY l.ownerId ASC, l.addedAt DESC
''',
        [ownerType.value, ...ownerIds],
      );

      final attachmentsByOwnerId = {
        for (final ownerId in ownerIds) ownerId: <Attachment>[],
      };
      for (final row in rows) {
        final ownerId = row['_ownerId'] as String;
        attachmentsByOwnerId.putIfAbsent(ownerId, () => <Attachment>[]).add(
          _toAttachment(row),
        );
      }

      return attachmentsByOwnerId;
    });
  }

  @override
  Future<int> getLinkCount(String attachmentId) async {
    return _run<int>('获取附件关联数量失败', (db) async {
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM ${DatabaseService.attachmentLinksTable} WHERE attachmentId = ?',
        [attachmentId],
      );
      return (rows.first['count'] as num?)?.toInt() ?? 0;
    });
  }

  @override
  Future<List<Attachment>> searchByKeyword(String keyword) async {
    return _run<List<Attachment>>('搜索附件失败', (db) async {
      final normalizedKeyword = '%${keyword.trim().toLowerCase()}%';
      final rows = await db.query(
        DatabaseService.attachmentsTable,
        where: 'LOWER(fileName) LIKE ? OR '
            'LOWER(originalFileName) LIKE ? OR '
            'LOWER(previewText) LIKE ?',
        whereArgs: [normalizedKeyword, normalizedKeyword, normalizedKeyword],
        orderBy: 'updatedAt DESC',
      );
      return rows.map(_toAttachment).toList();
    });
  }

  Attachment _toAttachment(Map<String, Object?> row) {
    return Attachment.fromMap(Map<String, dynamic>.from(row));
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