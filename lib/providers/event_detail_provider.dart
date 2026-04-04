import 'base_provider.dart';
import '../models/quick_note.dart';
import '../services/read/event_read_service.dart';
import '../services/read/notes_read_service.dart';
import '../services/read/todo_read_service.dart';

class EventDetailProvider extends BaseProvider {
  final EventReadService _eventReadService;
  final TodoReadService _todoReadService;
  final NotesReadService? _notesReadService;
  final String _eventId;

  EventDetailProvider(
    this._eventReadService,
    this._todoReadService,
    this._eventId, {
    NotesReadService? notesReadService,
  }) : _notesReadService = notesReadService;

  EventDetailReadModel? _data;
  List<TodoLinkedItemSummaryReadModel> _linkedTodoItems = const [];
  List<QuickNote> _linkedNotes = const [];

  EventDetailReadModel? get data => _data;
  List<TodoLinkedItemSummaryReadModel> get linkedTodoItems => _linkedTodoItems;
  List<QuickNote> get linkedNotes => _linkedNotes;

  Future<void> load() async {
    await execute(() async {
      _data = await _eventReadService.getEventDetail(_eventId);
      try {
        _linkedTodoItems = await _todoReadService.getItemsLinkedToEvent(_eventId);
      } catch (_) {
        _linkedTodoItems = const [];
      }
      try {
        _linkedNotes = await _notesReadService?.findByEventId(_eventId) ?? const [];
      } catch (_) {
        _linkedNotes = const [];
      }
      markInitialized();
    });
  }

  Future<void> refresh() => load();
}