enum ReminderSnoozeAction {
  tenMinutes(id: 'ten_minutes', label: '10 分钟后提醒'),
  laterToday(id: 'later_today', label: '今天晚些时候提醒');

  final String id;
  final String label;

  const ReminderSnoozeAction({
    required this.id,
    required this.label,
  });
}