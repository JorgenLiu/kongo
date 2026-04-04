import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/attachment.dart';
import '../../models/contact.dart';
import '../../models/event_summary.dart';
import '../../models/quick_note.dart';
import '../../providers/notes_provider.dart';
import '../../services/attachment_service.dart';
import '../../services/read/event_read_service.dart';
import '../contacts/contacts_list_actions.dart';
import '../events/events_list_actions.dart';
import '../summaries/summary_overview_actions.dart';

Future<void> openGlobalSearchContact(BuildContext context, Contact contact) {
  return openContactDetailFromList(context, contact);
}

Future<void> openGlobalSearchEvent(BuildContext context, EventListItemReadModel item) {
  return openScheduleDetailFromList(context, item.event.id);
}

Future<void> openGlobalSearchSummary(BuildContext context, DailySummary summary) {
  return editDailySummary(context, summary: summary);
}

Future<void> openGlobalSearchAttachment(BuildContext context, Attachment attachment) async {
  final service = context.read<AttachmentService>();
  await service.openAttachment(attachment);
}

Future<void> openGlobalSearchNote(BuildContext context, QuickNote note) async {
  final notesProvider = context.read<NotesProvider>();
  await notesProvider.navigateToDate(note.captureDate);
}