import 'dart:async';

import 'base_provider.dart';
import '../models/quick_note.dart';
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

  // ── 日期视图状态 ──
  DayNotesModel? _data;
  late DateTime _currentDate;

  DayNotesModel? get data => _data;
  DateTime get currentDate => _currentDate;

  // ── Filter / 分页状态 ──
  NotesFilter _filter = const NotesFilter.empty();
  List<QuickNote> _allNotes = const [];
  int _currentPage = 0;
  bool _hasMore = true;

  NotesFilter get filter => _filter;
  List<QuickNote> get allNotes => List.unmodifiable(_allNotes);
  bool get hasMore => _hasMore;

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
    if (_filter.isActive) {
      return _resetAndLoadPage();
    }
    return _load(_currentDate);
  }

  /// 切换联系人/事件过滤并重新加载第 0 页。
  Future<void> setFilter(NotesFilter filter) {
    _filter = filter;
    return _resetAndLoadPage();
  }

  /// 清除 filter 并返回日期视图。
  Future<void> clearFilter() {
    _filter = const NotesFilter.empty();
    _allNotes = const [];
    _currentPage = 0;
    _hasMore = true;
    return _load(_currentDate);
  }

  /// 加载下一页（filter 激活时使用）。
  Future<void> loadMore() {
    if (!_hasMore || loading) return Future.value();
    return _loadPage(_currentPage + 1);
  }

  Future<void> _resetAndLoadPage() async {
    _allNotes = const [];
    _currentPage = 0;
    _hasMore = true;
    return _loadPage(0);
  }

  Future<void> _loadPage(int page) async {
    await execute(() async {
      final results = await _readService.loadPage(page, _filter);
      if (page == 0) {
        _allNotes = results;
      } else {
        _allNotes = [..._allNotes, ...results];
      }
      _currentPage = page;
      _hasMore = results.length >= kNotesPageSize;
      markInitialized();
    });
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

  /// 软删除笔记并刷新当前视图。
  Future<void> deleteNote(String noteId) async {
    await execute(() async {
      await _captureService?.deleteNote(noteId);
      if (_filter.isActive) {
        await _resetAndLoadPage();
      } else {
        _data = await _readService.loadDay(_currentDate);
      }
    });
  }

  /// 清除笔记的 topics 并刷新当前视图。
  Future<void> clearNoteTopics(String noteId) async {
    await execute(() async {
      await _captureService?.clearNoteTopics(noteId);
      if (_filter.isActive) {
        await _resetAndLoadPage();
      } else {
        _data = await _readService.loadDay(_currentDate);
      }
    });
  }
}
