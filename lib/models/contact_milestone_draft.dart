import 'contact_milestone.dart';

/// 联系人重要日期创建/编辑草稿
class ContactMilestoneDraft {
  final ContactMilestoneType type;
  final String? label;
  final DateTime milestoneDate;
  final bool isLunar;
  final bool isRecurring;
  final bool reminderEnabled;
  final int reminderDaysBefore;
  final String? notes;

  const ContactMilestoneDraft({
    required this.type,
    this.label,
    required this.milestoneDate,
    this.isLunar = false,
    this.isRecurring = true,
    this.reminderEnabled = false,
    this.reminderDaysBefore = 0,
    this.notes,
  });
}
