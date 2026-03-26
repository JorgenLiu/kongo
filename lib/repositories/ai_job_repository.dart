import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../exceptions/app_exception.dart';
import '../models/ai_job.dart';
import '../models/ai_output.dart';
import '../services/database_service.dart';

abstract class AiJobRepository {
  Future<AiJob> getById(String id);
  Future<List<AiJob>> getByTarget(String targetType, String targetId);
  Future<AiJob> insert(AiJob job);
  Future<AiJob> update(AiJob job);
  Future<AiOutput> insertOutput(AiOutput output);
  Future<List<AiOutput>> getOutputs(String aiJobId);
}

class SqliteAiJobRepository implements AiJobRepository {
  final DatabaseService _databaseService;

  SqliteAiJobRepository(this._databaseService);

  @override
  Future<AiJob> getById(String id) async {
    return _run<AiJob>('获取 AI 作业失败', (db) async {
      final rows = await db.query(
        DatabaseService.aiJobsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw const DatabaseException(message: 'AI 作业不存在', code: 'ai_job_not_found');
      }
      return AiJob.fromMap(Map<String, dynamic>.from(rows.first));
    });
  }

  @override
  Future<List<AiJob>> getByTarget(String targetType, String targetId) async {
    return _run<List<AiJob>>('获取 AI 作业列表失败', (db) async {
      final rows = await db.query(
        DatabaseService.aiJobsTable,
        where: 'targetType = ? AND targetId = ?',
        whereArgs: [targetType, targetId],
        orderBy: 'createdAt DESC',
      );
      return rows.map((row) => AiJob.fromMap(Map<String, dynamic>.from(row))).toList();
    });
  }

  @override
  Future<AiJob> insert(AiJob job) async {
    return _run<AiJob>('创建 AI 作业失败', (db) async {
      await db.insert(DatabaseService.aiJobsTable, job.toMap());
      return getById(job.id);
    });
  }

  @override
  Future<AiJob> update(AiJob job) async {
    return _run<AiJob>('更新 AI 作业失败', (db) async {
      final count = await db.update(
        DatabaseService.aiJobsTable,
        job.toMap(),
        where: 'id = ?',
        whereArgs: [job.id],
      );
      if (count == 0) {
        throw const DatabaseException(message: 'AI 作业不存在，无法更新', code: 'ai_job_not_found');
      }
      return getById(job.id);
    });
  }

  @override
  Future<AiOutput> insertOutput(AiOutput output) async {
    return _run<AiOutput>('创建 AI 输出失败', (db) async {
      await db.insert(DatabaseService.aiOutputsTable, output.toMap());
      final rows = await db.query(
        DatabaseService.aiOutputsTable,
        where: 'id = ?',
        whereArgs: [output.id],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw const DatabaseException(message: 'AI 输出写入后未能读回', code: 'ai_output_read_back_failed');
      }
      return AiOutput.fromMap(Map<String, dynamic>.from(rows.first));
    });
  }

  @override
  Future<List<AiOutput>> getOutputs(String aiJobId) async {
    return _run<List<AiOutput>>('获取 AI 输出失败', (db) async {
      final rows = await db.query(
        DatabaseService.aiOutputsTable,
        where: 'aiJobId = ?',
        whereArgs: [aiJobId],
        orderBy: 'createdAt ASC',
      );
      return rows.map((row) => AiOutput.fromMap(Map<String, dynamic>.from(row))).toList();
    });
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
