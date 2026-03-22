import '../models/contact.dart';
import '../models/event.dart';
import '../models/event_draft.dart';
import '../models/event_type.dart';
import '../services/contact_service.dart';
import '../services/event_service.dart';
import 'base_provider.dart';

class EventProvider extends BaseProvider {
  final EventService _eventService;
  final ContactService _contactService;

  EventProvider(this._eventService, this._contactService);

  Event? _currentEvent;
  List<Contact> _participants = const [];
  List<Contact> _availableContacts = const [];
  List<EventType> _eventTypes = const [];

  Event? get currentEvent => _currentEvent;
  List<Contact> get participants => _participants;
  List<Contact> get availableContacts => _availableContacts;
  List<EventType> get eventTypes => _eventTypes;

  Future<void> loadFormOptions({bool force = false}) async {
    if (!force && _availableContacts.isNotEmpty && _eventTypes.isNotEmpty) {
      markInitialized();
      return;
    }

    await execute(() async {
      _availableContacts = await _contactService.getContacts();
      _eventTypes = await _eventService.getEventTypes();
      markInitialized();
    });
  }

  Future<void> createEvent(EventDraft draft) async {
    await execute(() async {
      _currentEvent = await _eventService.createEvent(draft);
      _participants = await _eventService.getParticipants(_currentEvent!.id);
    });
  }

  Future<void> updateEvent(
    Event event,
    List<String> participantIds, {
    Map<String, String>? participantRoles,
  }) async {
    await execute(() async {
      final updatedEvent = await _eventService.updateEvent(event);
      await _eventService.setParticipants(
        updatedEvent.id,
        participantIds,
        participantRoles: participantRoles,
      );
      _currentEvent = await _eventService.getEvent(updatedEvent.id);
      _participants = await _eventService.getParticipants(updatedEvent.id);
    });
  }

  Future<void> deleteEvent(String id) async {
    await execute(() async {
      await _eventService.deleteEvent(id);
      if (_currentEvent?.id == id) {
        _currentEvent = null;
        _participants = const [];
      }
    });
  }
}