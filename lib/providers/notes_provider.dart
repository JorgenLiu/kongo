import 'dart:async';

import 'base_provider.dart';
import '../services/quick_capture_service.dart';
import '../services/quick_note_enrichment_service.dart';
import '../services/read/notes_read_service.dart';

class NotesProvider extends BaseProvider {
  final NotesReadService _readService;
  final QuickCaptureService? _captureService;
  final QuickNoteEnrichmentService? _enrichmentService;

  NotesProvider(
    this._readService, {
    QuickCaptureService? captureService,
    QuickNoteEnrichmentService? enrichmentService,
  })  : _captureService = captureService,
        _enrichmentService = enrichmentService;

  DayNotesModel? _data;
  late DateTime _currentDate;

  DayNotesModel? get data => _data;
  DateTime get currentDate => _currentDate;

  /// 初始化并加载今日数据。
  Future<void> loadToday() {
    final today = DateTime.now();
    _currentDate = DateTime(today.year, today.month, today.day);
    return _load(_currentDate);
  }

  /// 切换到指定日期并重新加载。
  Future<void> navigateToDate(DateTime date) {
    _currentDate = DateTime(date.year, date.month, date.day);
    return _load(_currentDate);
  }

  /// 当前日期数据刷新（笔记内容更新后调用）。
  Future<void> refresh() {
    if (!initialized) {
      return loadToday();
    }
    return _load(_currentDate);
  }

  Future<void> _load(DateTime date) async {
    await execute(() async {
      _data = await _readService.loadDay(date);
      markInitialized();
    });
    _triggerEnrichment();
  }

  /// 后台触发富化，不阻塞加载，不抛错。
  void _triggerEnrichment() {
    final service = _enrichmentService;
    if (service == null) return;
    unawaited(service.enrichPending().catchError((_) {}));
  }

  /// 软删除笔记并刷新当前日期视图。
  Future<void> deleteNote(String noteId) async {
    await execute(() async {
      await _captureService?.deleteNote(noteId);
      _data = await _readService.loadDay(_currentDate);
    });
  }

  /// 清除笔记的 topics 并刷新当前日期视图。
  Future<void> clearNoteTopics(String noteId) async {
    await execute(() async {
      await _captureService?.clearNoteTopics(noteId);
      _data = await _readService.loadDay(_currentDate);
    });
  }
}
