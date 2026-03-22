/// 事件模型
class Event {
  final String id;
  final String title;
  final String? eventTypeId;
  final DateTime? startAt;
  final DateTime? endAt;
  final String? location;
  final String? description;
  final bool reminderEnabled;
  final DateTime? reminderAt;
  final String? createdByContactId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Event({
    required this.id,
    required this.title,
    this.eventTypeId,
    this.startAt,
    this.endAt,
    this.location,
    this.description,
    this.reminderEnabled = false,
    this.reminderAt,
    this.createdByContactId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Event.fromMap(Map<String, dynamic> map) {
    DateTime? readTimestamp(String key) {
      final value = map[key];
      if (value == null) {
        return null;
      }
      return DateTime.fromMillisecondsSinceEpoch((value as num).toInt());
    }

    return Event(
      id: map['id'] as String,
      title: map['title'] as String,
      eventTypeId: map['eventTypeId'] as String?,
      startAt: readTimestamp('startAt'),
      endAt: readTimestamp('endAt'),
      location: map['location'] as String?,
      description: map['description'] as String?,
      reminderEnabled: ((map['reminderEnabled'] as num?)?.toInt() ?? 0) == 1,
      reminderAt: readTimestamp('reminderAt'),
      createdByContactId: map['createdByContactId'] as String?,
      createdAt: readTimestamp('createdAt')!,
      updatedAt: readTimestamp('updatedAt')!,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'eventTypeId': eventTypeId,
      'startAt': startAt?.millisecondsSinceEpoch,
      'endAt': endAt?.millisecondsSinceEpoch,
      'location': location,
      'description': description,
      'reminderEnabled': reminderEnabled ? 1 : 0,
      'reminderAt': reminderAt?.millisecondsSinceEpoch,
      'createdByContactId': createdByContactId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? eventTypeId,
    DateTime? startAt,
    DateTime? endAt,
    String? location,
    String? description,
    bool? reminderEnabled,
    DateTime? reminderAt,
    String? createdByContactId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      eventTypeId: eventTypeId ?? this.eventTypeId,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      location: location ?? this.location,
      description: description ?? this.description,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderAt: reminderAt ?? this.reminderAt,
      createdByContactId: createdByContactId ?? this.createdByContactId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Event(id: $id, title: $title)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          runtimeType == other.runtimeType &&
          id == other.id &&
            title == other.title;

  @override
          int get hashCode => id.hashCode ^ title.hashCode;
}