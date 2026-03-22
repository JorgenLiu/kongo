import '../../models/attachment.dart';
import '../../models/attachment_link.dart';
import '../../models/contact.dart';
import '../../models/event.dart';
import '../../models/tag.dart';
import '../../repositories/attachment_repository.dart';
import '../../repositories/contact_repository.dart';
import '../../repositories/event_repository.dart';
import '../../repositories/tag_repository.dart';
import 'read_aggregation_helpers.dart';

abstract class ContactReadService {
  Future<ContactDetailReadModel> getContactDetail(String contactId);
}

class DefaultContactReadService implements ContactReadService {
  final ContactRepository _contactRepository;
  final TagRepository _tagRepository;
  final EventRepository _eventRepository;
  final AttachmentRepository _attachmentRepository;

  DefaultContactReadService(
    this._contactRepository,
    this._tagRepository,
    this._eventRepository,
    this._attachmentRepository,
  );

  @override
  Future<ContactDetailReadModel> getContactDetail(String contactId) async {
    final contact = await _contactRepository.getById(contactId);
    final tags = await _tagRepository.getTagsForContact(contactId);
    final events = await _eventRepository.getByContactId(contactId);
    final eventTypes = await _eventRepository.getEventTypes();
    final eventIds = events.map((event) => event.id).toList();
    final eventAttachmentsByEventId = await _attachmentRepository.getByOwners(
      AttachmentOwnerType.event,
      eventIds,
    );
    final eventTypeNames = buildEventTypeNames(eventTypes);
    final attachments = collectSortedEventAttachments(
      events: events,
      eventAttachmentsByEventId: eventAttachmentsByEventId,
    );

    return ContactDetailReadModel(
      contact: contact,
      tags: tags,
      events: events,
      attachments: attachments,
      eventTypeNames: eventTypeNames,
    );
  }
}

class ContactDetailReadModel {
  final Contact contact;
  final List<Tag> tags;
  final List<Event> events;
  final List<Attachment> attachments;
  final Map<String, String> eventTypeNames;

  const ContactDetailReadModel({
    required this.contact,
    required this.tags,
    required this.events,
    required this.attachments,
    required this.eventTypeNames,
  });
}