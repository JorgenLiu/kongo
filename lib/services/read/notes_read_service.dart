import '../../models/event_summary.dart';
import '../../models/quick_note.dart';
import '../../repositories/quick_note_repository.dart';
import '../../repositories/summary_repository.dart';

/// 按天聚合的"记录"读取服务。
abstract class NotesReadService {
  /// 加载指定日期的全部笔记 + 当日总结。
  Future<DayNotesModel> loadDay(DateTime date);

  /// 查询某一日期是否有任何笔记，用于导航指示。
  Future<int> countForDate(DateTime date);
}

/// 一个会话分组（同一 sessionGroup ID 的连续输入）。
class CaptureSession {
  final String? sessionId;
  final DateTime startAt;
  final DateTime endAt;
  final List<QuickNote> notes;

  const CaptureSession({
    required this.sessionId,
    required this.startAt,
    required this.endAt,
    required this.notes,
  });
}

/// 一天的完整笔记聚合。
class DayNotesModel {
  final DateTime date;
  final List<CaptureSession> sessions;
  final DailySummary? summary;

  const DayNotesModel({
    required this.date,
    required this.sessions,
    required this.summary,
  });

  bool get isEmpty => sessions.isEmpty && summary == null;
}

class DefaultNotesReadService implements NotesReadService {
  final QuickNoteRepository _noteRepository;
  final SummaryRepository _summaryRepository;

  DefaultNotesReadService(this._noteRepository, this._summaryRepository);

  @override
  Future<DayNotesModel> loadDay(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    final notes = await _noteRepository.findByDate(normalizedDate);
    final summary = await _summaryRepository.getByDate(normalizedDate);
    final sessions = _groupIntoSessions(notes);

    return DayNotesModel(
      date: normalizedDate,
      sessions: sessions,
      summary: summary,
    );
  }

  @override
  Future<int> countForDate(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final notes = await _noteRepository.findByDate(normalizedDate);
    return notes.length;
  }

  /// 将 note 列表按 sessionGroup 分组，保持 createdAt 升序。
  ///
  /// - 有 sessionGroup 的 notes 按 ID 归组。
  /// - sessionGroup 为 null 的每条 note 各自独立构成 session。
  List<CaptureSession> _groupIntoSessions(List<QuickNote> notes) {
    if (notes.isEmpty) return const [];

    // 保持按 createdAt 升序，findByDate 已排好序
    final grouped = <String?, List<QuickNote>>{};
    final sessionOrder = <String?>[];

    for (final note in notes) {
      final key = note.sessionGroup;
      if (!grouped.containsKey(key)) {
        // null key 需要唯一标识（每条独立），用 object identity 区分
        if (key == null) {
          // 对 null sessionGroup 的 note：每条独立存储（用 note.id 作为虚拟 key）
          grouped[note.id] = [note];
          sessionOrder.add(note.id);
        } else {
          grouped[key] = [note];
          sessionOrder.add(key);
        }
      } else {
        grouped[key]!.add(note);
      }
    }

    return sessionOrder.map((key) {
      final sessionNotes = grouped[key]!;
      return CaptureSession(
        sessionId: sessionNotes.first.sessionGroup,
        startAt: sessionNotes.first.createdAt,
        endAt: sessionNotes.last.createdAt,
        notes: sessionNotes,
      );
    }).toList();
  }
}
