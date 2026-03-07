/// 联系人模型
class Contact {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? avatar;
  final String? notes;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Contact({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.avatar,
    this.notes,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// 用于测试的模型副本方法
  Contact copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? avatar,
    String? notes,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Contact(id: $id, name: $name, phone: $phone, tags: $tags)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contact &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          phone == other.phone &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ phone.hashCode ^ email.hashCode;
}
