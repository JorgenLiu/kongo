import 'base_provider.dart';
import '../models/quick_note.dart';
import '../services/read/contact_read_service.dart';
import '../services/read/notes_read_service.dart';
import '../services/read/todo_read_service.dart';

class ContactDetailProvider extends BaseProvider {
  final ContactReadService _contactReadService;
  final TodoReadService _todoReadService;
  final NotesReadService? _notesReadService;
  final String _contactId;

  ContactDetailProvider(
    this._contactReadService,
    this._todoReadService,
    this._contactId, {
    NotesReadService? notesReadService,
  }) : _notesReadService = notesReadService;

  ContactDetailReadModel? _data;
  List<TodoLinkedItemSummaryReadModel> _linkedTodoItems = const [];
  List<QuickNote> _linkedNotes = const [];

  ContactDetailReadModel? get data => _data;
  List<TodoLinkedItemSummaryReadModel> get linkedTodoItems => _linkedTodoItems;
  List<QuickNote> get linkedNotes => _linkedNotes;

  Future<void> load() async {
    await execute(() async {
      _data = await _contactReadService.getContactDetail(_contactId);
      try {
        _linkedTodoItems = await _todoReadService.getItemsLinkedToContact(_contactId);
      } catch (_) {
        _linkedTodoItems = const [];
      }
      try {
        _linkedNotes = await _notesReadService?.findByContactId(_contactId) ?? const [];
      } catch (_) {
        _linkedNotes = const [];
      }
      markInitialized();
    });
  }

  Future<void> refresh() => load();
}