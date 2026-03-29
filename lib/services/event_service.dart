import 'package:uuid/uuid.dart';

import '../exceptions/app_exception.dart';
import '../models/attachment_link.dart';
import '../models/contact.dart';
import '../models/event.dart';
import '../models/event_draft.dart';
import '../models/event_participant.dart';
import '../models/event_type.dart';
import '../models/event_type_draft.dart';
import '../repositories/attachment_repository.dart';
import '../repositories/contact_repository.dart';
import '../repositories/event_repository.dart';
import '../utils/event_participant_roles.dart';
import '../utils/text_normalize.dart';
import 'reminder_service.dart';

abstract class EventService {
  Future<List<EventType>> getEventTypes();
  Future<EventType> createEventType(EventTypeDraft draft);
  Future<List<Event>> getEvents();
  Future<Event> getEvent(String id);
  Future<Event> createEvent(EventDraft draft);
  Future<Event> updateEvent(Event event);
  Future<void> deleteEvent(String id);
  Future<void> setParticipants(
    String eventId,
    List<String> contactIds, {
    Map<String, String>? participantRoles,
  });
  Future<void> addParticipant(String eventId, String contactId, {String? role});
  Future<void> removeParticipant(String eventId, String contactId);
  Future<List<Contact>> getParticipants(String eventId);
  Future<Map<String, List<Contact>>> getParticipantsByEventIds(List<String> eventIds);
  Future<List<Event>> searchEvents({
    String? keyword,
    String? eventTypeId,
  });
  Future<List<Event>> getUpcomingEvents({int days = 30});
  Future<List<Event>> getEventsByDate(DateTime date);
}

class DefaultEventService implements EventService {
  final EventRepository _eventRepository;
  final ContactRepository _contactRepository;
  final AttachmentRepository _attachmentRepository;
  final ReminderService? _reminderService;
  final Uuid _uuid;

  DefaultEventService(
    this._eventRepository,
    this._contactRepository,
    this._attachmentRepository, {
    ReminderService? reminderService,
    Uuid? uuid,
  })  : _reminderService = reminderService,
        _uuid = uuid ?? const Uuid();

  @override
  Future<List<EventType>> getEventTypes() {
    return _eventRepository.getEventTypes();
  }

  @override
  Future<EventType> createEventType(EventTypeDraft draft) async {
    final normalizedName = draft.name.trim();
    if (normalizedName.isEmpty) {
      throw const ValidationException(message: '事件类型名称不能为空', code: 'event_type_name_required');
    }

    final now = DateTime.now();
    final eventType = EventType(
      id: _uuid.v4(),
      name: normalizedName,
      icon: normalizeOptionalText(draft.icon),
      color: normalizeOptionalText(draft.color),
      createdAt: now,
      updatedAt: now,
    );

    return _eventRepository.insertEventType(eventType);
  }

  @override
  Future<List<Event>> getEvents() {
    return _eventRepository.getAll();
  }

  @override
  Future<Event> getEvent(String id) {
    return _eventRepository.getById(id);
  }

  @override
  Future<Event> createEvent(EventDraft draft) async {
    final normalizedTitle = draft.title.trim();
    if (normalizedTitle.isEmpty) {
      throw const ValidationException(message: '事件标题不能为空', code: 'event_title_required');
    }

    _validateTimeRange(draft.startAt, draft.endAt);
    final participantRoles = _resolveParticipantRoles(
      participantIds: draft.participantIds,
      participantRoles: draft.participantRoles,
    );
    final participantIds = participantRoles.keys.toList();

    if (participantIds.isNotEmpty) {
      await _ensureContactIdsExist(participantIds);
    }
    await _ensureOptionalContactExists(draft.createdByContactId);
    await _ensureOptionalEventTypeExists(draft.eventTypeId);

    final now = DateTime.now();
    final event = Event(
      id: _uuid.v4(),
      title: normalizedTitle,
      eventTypeId: draft.eventTypeId,
      startAt: draft.startAt,
      endAt: draft.endAt,
      location: normalizeOptionalText(draft.location),
      description: normalizeOptionalText(draft.description),
      reminderEnabled: draft.reminderEnabled,
      reminderAt: draft.reminderAt,
      createdByContactId: draft.createdByContactId,
      createdAt: now,
      updatedAt: now,
    );

    final created = await _eventRepository.insert(event);
    if (participantIds.isNotEmpty) {
      await setParticipants(
        created.id,
        participantIds,
        participantRoles: participantRoles,
      );
    }
    final saved = await _eventRepository.getById(created.id);
    await _syncReminderSafely(() => _reminderService?.syncEventReminder(saved));
    return saved;
  }

  @override
  Future<Event> updateEvent(Event event) async {
    final normalizedTitle = event.title.trim();
    if (normalizedTitle.isEmpty) {
      throw const ValidationException(message: '事件标题不能为空', code: 'event_title_required');
    }

    _validateTimeRange(event.startAt, event.endAt);
    await _eventRepository.getById(event.id);
    await _ensureOptionalContactExists(event.createdByContactId);
    await _ensureOptionalEventTypeExists(event.eventTypeId);

    final updated = await _eventRepository.update(
      event.copyWith(
        title: normalizedTitle,
        location: normalizeOptionalText(event.location),
        description: normalizeOptionalText(event.description),
        updatedAt: DateTime.now(),
      ),
    );
    await _syncReminderSafely(() => _reminderService?.syncEventReminder(updated));
    return updated;
  }

