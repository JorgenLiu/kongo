import 'display_formatters.dart';

String appendEventFollowUpNote(
  String? existingDescription,
  String note, {
  DateTime? timestamp,
}) {
  final sections = <String>[];
  final normalizedExisting = existingDescription?.trimRight();
  if (normalizedExisting != null && normalizedExisting.isNotEmpty) {
    sections.add(normalizedExisting);
  }

  final resolvedTimestamp = timestamp ?? DateTime.now();
  sections.add('会后补充（${formatDateTimeLabel(resolvedTimestamp)}）\n- ${note.trim()}');
  return sections.join('\n\n');
}