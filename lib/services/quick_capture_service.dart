import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../repositories/quick_note_repository.dart';
import 'database_service.dart';

abstract class QuickCaptureService {
  /// 立即存储原始输入，不做解析。内容 trim 后为空则忽略。
  /// noteType 固定为 'knowledge'，不关联联系人。
  Future<void> saveRawNote(String content);

  /// 存储一条经过解析的 note，可携带联系人关联和 noteType。
  /// [linkedContactId] 非 null 时关联到已有联系人.
  /// [noteType] 默认 'knowledge'；关联联系人后传 'structured'.
  /// [aiMetadata] AI 解析结果，序列化后写入 aiMetadata 字段。
  /// 内容 trim 后为空则忽略。
  Future<void> saveNote(
    String content, {
    String? linkedContactId,
    String? linkedEventId,
    String noteType = 'knowledge',
    Map<String, dynamic>? aiMetadata,
  });

  /// 软删除笔记（设置 deletedAt）。
  Future<void> deleteNote(String noteId);

  /// 清除笔记的 AI 提取字段（aiMetadata + enrichedAt）。
  Future<void> clearNoteTopics(String noteId);
}

class DefaultQuickCaptureService implements QuickCaptureService {
  final DatabaseService _databaseService;
  final QuickNoteRepository _quickNoteRepository;
  final Uuid _uuid;

  /// 上一条 note 的写入时间，用于会话分组判断。
  DateTime? _lastNoteTime;

  /// 当前会话分组 ID（30 分钟内复用同一 sessionGroup）。
  String? _currentSessionGroup;

  static const Duration _sessionWindow = Duration(minutes: 30);

  DefaultQuickCaptureService(
    this._databaseService,
    this._quickNoteRepository, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  // ──────────────────── 公开方法 ────────────────────

  @override
  Future<void> saveRawNote(String content) {
    return saveNote(content);
  }

  @override
  Future<void> saveNote(
    String content, {
    String? linkedContactId,
    String? linkedEventId,
    String noteType = 'knowledge',
    Map<String, dynamic>? aiMetadata,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    final db = await _databaseService.database;
    final now = DateTime.now();
    final captureDate =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final nowIso = now.toIso8601String();

    await db.insert(
      DatabaseService.quickNotesTable,
      {
        'id': _uuid.v4(),
        'content': trimmed,
        'noteType': noteType,
        'linkedContactId': linkedContactId,
        'linkedEventId': linkedEventId,
        'sessionGroup': _resolveSessionGroup(now),
        'aiMetadata': aiMetadata != null ? json.encode(aiMetadata) : null,
        'enrichedAt': null,
        'captureDate': captureDate,
        'createdAt': nowIso,
        'updatedAt': nowIso,
        'deletedAt': null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ──────────────────── 内部方法 ────────────────────

  /// 判断当前 note 是否属于活跃会话；超过 [_sessionWindow] 则开启新会话。
  String _resolveSessionGroup(DateTime now) {
    final last = _lastNoteTime;
    if (last == null || now.difference(last) > _sessionWindow) {
      _currentSessionGroup = _uuid.v4();
    }
    _lastNoteTime = now;
    return _currentSessionGroup!;
  }

  @override
  Future<void> deleteNote(String noteId) {
    return _quickNoteRepository.softDelete(noteId);
  }

  @override
  Future<void> clearNoteTopics(String noteId) {
    return _quickNoteRepository.clearAiMetadata(noteId);
  }
}
