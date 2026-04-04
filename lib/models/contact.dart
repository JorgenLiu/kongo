/// 联系人模型
class Contact {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? avatar;
  final String? notes;
  final List<String> tags;
  final List<String> infoTags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Contact({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.avatar,
    this.notes,
    this.tags = const [],
    this.infoTags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Contact.fromMap(
    Map<String, dynamic> map, {
    List<String> tags = const [],
    List<String> infoTags = const [],
  }) {
    return Contact(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      avatar: map['avatarPath'] as String?,
      notes: map['notes'] as String?,
      tags: tags,
      infoTags: infoTags,
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
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'avatarPath': avatar,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  Contact copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? avatar,
    String? notes,
    List<String>? tags,
    List<String>? infoTags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      avatar: avatar ?? this.avatar,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      infoTags: infoTags ?? this.infoTags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Contact(id: $id, name: $name, phone: $phone, email: $email, tags: $tags)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contact &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          phone == other.phone &&
          email == other.email &&
          address == other.address &&
          avatar == other.avatar &&
          notes == other.notes;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      phone.hashCode ^
      email.hashCode ^
      address.hashCode ^
      avatar.hashCode ^
      notes.hashCode;
}
