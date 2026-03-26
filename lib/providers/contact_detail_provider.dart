import 'base_provider.dart';
import '../services/read/contact_read_service.dart';
import '../services/read/todo_read_service.dart';

class ContactDetailProvider extends BaseProvider {
  final ContactReadService _contactReadService;
  final TodoReadService _todoReadService;
  final String _contactId;

  ContactDetailProvider(this._contactReadService, this._todoReadService, this._contactId);

  ContactDetailReadModel? _data;
  List<TodoLinkedItemSummaryReadModel> _linkedTodoItems = const [];

  ContactDetailReadModel? get data => _data;
  List<TodoLinkedItemSummaryReadModel> get linkedTodoItems => _linkedTodoItems;

  Future<void> load() async {
    await execute(() async {
      _data = await _contactReadService.getContactDetail(_contactId);
      try {
        _linkedTodoItems = await _todoReadService.getItemsLinkedToContact(_contactId);
      } catch (_) {
        _linkedTodoItems = const [];
      }
      markInitialized();
    });
  }

  Future<void> refresh() => load();
}