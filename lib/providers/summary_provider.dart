import '../models/action_item.dart';
import '../models/event_summary.dart';
import '../models/event_summary_draft.dart';
import '../services/summary_service.dart';
import 'base_provider.dart';

class SummaryProvider extends BaseProvider {
  final SummaryService _summaryService;

  SummaryProvider(this._summaryService);

  List<DailySummary> _summaries = const [];
  DailySummary? _currentSummary;
  List<ActionItem> _actionItems = const [];
  String _keyword = '';

  List<DailySummary> get summaries => _summaries;
  DailySummary? get currentSummary => _currentSummary;
  List<ActionItem> get actionItems => _actionItems;
  String get keyword => _keyword;

  void resetDetailState() {
    final shouldNotify = _currentSummary != null || _actionItems.isNotEmpty || initialized;
    _currentSummary = null;
    _actionItems = const [];
    markInitialized(false);
    if (error != null) {
      clearError();
      return;
    }

    if (shouldNotify) {
      notifyListeners();
    }
  }

  Future<void> loadSummaries() async {
    await execute(() async {
      _keyword = '';
      _summaries = await _summaryService.getSummaries();
      markInitialized();
    });
  }

  Future<void> searchByKeyword(String keyword) async {
    await execute(() async {
      _keyword = keyword;
      _summaries = await _summaryService.searchByKeyword(keyword);
      markInitialized();
    });
  }

  Future<void> clearFilters() async {
    await loadSummaries();
  }

  Future<void> createSummary(DailySummaryDraft draft) async {
    await execute(() async {
      _currentSummary = await _summaryService.createSummary(draft);
      await _reloadCurrentView();
      _actionItems = await _summaryService.extractActionItemsFromSummary(_currentSummary!.id);
      markInitialized(true);
    });
  }

  Future<void> updateSummary(DailySummary summary) async {
    await execute(() async {
      _currentSummary = await _summaryService.updateSummary(summary);
      await _reloadCurrentView();
      _actionItems = await _summaryService.extractActionItemsFromSummary(summary.id);
      markInitialized(true);
    });
  }

  Future<void> deleteSummary(String id) async {
    await execute(() async {
      await _summaryService.deleteSummary(id);
      await _reloadCurrentView();
      if (_currentSummary?.id == id) {
        _currentSummary = null;
        _actionItems = const [];
        markInitialized(false);
      }
    });
  }

  Future<void> loadSummaryDetail(String summaryId) async {
    await _resetAndLoadDetail(() async {
      _currentSummary = await _summaryService.getSummary(summaryId);
      _actionItems = await _summaryService.extractActionItemsFromSummary(summaryId);
    });
  }

  Future<void> loadSummaryByDate(DateTime summaryDate) async {
    await _resetAndLoadDetail(() async {
      _currentSummary = await _summaryService.getSummaryByDate(summaryDate);
      if (_currentSummary != null) {
        _actionItems = await _summaryService.extractActionItemsFromSummary(_currentSummary!.id);
      }
    });
  }

  Future<void> _resetAndLoadDetail(Future<void> Function() loader) async {
    _currentSummary = null;
    _actionItems = const [];
    markInitialized(false);

    await execute(() async {
      await loader();
      markInitialized(true);
    });
  }

  Future<void> loadActionItems(String summaryId) async {
    await execute(() async {
      _actionItems = await _summaryService.extractActionItemsFromSummary(summaryId);
      markInitialized();
    });
  }

  Future<void> _reloadCurrentView() async {
    if (_keyword.trim().isEmpty) {
      _summaries = await _summaryService.getSummaries();
      return;
    }

    _summaries = await _summaryService.searchByKeyword(_keyword);
  }
}