  @override
  Future<void> deleteEvent(String id) async {
    await _eventRepository.getById(id);
    await _attachmentRepository.unlinkAllByOwner(AttachmentOwnerType.event, id);
    await _eventRepository.delete(id);
    await _syncReminderSafely(() => _reminderService?.removeEventReminder(id));
  }

  @override
  Future<void> setParticipants(
    String eventId,
    List<String> contactIds, {
    Map<String, String>? participantRoles,
  }) async {
    await _eventRepository.getById(eventId);

    final resolvedParticipantRoles = _resolveParticipantRoles(
      participantIds: contactIds,
      participantRoles: participantRoles ?? const {},
    );
    final normalizedContactIds = resolvedParticipantRoles.keys.toList();
    if (normalizedContactIds.isEmpty) {
      throw const ValidationException(message: '事件至少需要一个参与人', code: 'event_participants_required');
    }

    await _ensureContactIdsExist(normalizedContactIds);

    final now = DateTime.now();
    final participants = normalizedContactIds
        .map(
          (contactId) => EventParticipant(
            id: '${eventId}_$contactId',
            eventId: eventId,
            contactId: contactId,
            role: resolvedParticipantRoles[contactId] ?? EventParticipantRoles.participant,
            addedAt: now,
          ),
        )
        .toList();

    await _eventRepository.replaceParticipants(eventId, participants);
  }

  @override
  Future<void> addParticipant(String eventId, String contactId, {String? role}) async {
    await _eventRepository.getById(eventId);
    await _contactRepository.getById(contactId);
    await _eventRepository.addParticipant(
      EventParticipant(
        id: '${eventId}_$contactId',
        eventId: eventId,
        contactId: contactId,
        role: EventParticipantRoles.normalize(normalizeOptionalText(role)),
        addedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> removeParticipant(String eventId, String contactId) async {
    await _eventRepository.getById(eventId);
    final participants = await _eventRepository.getParticipantLinks(eventId);
    final exists = participants.any((participant) => participant.contactId == contactId);

    if (!exists) {
      throw const BusinessException(message: '该联系人不在事件参与人列表中', code: 'participant_not_found');
    }

    if (participants.length <= 1) {
      throw const ValidationException(message: '事件至少需要保留一个参与人', code: 'event_participants_required');
    }

    await _eventRepository.removeParticipant(eventId, contactId);
  }

  @override
  Future<List<Contact>> getParticipants(String eventId) async {
    await _eventRepository.getById(eventId);
    return _eventRepository.getParticipants(eventId);
  }

  @override
  Future<Map<String, List<Contact>>> getParticipantsByEventIds(List<String> eventIds) {
    if (eventIds.isEmpty) {
      return Future.value(const {});
    }
    return _eventRepository.getParticipantsByEventIds(eventIds);
  }

  @override
  Future<List<Event>> searchEvents({
    String? keyword,
    String? eventTypeId,
  }) async {
    if (eventTypeId != null && eventTypeId.trim().isNotEmpty) {
      await _eventRepository.getEventTypeById(eventTypeId);
    }

    return _eventRepository.search(
      keyword: keyword,
      eventTypeId: eventTypeId,
    );
  }

  @override
  Future<List<Event>> getUpcomingEvents({int days = 30}) {
    return _eventRepository.getUpcomingEvents(days: days);
  }

  @override
  Future<List<Event>> getEventsByDate(DateTime date) {
    return _eventRepository.getEventsByDate(date);
  }

  List<String> _normalizeParticipantIds(List<String> contactIds) {
    return contactIds
        .map((contactId) => contactId.trim())
        .where((contactId) => contactId.isNotEmpty)
        .toSet()
        .toList();
  }

  Map<String, String> _resolveParticipantRoles({
    required List<String> participantIds,
    required Map<String, String> participantRoles,
  }) {
    final normalizedIds = _normalizeParticipantIds([
      ...participantIds,
      ...participantRoles.keys,
    ]);

    return {
      for (final contactId in normalizedIds)
        contactId: EventParticipantRoles.normalize(participantRoles[contactId]),
    };
  }

  Future<void> _ensureContactIdsExist(List<String> contactIds) async {
    for (final contactId in contactIds) {
      await _contactRepository.getById(contactId);
    }
  }

  Future<void> _ensureOptionalContactExists(String? contactId) async {
    if (contactId == null || contactId.trim().isEmpty) {
      return;
    }
    await _contactRepository.getById(contactId);
  }

  Future<void> _ensureOptionalEventTypeExists(String? eventTypeId) async {
    if (eventTypeId == null || eventTypeId.trim().isEmpty) {
      return;
    }
    await _eventRepository.getEventTypeById(eventTypeId);
  }

  void _validateTimeRange(DateTime? startAt, DateTime? endAt) {
    if (startAt != null && endAt != null && endAt.isBefore(startAt)) {
      throw const ValidationException(message: '事件结束时间不能早于开始时间', code: 'invalid_event_time_range');
    }
  }

  Future<void> _syncReminderSafely(Future<void>? Function() action) async {
    try {
      await action();
    } catch (_) {}
  }


}