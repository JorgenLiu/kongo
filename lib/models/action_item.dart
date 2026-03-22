/// 从总结中提取的行动项。
class ActionItem {
  final String title;
  final String? assigneeContactId;
  final DateTime? dueAt;
  final bool completed;

  const ActionItem({
    required this.title,
    this.assigneeContactId,
    this.dueAt,
    this.completed = false,
  });
}