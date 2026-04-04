import '../models/attachment.dart';
import '../models/contact.dart';
import '../models/event_summary.dart';
import '../models/quick_note.dart';
import '../repositories/info_tag_repository.dart';
import '../repositories/quick_note_repository.dart';
import '../services/attachment_service.dart';
import '../services/contact_service.dart';
import '../services/read/event_read_service.dart';
import '../services/summary_service.dart';
import 'base_provider.dart';

class GlobalSearchProvider extends BaseProvider {
  final ContactService _contactService;
  final EventReadService _eventReadService;
  final SummaryService _summaryService;
  final AttachmentService _attachmentService;
  final QuickNoteRepository _noteRepository;
  final InfoTagRepository? _infoTagRepository;

  GlobalSearchProvider(
    this._contactService,
    this._eventReadService,
    this._summaryService,
    this._attachmentService,
    this._noteRepository, {
    InfoTagRepository? infoTagRepository,
  }) : _infoTagRepository = infoTagRepository;

  String _keyword = '';
  List<Contact> _contacts = const [];
  List<EventListItemReadModel> _events = const [];
  List<DailySummary> _summaries = const [];
  List<Attachment> _attachments = const [];
  List<QuickNote> _notes = const [];
  List<Contact> _contactsByInfoTag = const [];

  String get keyword => _keyword;
  List<Contact> get contacts => _contacts;
  List<EventListItemReadModel> get events => _events;
  List<DailySummary> get summaries => _summaries;
  List<Attachment> get attachments => _attachments;
  List<QuickNote> get notes => _notes;
  List<Contact> get contactsByInfoTag => _contactsByInfoTag;
  bool get hasQuery => _keyword.trim().isNotEmpty;
  int get totalResults => _contacts.length + _events.length + _summaries.length + _attachments.length + _notes.length + _contactsByInfoTag.length;

  Future<void> search(String keyword) async {
    await execute(() async {
      _keyword = keyword;
      final normalizedKeyword = keyword.trim();
      if (normalizedKeyword.isEmpty) {
        _contacts = const [];
        _events = const [];
        _summaries = const [];
        _attachments = const [];
        _notes = const [];
        _contactsByInfoTag = const [];
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
      _attachments = _sortAttachments(
        await _attachmentService.searchAttachments(normalizedKeyword),
        normalizedKeyword,
      );
      _notes = _sortNotes(
        await _noteRepository.searchByKeyword(normalizedKeyword),
        normalizedKeyword,
      );

      // 按 info tag 名称搜索联系人（独立于普通联系人搜索）
      final infoTagRepo = _infoTagRepository;
      if (infoTagRepo != null) {
        final tagContactIds =
            await infoTagRepo.findContactIdsByTagKeyword(normalizedKeyword);
        // 排除已出现在 _contacts 中的联系人（避免重复）
        final existingIds = _contacts.map((c) => c.id).toSet();
        final newIds = tagContactIds.where((id) => !existingIds.contains(id)).toList();
        final tagContacts = <Contact>[];
        for (final id in newIds) {
          try {
            tagContacts.add(await _contactService.getContact(id));
          } catch (_) {}
        }
        _contactsByInfoTag = tagContacts;
      } else {
        _contactsByInfoTag = const [];
      }

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

  List<Attachment> _sortAttachments(List<Attachment> items, String keyword) {
    final sorted = [...items];
    sorted.sort((left, right) {
      final scoreCompare =
          _scoreAttachment(right, keyword).compareTo(_scoreAttachment(left, keyword));
      if (scoreCompare != 0) {
        return scoreCompare;
      }

      return right.updatedAt.compareTo(left.updatedAt);
    });
    return sorted;
  }

  int _scoreAttachment(Attachment attachment, String keyword) {
    return _scoreText(attachment.fileName, keyword,
            exact: 120, prefix: 90, contains: 70) +
        _scoreText(attachment.originalFileName ?? '', keyword,
            exact: 60, prefix: 50, contains: 40) +
        _scoreText(attachment.previewText ?? '', keyword,
            exact: 30, prefix: 25, contains: 20);
  }

  List<QuickNote> _sortNotes(List<QuickNote> items, String keyword) {
    final sorted = [...items];
    sorted.sort((left, right) {
      final scoreCompare = _scoreNote(right, keyword).compareTo(_scoreNote(left, keyword));
      if (scoreCompare != 0) return scoreCompare;
      return right.createdAt.compareTo(left.createdAt);
    });
    return sorted;
  }

  int _scoreNote(QuickNote note, String keyword) {
    final topicsStr = (note.aiMetadata?['topics'] as List?)
            ?.whereType<String>()
            .join(' ') ??
        '';
    return _scoreText(note.content, keyword, exact: 100, prefix: 80, contains: 60) +
        _scoreText(topicsStr, keyword, exact: 40, prefix: 30, contains: 20);
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