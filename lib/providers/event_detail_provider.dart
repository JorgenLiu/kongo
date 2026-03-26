import 'base_provider.dart';
import '../services/read/event_read_service.dart';
import '../services/read/todo_read_service.dart';

class EventDetailProvider extends BaseProvider {
  final EventReadService _eventReadService;
  final TodoReadService _todoReadService;
  final String _eventId;

  EventDetailProvider(this._eventReadService, this._todoReadService, this._eventId);

  EventDetailReadModel? _data;
  List<TodoLinkedItemSummaryReadModel> _linkedTodoItems = const [];

  EventDetailReadModel? get data => _data;
  List<TodoLinkedItemSummaryReadModel> get linkedTodoItems => _linkedTodoItems;

  Future<void> load() async {
    await execute(() async {
      _data = await _eventReadService.getEventDetail(_eventId);
      try {
        _linkedTodoItems = await _todoReadService.getItemsLinkedToEvent(_eventId);
      } catch (_) {
        _linkedTodoItems = const [];
      }
      markInitialized();
    });
  }

  Future<void> refresh() => load();
}