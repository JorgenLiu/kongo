import '../../models/attachment.dart';
import '../../models/event.dart';
import '../../models/event_type.dart';

Map<String, String> buildEventTypeNames(List<EventType> eventTypes) {
  return {
    for (final eventType in eventTypes) eventType.id: eventType.name,
  };
}

String? resolveEventTypeName(Map<String, String> eventTypeNames, String? eventTypeId) {
  if (eventTypeId == null || eventTypeId.isEmpty) {
    return null;
  }

  return eventTypeNames[eventTypeId];
}

List<Attachment> collectSortedEventAttachments({
  required List<Event> events,
  required Map<String, List<Attachment>> eventAttachmentsByEventId,
}) {
  final attachmentsById = <String, Attachment>{};

  for (final event in events) {
    for (final attachment in eventAttachmentsByEventId[event.id] ?? const <Attachment>[]) {
      attachmentsById[attachment.id] = attachment;
    }
  }

  final attachments = attachmentsById.values.toList()
    ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
  return attachments;
}