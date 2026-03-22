/// 事件创建草稿。
class EventDraft {
  final String title;
  final String? eventTypeId;
  final DateTime? startAt;
  final DateTime? endAt;
  final String? location;
  final String? description;
  final bool reminderEnabled;
  final DateTime? reminderAt;
  final String? createdByContactId;
  final List<String> participantIds;
  final Map<String, String> participantRoles;

  const EventDraft({
    required this.title,
    this.eventTypeId,
    this.startAt,
    this.endAt,
    this.location,
    this.description,
    this.reminderEnabled = false,
    this.reminderAt,
    this.createdByContactId,
    this.participantIds = const [],
    this.participantRoles = const {},
  });
}