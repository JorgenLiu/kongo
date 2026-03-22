/// 联系人创建草稿。
class ContactDraft {
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? avatar;
  final String? notes;
  final List<String> tagIds;

  const ContactDraft({
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.avatar,
    this.notes,
    this.tagIds = const [],
  });
}