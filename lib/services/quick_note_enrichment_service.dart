import 'dart:convert';

import '../ai/ai_provider.dart';
import '../ai/ai_service.dart';
import '../repositories/quick_note_repository.dart';

/// 负责对 quick_notes 发起 AI 富化，提取主题、实体、回顾建议等语义信息。
///
/// 原则：
/// - AI 不可用时静默跳过，不抛错
/// - 每条 note 最多富化一次（enrichedAt 非 null 表示已处理）
/// - 富化失败不影响任何主流程
abstract class QuickNoteEnrichmentService {
  /// 富化单条笔记，写入 aiMetadata 并更新 enrichedAt。
  Future<void> enrichNote(String noteId);

  /// 批量富化所有 enrichedAt=null 的笔记（后台启动时调用）。
  Future<void> enrichPending();
}

class DefaultQuickNoteEnrichmentService implements QuickNoteEnrichmentService {
  final AiService _aiService;
  final QuickNoteRepository _repository;

  DefaultQuickNoteEnrichmentService(this._aiService, this._repository);

  @override
  Future<void> enrichNote(String noteId) async {
    if (!_aiService.isAvailable) return;

    final note = await _repository.findById(noteId);
    if (note == null || note.enrichedAt != null) return;

    try {
      final result = await _aiService.execute(AiRequest(
        feature: 'quick_note_enrichment',
        targetType: 'quick_note',
        targetId: noteId,
        outputType: 'enrichment_metadata',
        messages: [
          const AiMessage.system(_kSystemPrompt),
          AiMessage.user(note.content),
        ],
      ));

      final parsed = _parseResponse(result.output.content);
      if (parsed != null) {
        await _repository.updateEnrichment(
          noteId,
          aiMetadata: parsed,
          enrichedAt: DateTime.now(),
        );
      }
    } catch (_) {
      // 富化失败不影响主流程，静默忽略
    }
  }

  @override
  Future<void> enrichPending() async {
    if (!_aiService.isAvailable) return;

    final pending = await _repository.findUnenriched();
    for (final note in pending) {
      await enrichNote(note.id);
    }
  }

  /// 从 AI 响应文本中提取 JSON 对象，容忍前导/尾随文本。
  Map<String, dynamic>? _parseResponse(String content) {
    try {
      final trimmed = content.trim();
      final start = trimmed.indexOf('{');
      final end = trimmed.lastIndexOf('}');
      if (start == -1 || end == -1 || end <= start) return null;
      final jsonStr = trimmed.substring(start, end + 1);
      final decoded = json.decode(jsonStr);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }
}

const _kSystemPrompt = '''你是一个帮助提取笔记语义的助手。
对给定的一条笔记，请提取以下字段并以 JSON 格式返回（只返回 JSON，不要任何其他内容）：

{
  "topics": ["主题1", "主题2"],
  "entities": [{"type": "person", "name": "实体名"}, {"type": "org", "name": "组织名"}],
  "sessionLabel": "不超过6个字的会话标题",
  "resurfaceAt": "ISO 8601 格式的建议回顾时间，如无时效性则为 null"
}

type 可选值：person（人物）、org（组织）、topic（话题）。
若某字段无合适内容，topics 返回空数组，entities 返回空数组，sessionLabel 返回 null，resurfaceAt 返回 null。''';
