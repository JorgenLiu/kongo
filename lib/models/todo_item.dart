enum TodoItemStatus {
  pending('pending', '待处理'),
  completed('completed', '已完成');

  const TodoItemStatus(this.value, this.label);

  final String value;
  final String label;

  static TodoItemStatus fromValue(String value) {
    return TodoItemStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TodoItemStatus.pending,
    );
  }
}

class TodoItem {
  final String id;
  final String groupId;
  final String? parentItemId;
  final String title;
  final String? notes;
  final TodoItemStatus status;
  final DateTime? dueAt;
  final DateTime? completedAt;
  final String? sourceType;
  final String? sourceId;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TodoItem({
    required this.id,
    required this.groupId,
    this.parentItemId,
    required this.title,
    this.notes,
    this.status = TodoItemStatus.pending,
    this.dueAt,
    this.completedAt,
    this.sourceType,
    this.sourceId,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TodoItem.fromMap(Map<String, dynamic> map) {
    DateTime? readTimestamp(String key) {
      final value = map[key];
      if (value == null) {
        return null;
      }
      return DateTime.fromMillisecondsSinceEpoch((value as num).toInt());
    }

    return TodoItem(
      id: map['id'] as String,
      groupId: map['groupId'] as String,
      parentItemId: map['parentItemId'] as String?,
      title: map['title'] as String,
      notes: map['notes'] as String?,
      status: TodoItemStatus.fromValue(map['status'] as String? ?? 'pending'),
      dueAt: readTimestamp('dueAt'),
      completedAt: readTimestamp('completedAt'),
      sourceType: map['sourceType'] as String?,
      sourceId: map['sourceId'] as String?,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: readTimestamp('createdAt')!,
      updatedAt: readTimestamp('updatedAt')!,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'parentItemId': parentItemId,
      'title': title,
      'notes': notes,
      'status': status.value,
      'dueAt': dueAt?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'sourceType': sourceType,
      'sourceId': sourceId,
      'sortOrder': sortOrder,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  TodoItem copyWith({
    String? id,
    String? groupId,
    String? parentItemId,
    bool clearParentItemId = false,
    String? title,
    String? notes,
    bool clearNotes = false,
    TodoItemStatus? status,
    DateTime? dueAt,
    bool clearDueAt = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    String? sourceType,
    bool clearSourceType = false,
    String? sourceId,
    bool clearSourceId = false,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      parentItemId: clearParentItemId ? null : parentItemId ?? this.parentItemId,
      title: title ?? this.title,
      notes: clearNotes ? null : notes ?? this.notes,
      status: status ?? this.status,
      dueAt: clearDueAt ? null : dueAt ?? this.dueAt,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      sourceType: clearSourceType ? null : sourceType ?? this.sourceType,
      sourceId: clearSourceId ? null : sourceId ?? this.sourceId,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}