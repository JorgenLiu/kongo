import 'dart:convert';

import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../exceptions/app_exception.dart';
import '../models/quick_note.dart';
import '../services/database_service.dart';

abstract class QuickNoteRepository {
  /// 插入一条新笔记。
  Future<QuickNote> insert(QuickNote note);

  /// 查询指定日期的所有笔记（未软删）。
  Future<List<QuickNote>> findByDate(DateTime date);

  /// 查询最近 [limit] 条笔记（未软删），按 createdAt 倒序。
  Future<List<QuickNote>> findRecent(int limit);

  /// 按 ID 查询单条笔记，不存在时返回 null。
  Future<QuickNote?> findById(String id);

  /// 查询所有尚未 AI 富化（enrichedAt IS NULL）的笔记，最多返回 [limit] 条。
  Future<List<QuickNote>> findUnenriched({int limit = 50});

  /// 写入 AI 富化结果（aiMetadata + enrichedAt）。
  Future<void> updateEnrichment(
    String noteId, {
    required Map<String, dynamic> aiMetadata,
    required DateTime enrichedAt,
  });

  /// 更新 linkedContactId（rule-based 追加关联时使用）。
  Future<void> updateLinkedContact(String noteId, String contactId);

  /// 软删除笔记（设置 deletedAt）。
  Future<void> softDelete(String id);

  /// 清除 AI 富化数据（aiMetadata 和 enrichedAt 置 null）。
  Future<void> clearAiMetadata(String id);
}

class SqliteQuickNoteRepository implements QuickNoteRepository {
  final DatabaseService _databaseService;

  SqliteQuickNoteRepository(this._databaseService);

  @override
  Future<QuickNote> insert(QuickNote note) async {
    return _run<QuickNote>('写入笔记失败', (db) async {
      await db.insert(
        DatabaseService.quickNotesTable,
        note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return note;
    });
  }

  @override
  Future<List<QuickNote>> findByDate(DateTime date) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return _run<List<QuickNote>>('查询当日笔记失败', (db) async {
      final rows = await db.query(
        DatabaseService.quickNotesTable,
        where: 'captureDate = ? AND deletedAt IS NULL',
        whereArgs: [dateStr],
        orderBy: 'createdAt ASC',
      );
      return rows.map(QuickNote.fromMap).toList();
    });
  }

  @override
  Future<List<QuickNote>> findRecent(int limit) async {
    return _run<List<QuickNote>>('查询最近笔记失败', (db) async {
      final rows = await db.query(
        DatabaseService.quickNotesTable,
        where: 'deletedAt IS NULL',
        orderBy: 'createdAt DESC',
        limit: limit,
      );
      return rows.map(QuickNote.fromMap).toList();
    });
  }

  @override
  Future<void> updateLinkedContact(String noteId, String contactId) async {
    await _run<void>('更新笔记关联联系人失败', (db) async {
      final count = await db.update(
        DatabaseService.quickNotesTable,
        {
          'linkedContactId': contactId,
          'noteType': 'structured',
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [noteId],
      );
      if (count == 0) {
        throw const DatabaseException(
          message: '笔记不存在，无法更新关联联系人',
          code: 'quick_note_not_found',
        );
      }
    });
  }

  @override
  Future<void> softDelete(String id) async {
    await _run<void>('删除笔记失败', (db) async {
      final count = await db.update(
        DatabaseService.quickNotesTable,
        {'deletedAt': DateTime.now().toIso8601String()},
        where: 'id = ? AND deletedAt IS NULL',
        whereArgs: [id],
      );
      if (count == 0) {
        throw const DatabaseException(
          message: '笔记不存在或已删除',
          code: 'quick_note_not_found',
        );
      }
    });
  }

  @override
  Future<void> clearAiMetadata(String id) async {
    await _run<void>('清除 AI 数据失败', (db) async {
      await db.update(
        DatabaseService.quickNotesTable,
        {
          'aiMetadata': null,
          'enrichedAt': null,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ? AND deletedAt IS NULL',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<QuickNote?> findById(String id) async {
    return _run<QuickNote?>('查询笔记失败', (db) async {
      final rows = await db.query(
        DatabaseService.quickNotesTable,
        where: 'id = ? AND deletedAt IS NULL',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return QuickNote.fromMap(rows.first);
    });
  }

  @override
  Future<List<QuickNote>> findUnenriched({int limit = 50}) async {
    return _run<List<QuickNote>>('查询未富化笔记失败', (db) async {
      final rows = await db.query(
        DatabaseService.quickNotesTable,
        where: 'enrichedAt IS NULL AND deletedAt IS NULL',
        orderBy: 'createdAt ASC',
        limit: limit,
      );
      return rows.map(QuickNote.fromMap).toList();
    });
  }

  @override
  Future<void> updateEnrichment(
    String noteId, {
    required Map<String, dynamic> aiMetadata,
    required DateTime enrichedAt,
  }) async {
    await _run<void>('写入富化结果失败', (db) async {
      final count = await db.update(
        DatabaseService.quickNotesTable,
        {
          'aiMetadata': json.encode(aiMetadata),
          'enrichedAt': enrichedAt.toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [noteId],
      );
      if (count == 0) {
        throw const DatabaseException(
          message: '笔记不存在，无法写入富化结果',
          code: 'quick_note_not_found',
        );
      }
    });
  }

  // ──────────────────── 内部工具 ────────────────────

  Future<T> _run<T>(String context, Future<T> Function(Database db) action) async {
    try {
      final db = await _databaseService.database;
      return await action(db);
    } on DatabaseException {
      rethrow;
    } catch (e) {
      throw DatabaseException(message: '$context: $e', code: 'db_error');
    }
  }
}
