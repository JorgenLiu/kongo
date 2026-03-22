/// 事件参与人模型
class EventParticipant {
  final String id;
  final String eventId;
  final String contactId;
  final String? role;
  final DateTime addedAt;

  const EventParticipant({
    required this.id,
    required this.eventId,
    required this.contactId,
    this.role,
    required this.addedAt,
  });

  factory EventParticipant.fromMap(Map<String, dynamic> map) {
    return EventParticipant(
      id: map['id'] as String,
      eventId: map['eventId'] as String,
      contactId: map['contactId'] as String,
      role: map['role'] as String?,
      addedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['addedAt'] as num).toInt(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'contactId': contactId,
      'role': role,
      'addedAt': addedAt.millisecondsSinceEpoch,
    };
  }

  EventParticipant copyWith({
    String? id,
    String? eventId,
    String? contactId,
    String? role,
    DateTime? addedAt,
  }) {
    return EventParticipant(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      contactId: contactId ?? this.contactId,
      role: role ?? this.role,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  String toString() {
    return 'EventParticipant(id: $id, eventId: $eventId, contactId: $contactId, role: $role)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventParticipant &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          eventId == other.eventId &&
          contactId == other.contactId;

  @override
  int get hashCode => id.hashCode ^ eventId.hashCode ^ contactId.hashCode;
}