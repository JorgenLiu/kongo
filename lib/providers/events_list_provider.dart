import 'base_provider.dart';
import '../models/event_type.dart';
import '../services/event_service.dart';
import '../services/read/event_read_service.dart';

class EventsListProvider extends BaseProvider {
  final EventReadService _eventReadService;
  final EventService _eventService;
  final String? _contactId;
  String _keyword = '';
  String? _selectedEventTypeId;

  EventsListProvider(
    this._eventReadService,
    this._eventService, {
    String? contactId,
  }) : _contactId = contactId;

  EventsListReadModel? _data;
  List<EventType> _eventTypes = const [];

  EventsListReadModel? get data => _data;
  String get keyword => _keyword;
  String? get selectedEventTypeId => _selectedEventTypeId;
  List<EventType> get eventTypes => _eventTypes;

  Future<void> load() async {
    await execute(() async {
      _keyword = '';
      _selectedEventTypeId = null;
      _eventTypes = await _eventService.getEventTypes();
      _data = await _eventReadService.getEventsList(contactId: _contactId);
      markInitialized();
    });
  }

  Future<void> searchByKeyword(String keyword) async {
    await execute(() async {
      _keyword = keyword;
      _data = await _loadCurrentView();
      markInitialized();
    });
  }

  Future<void> filterByEventType(String? eventTypeId) async {
    await execute(() async {
      _selectedEventTypeId = eventTypeId?.trim().isEmpty ?? true ? null : eventTypeId;
      _data = await _loadCurrentView();
      markInitialized();
    });
  }

  Future<void> clearFilters() => load();

  Future<void> refresh() async {
    await execute(() async {
      _data = await _loadCurrentView();
      markInitialized();
    });
  }

  Future<EventsListReadModel> _loadCurrentView() {
    return _eventReadService.searchEventsList(
      contactId: _contactId,
      keyword: _keyword,
      eventTypeId: _selectedEventTypeId,
    );
  }
}