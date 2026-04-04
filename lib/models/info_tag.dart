/// 联系人信息标签，对应 info_tags 表。
///
/// 与分组标签（tags / contact_tags）完全隔离，不参与联系人筛选，
/// 用于沉淀如年龄、状态、角色等半结构化属性信息。
class InfoTag {
  final String id;
  final String name;
  final DateTime createdAt;

  const InfoTag({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory InfoTag.fromMap(Map<String, dynamic> map) {
    return InfoTag(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as num).toInt(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  @override
  String toString() => 'InfoTag(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InfoTag && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
