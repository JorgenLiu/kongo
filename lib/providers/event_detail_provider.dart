import 'base_provider.dart';
import '../services/read/event_read_service.dart';

class EventDetailProvider extends BaseProvider {
  final EventReadService _eventReadService;
  final String _eventId;

  EventDetailProvider(this._eventReadService, this._eventId);

  EventDetailReadModel? _data;

  EventDetailReadModel? get data => _data;

  Future<void> load() async {
    await execute(() async {
      _data = await _eventReadService.getEventDetail(_eventId);
      markInitialized();
    });
  }

  Future<void> refresh() => load();
}