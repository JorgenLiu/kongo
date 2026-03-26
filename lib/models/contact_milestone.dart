/// 联系人重要日期类型
enum ContactMilestoneType {
  birthday('birthday', '生日', '🎂'),
  weddingAnniversary('wedding_anniversary', '结婚纪念日', '💍'),
  workStart('work_start', '入职日', '💼'),
  graduation('graduation', '毕业日', '🎓'),
  firstMet('first_met', '相识日', '🤝'),
  collaborationStart('collaboration_start', '合作开始日', '📋'),
  memorial('memorial', '忌日', '🕯️'),
  custom('custom', '自定义', '📌');

  const ContactMilestoneType(this.value, this.label, this.icon);

  final String value;
  final String label;
  final String icon;

  static ContactMilestoneType fromValue(String value) {
    return ContactMilestoneType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ContactMilestoneType.custom,
    );
  }
}

/// 联系人重要日期模型
class ContactMilestone {
  final String id;
  final String contactId;
  final ContactMilestoneType type;
  final String? label;
  final DateTime milestoneDate;
  final bool isLunar;
  final bool isRecurring;
  final bool reminderEnabled;
  final int reminderDaysBefore;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContactMilestone({
    required this.id,
    required this.contactId,
    required this.type,
    this.label,
    required this.milestoneDate,
    this.isLunar = false,
    this.isRecurring = true,
    this.reminderEnabled = false,
    this.reminderDaysBefore = 0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 展示名称：自定义类型用 label，否则用类型默认名称
  String get displayName => label ?? type.label;

  factory ContactMilestone.fromMap(Map<String, dynamic> map) {
    return ContactMilestone(
      id: map['id'] as String,
      contactId: map['contactId'] as String,
      type: ContactMilestoneType.fromValue(map['type'] as String),
      label: map['label'] as String?,
      milestoneDate: DateTime.fromMillisecondsSinceEpoch(
        (map['milestoneDate'] as num).toInt(),
      ),
      isLunar: (map['isLunar'] as num).toInt() == 1,
      isRecurring: (map['isRecurring'] as num).toInt() == 1,
      reminderEnabled: (map['reminderEnabled'] as num).toInt() == 1,
      reminderDaysBefore: (map['reminderDaysBefore'] as num).toInt(),
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as num).toInt(),
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updatedAt'] as num).toInt(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contactId': contactId,
      'type': type.value,
      'label': label,
      'milestoneDate': milestoneDate.millisecondsSinceEpoch,
      'isLunar': isLunar ? 1 : 0,
      'isRecurring': isRecurring ? 1 : 0,
      'reminderEnabled': reminderEnabled ? 1 : 0,
      'reminderDaysBefore': reminderDaysBefore,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  ContactMilestone copyWith({
    String? id,
    String? contactId,
    ContactMilestoneType? type,
    String? label,
    DateTime? milestoneDate,
    bool? isLunar,
    bool? isRecurring,
    bool? reminderEnabled,
    int? reminderDaysBefore,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContactMilestone(
      id: id ?? this.id,
      contactId: contactId ?? this.contactId,
      type: type ?? this.type,
      label: label ?? this.label,
      milestoneDate: milestoneDate ?? this.milestoneDate,
      isLunar: isLunar ?? this.isLunar,
      isRecurring: isRecurring ?? this.isRecurring,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ContactMilestone(id: $id, contactId: $contactId, type: ${type.value}, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactMilestone &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          contactId == other.contactId &&
          type == other.type &&
          label == other.label &&
          milestoneDate == other.milestoneDate;

  @override
  int get hashCode =>
      id.hashCode ^
      contactId.hashCode ^
      type.hashCode ^
      label.hashCode ^
      milestoneDate.hashCode;
}
