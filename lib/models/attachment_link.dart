enum AttachmentOwnerType { event, summary }

extension AttachmentOwnerTypeValue on AttachmentOwnerType {
  String get value {
    switch (this) {
      case AttachmentOwnerType.event:
        return 'event';
      case AttachmentOwnerType.summary:
        return 'summary';
    }
  }

  static AttachmentOwnerType fromValue(String value) {
    return AttachmentOwnerType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AttachmentOwnerType.event,
    );
  }
}

/// 附件关联模型
class AttachmentLink {
  final String id;
  final String attachmentId;
  final AttachmentOwnerType ownerType;
  final String ownerId;
  final String? label;
  final DateTime addedAt;

  const AttachmentLink({
    required this.id,
    required this.attachmentId,
    required this.ownerType,
    required this.ownerId,
    this.label,
    required this.addedAt,
  });

  factory AttachmentLink.fromMap(Map<String, dynamic> map) {
    return AttachmentLink(
      id: map['id'] as String,
      attachmentId: map['attachmentId'] as String,
      ownerType: AttachmentOwnerTypeValue.fromValue(
        map['ownerType'] as String? ?? 'event',
      ),
      ownerId: map['ownerId'] as String,
      label: map['label'] as String?,
      addedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['addedAt'] as num).toInt(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'attachmentId': attachmentId,
      'ownerType': ownerType.value,
      'ownerId': ownerId,
      'label': label,
      'addedAt': addedAt.millisecondsSinceEpoch,
    };
  }

  AttachmentLink copyWith({
    String? id,
    String? attachmentId,
    AttachmentOwnerType? ownerType,
    String? ownerId,
    String? label,
    DateTime? addedAt,
  }) {
    return AttachmentLink(
      id: id ?? this.id,
      attachmentId: attachmentId ?? this.attachmentId,
      ownerType: ownerType ?? this.ownerType,
      ownerId: ownerId ?? this.ownerId,
      label: label ?? this.label,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  String toString() {
    return 'AttachmentLink(id: $id, attachmentId: $attachmentId, ownerType: ${ownerType.value}, ownerId: $ownerId)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttachmentLink &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          attachmentId == other.attachmentId &&
          ownerType == other.ownerType &&
          ownerId == other.ownerId;

  @override
  int get hashCode =>
      id.hashCode ^
      attachmentId.hashCode ^
      ownerType.hashCode ^
      ownerId.hashCode;
}