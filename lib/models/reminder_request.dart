class ReminderRequest {
  final String id;
  final String title;
  final String body;
  final DateTime fireAt;
  final Map<String, String> payload;

  const ReminderRequest({
    required this.id,
    required this.title,
    required this.body,
    required this.fireAt,
    this.payload = const {},
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'fireAt': fireAt.millisecondsSinceEpoch,
      'payload': payload,
    };
  }
}