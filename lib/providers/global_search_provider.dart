import '../models/contact.dart';
import '../models/event_summary.dart';
import '../services/contact_service.dart';
import '../services/read/event_read_service.dart';
import '../services/summary_service.dart';
import 'base_provider.dart';

class GlobalSearchProvider extends BaseProvider {
  final ContactService _contactService;
  final EventReadService _eventReadService;
  final SummaryService _summaryService;

  GlobalSearchProvider(
    this._contactService,
    this._eventReadService,
    this._summaryService,
  );

  String _keyword = '';
  List<Contact> _contacts = const [];
  List<EventListItemReadModel> _events = const [];
  List<DailySummary> _summaries = const [];

  String get keyword => _keyword;
  List<Contact> get contacts => _contacts;
  List<EventListItemReadModel> get events => _events;
  List<DailySummary> get summaries => _summaries;
  bool get hasQuery => _keyword.trim().isNotEmpty;
  int get totalResults => _contacts.length + _events.length + _summaries.length;

  Future<void> search(String keyword) async {
    await execute(() async {
      _keyword = keyword;
      final normalizedKeyword = keyword.trim();
      if (normalizedKeyword.isEmpty) {
        _contacts = const [];
        _events = const [];
        _summaries = const [];
        markInitialized(false);
        return;
      }

      _contacts = _sortContacts(
        await _contactService.searchByKeyword(normalizedKeyword),
        normalizedKeyword,
      );
      final eventResults = await _eventReadService.searchEventsList(keyword: normalizedKeyword);
      _events = _sortEvents(eventResults.items, normalizedKeyword);
      _summaries = _sortSummaries(
        await _summaryService.searchByKeyword(normalizedKeyword),
        normalizedKeyword,
      );
      markInitialized();
    });
  }

  List<Contact> _sortContacts(List<Contact> items, String keyword) {
    final sorted = [...items];
    sorted.sort((left, right) {
      final scoreCompare = _scoreContact(right, keyword).compareTo(_scoreContact(left, keyword));
      if (scoreCompare != 0) {
        return scoreCompare;
      }

      return right.updatedAt.compareTo(left.updatedAt);
    });
    return sorted;
  }

  List<EventListItemReadModel> _sortEvents(List<EventListItemReadModel> items, String keyword) {
    final sorted = [...items];
    sorted.sort((left, right) {
      final scoreCompare = _scoreEvent(right, keyword).compareTo(_scoreEvent(left, keyword));
      if (scoreCompare != 0) {
        return scoreCompare;
      }

      final rightTime = right.event.startAt ?? right.event.updatedAt;
      final leftTime = left.event.startAt ?? left.event.updatedAt;
      return rightTime.compareTo(leftTime);
    });
    return sorted;
  }

  List<DailySummary> _sortSummaries(List<DailySummary> items, String keyword) {
    final sorted = [...items];
    sorted.sort((left, right) {
      final scoreCompare = _scoreSummary(right, keyword).compareTo(_scoreSummary(left, keyword));
      if (scoreCompare != 0) {
        return scoreCompare;
      }

      return right.summaryDate.compareTo(left.summaryDate);
    });
    return sorted;
  }

  int _scoreContact(Contact contact, String keyword) {
    return _scoreText(contact.name, keyword, exact: 120, prefix: 90, contains: 70) +
        _scoreText(contact.phone ?? '', keyword, exact: 60, prefix: 50, contains: 40) +
        _scoreText(contact.email ?? '', keyword, exact: 50, prefix: 40, contains: 30) +
        _scoreText(contact.notes ?? '', keyword, exact: 25, prefix: 20, contains: 15);
  }

  int _scoreEvent(EventListItemReadModel item, String keyword) {
    return _scoreText(item.event.title, keyword, exact: 120, prefix: 90, contains: 70) +
        _scoreText(item.event.location ?? '', keyword, exact: 60, prefix: 45, contains: 35) +
        _scoreText(item.event.description ?? '', keyword, exact: 55, prefix: 40, contains: 30) +
        _scoreText(item.eventTypeName ?? '', keyword, exact: 45, prefix: 35, contains: 25) +
        _scoreText(item.participantNames.join('、'), keyword, exact: 35, prefix: 28, contains: 20);
  }

  int _scoreSummary(DailySummary summary, String keyword) {
    return _scoreText(summary.todaySummary, keyword, exact: 100, prefix: 80, contains: 60) +
        _scoreText(summary.tomorrowPlan, keyword, exact: 90, prefix: 70, contains: 55);
  }

  int _scoreText(
    String source,
    String keyword, {
    required int exact,
    required int prefix,
    required int contains,
  }) {
    final normalizedSource = source.trim().toLowerCase();
    final normalizedKeyword = keyword.trim().toLowerCase();
    if (normalizedSource.isEmpty || normalizedKeyword.isEmpty) {
      return 0;
    }
    if (normalizedSource == normalizedKeyword) {
      return exact;
    }
    if (normalizedSource.startsWith(normalizedKeyword)) {
      return prefix;
    }
    if (normalizedSource.contains(normalizedKeyword)) {
      return contains;
    }
    return 0;
  }
}