import '../../models/attachment.dart';
import '../../models/attachment_link.dart';
import '../../models/contact.dart';
import '../../models/event.dart';
import '../../models/event_participant.dart';
import '../../repositories/attachment_repository.dart';
import '../../repositories/contact_repository.dart';
import '../../repositories/event_repository.dart';
import '../../utils/event_participant_roles.dart';
import 'read_aggregation_helpers.dart';

abstract class EventReadService {
  Future<EventsListReadModel> getEventsList({String? contactId});
  Future<EventsListReadModel> searchEventsList({
    String? contactId,
    String? keyword,
    String? eventTypeId,
  });
  Future<EventDetailReadModel> getEventDetail(String eventId);
}

class DefaultEventReadService implements EventReadService {
  final ContactRepository _contactRepository;
  final EventRepository _eventRepository;
  final AttachmentRepository _attachmentRepository;

  DefaultEventReadService(
    this._contactRepository,
    this._eventRepository,
    this._attachmentRepository,
  );

  @override
  Future<EventsListReadModel> getEventsList({String? contactId}) async {
    return searchEventsList(contactId: contactId);
  }

  @override
  Future<EventsListReadModel> searchEventsList({
    String? contactId,
    String? keyword,
    String? eventTypeId,
  }) async {
    Contact? contact;
    late final List<Event> events;
    if (contactId != null) {
      contact = await _contactRepository.getById(contactId);
      final relatedEvents = await _eventRepository.getByContactId(contactId);
      events = relatedEvents.where((event) {
        if (eventTypeId != null && eventTypeId.trim().isNotEmpty && event.eventTypeId != eventTypeId) {
          return false;
        }

        final normalizedKeyword = keyword?.trim().toLowerCase();
        if (normalizedKeyword == null || normalizedKeyword.isEmpty) {
          return true;
        }

        return [event.title, event.location, event.description]
            .whereType<String>()
            .map((value) => value.toLowerCase())
            .any((value) => value.contains(normalizedKeyword));
      }).toList();
    } else {
      events = await _eventRepository.search(
        keyword: keyword,
        eventTypeId: eventTypeId,
      );
    }

    return _buildEventsListReadModel(contact: contact, events: events);
  }

  Future<EventsListReadModel> _buildEventsListReadModel({
    required Contact? contact,
    required List<Event> events,
  }) async {

    final eventTypeNames = buildEventTypeNames(await _eventRepository.getEventTypes());
    final participantsByEventId = await _eventRepository.getParticipantsByEventIds(
      events.map((event) => event.id).toList(),
    );

    final items = events
        .map(
          (event) => EventListItemReadModel(
            event: event,
            eventTypeName: eventTypeNames[event.eventTypeId],
            participantNames: (participantsByEventId[event.id] ?? const <Contact>[])
                .map((item) => item.name)
                .toList(),
          ),
        )
        .toList();

    return EventsListReadModel(
      contact: contact,
      items: items,
    );
  }

  @override
  Future<EventDetailReadModel> getEventDetail(String eventId) async {
    final event = await _eventRepository.getById(eventId);
    final eventTypeNames = buildEventTypeNames(await _eventRepository.getEventTypes());
    final participants = await _eventRepository.getParticipants(eventId);
    final participantLinks = await _eventRepository.getParticipantLinks(eventId);
    final attachments = await _attachmentRepository.getByOwner(
      AttachmentOwnerType.event,
      eventId,
    );

    Contact? createdByContact;
    if (event.createdByContactId != null) {
      createdByContact = await _contactRepository.getById(event.createdByContactId!);
    }

    final contactsById = {
      for (final participant in participants) participant.id: participant,
    };
    final participantEntries = participantLinks
        .map(
          (link) => _toParticipantEntry(
            event: event,
            link: link,
            contactsById: contactsById,
          ),
        )
        .whereType<EventParticipantDetailReadModel>()
        .toList();

    return EventDetailReadModel(
      event: event,
      eventTypeName: resolveEventTypeName(eventTypeNames, event.eventTypeId),
      participants: participants,
      participantEntries: participantEntries,
      attachments: attachments,
      createdByContact: createdByContact,
    );
  }

  EventParticipantDetailReadModel? _toParticipantEntry({
    required Event event,
    required EventParticipant link,
    required Map<String, Contact> contactsById,
  }) {
    final contact = contactsById[link.contactId];
    if (contact == null) {
      return null;
    }

    var role = EventParticipantRoles.normalize(link.role);
    if (role == EventParticipantRoles.participant && event.createdByContactId == contact.id) {
      role = EventParticipantRoles.initiator;
    }

    return EventParticipantDetailReadModel(
      contact: contact,
      role: role,
    );
  }
}

class EventsListReadModel {
  final Contact? contact;
  final List<EventListItemReadModel> items;

  const EventsListReadModel({
    required this.contact,
    required this.items,
  });
}

class EventListItemReadModel {
  final Event event;
  final String? eventTypeName;
  final List<String> participantNames;

  const EventListItemReadModel({
    required this.event,
    required this.eventTypeName,
    required this.participantNames,
  });
}

class EventDetailReadModel {
  final Event event;
  final String? eventTypeName;
  final List<Contact> participants;
  final List<EventParticipantDetailReadModel> participantEntries;
  final List<Attachment> attachments;
  final Contact? createdByContact;

  const EventDetailReadModel({
    required this.event,
    required this.eventTypeName,
    required this.participants,
    required this.participantEntries,
    required this.attachments,
    required this.createdByContact,
  });
}

class EventParticipantDetailReadModel {
  final Contact contact;
  final String role;

  const EventParticipantDetailReadModel({
    required this.contact,
    required this.role,
  });
}