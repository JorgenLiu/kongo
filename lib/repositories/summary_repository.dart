import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../exceptions/app_exception.dart';
import '../models/event_summary.dart';
import '../services/database_service.dart';

abstract class SummaryRepository {
  Future<List<DailySummary>> getAll();
  Future<List<DailySummary>> searchByKeyword(String keyword);
  Future<DailySummary?> getByDate(DateTime summaryDate);
  Future<DailySummary> getById(String id);
  Future<bool> exists(String id);
  Future<DailySummary> insert(DailySummary summary);
  Future<DailySummary> update(DailySummary summary);
  Future<void> delete(String id);
}

class SqliteSummaryRepository implements SummaryRepository {
  final DatabaseService _databaseService;

  SqliteSummaryRepository(this._databaseService);

  @override
  Future<List<DailySummary>> getAll() async {
    return _run<List<DailySummary>>('获取总结列表失败', (db) async {
      final rows = await db.query(
        DatabaseService.summariesTable,
        orderBy: 'summaryDate DESC, updatedAt DESC',
      );
      return rows.map(_toSummary).toList();
    });
  }

  @override
  Future<List<DailySummary>> searchByKeyword(String keyword) async {
    return _run<List<DailySummary>>('搜索总结失败', (db) async {
      final normalizedKeyword = keyword.trim();
      if (normalizedKeyword.isEmpty) {
        return getAll();
      }

      final likeKeyword = '%$normalizedKeyword%';
      final rows = await db.query(
        DatabaseService.summariesTable,
        where: 'todaySummary LIKE ? OR tomorrowPlan LIKE ?',
        whereArgs: [likeKeyword, likeKeyword],
        orderBy: 'summaryDate DESC, updatedAt DESC',
      );
      return rows.map(_toSummary).toList();
    });
  }

  @override
  Future<DailySummary?> getByDate(DateTime summaryDate) async {
    return _run<DailySummary?>('获取当日总结失败', (db) async {
      final rows = await db.query(
        DatabaseService.summariesTable,
        where: 'summaryDate = ?',
        whereArgs: [_normalizeDate(summaryDate).millisecondsSinceEpoch],
        limit: 1,
      );
      if (rows.isEmpty) {
        return null;
      }
      return _toSummary(rows.first);
    });
  }

  @override
  Future<DailySummary> getById(String id) async {
    return _run<DailySummary>('获取总结失败', (db) async {
      final rows = await db.query(
        DatabaseService.summariesTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw const DatabaseException(message: '总结不存在', code: 'summary_not_found');
      }
      return _toSummary(rows.first);
    });
  }

  @override
  Future<bool> exists(String id) async {
    return _run<bool>('检查总结失败', (db) async {
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM ${DatabaseService.summariesTable} WHERE id = ?',
        [id],
      );
      return ((rows.first['count'] as num?)?.toInt() ?? 0) > 0;
    });
  }

  @override
  Future<DailySummary> insert(DailySummary summary) async {
    return _run<DailySummary>('创建总结失败', (db) async {
      await db.insert(DatabaseService.summariesTable, summary.toMap());
      return getById(summary.id);
    });
  }

  @override
  Future<DailySummary> update(DailySummary summary) async {
    return _run<DailySummary>('更新总结失败', (db) async {
      final count = await db.update(
        DatabaseService.summariesTable,
        summary.toMap(),
        where: 'id = ?',
        whereArgs: [summary.id],
      );
      if (count == 0) {
        throw const DatabaseException(message: '总结不存在，无法更新', code: 'summary_not_found');
      }
      return getById(summary.id);
    });
  }

  @override
  Future<void> delete(String id) async {
    await _run<void>('删除总结失败', (db) async {
      final count = await db.delete(
        DatabaseService.summariesTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count == 0) {
        throw const DatabaseException(message: '总结不存在，无法删除', code: 'summary_not_found');
      }
    });
  }

  DailySummary _toSummary(Map<String, Object?> row) {
    return DailySummary.fromMap(Map<String, dynamic>.from(row));
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
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