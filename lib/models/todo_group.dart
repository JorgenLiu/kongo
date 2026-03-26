class TodoGroup {
  final String id;
  final String title;
  final String? description;
  final int sortOrder;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TodoGroup({
    required this.id,
    required this.title,
    this.description,
    this.sortOrder = 0,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TodoGroup.fromMap(Map<String, dynamic> map) {
    DateTime? readTimestamp(String key) {
      final value = map[key];
      if (value == null) {
        return null;
      }
      return DateTime.fromMillisecondsSinceEpoch((value as num).toInt());
    }

    return TodoGroup(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      archivedAt: readTimestamp('archivedAt'),
      createdAt: readTimestamp('createdAt')!,
      updatedAt: readTimestamp('updatedAt')!,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'sortOrder': sortOrder,
      'archivedAt': archivedAt?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  TodoGroup copyWith({
    String? id,
    String? title,
    String? description,
    bool clearDescription = false,
    int? sortOrder,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoGroup(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      archivedAt: clearArchivedAt ? null : archivedAt ?? this.archivedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}