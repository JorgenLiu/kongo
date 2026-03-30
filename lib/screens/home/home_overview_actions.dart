import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/page_transitions.dart';
import '../../models/event_draft.dart';
import '../../providers/event_provider.dart';
import '../../utils/contact_action_helpers.dart';
import '../../utils/navigation_helpers.dart';
import '../contacts/contact_detail_screen.dart';
import '../contacts/contact_form_screen.dart';
import '../contacts/contacts_list_screen.dart';
import '../events/event_detail_screen.dart';
import '../events/event_form_screen.dart';
import '../events/events_list_screen.dart';
import '../notes/notes_overview_screen.dart';
import '../summaries/summary_form_screen.dart';
import '../summaries/summary_overview_screen.dart';
import '../todos/todo_board_screen.dart';

Future<void> openEventsFromHome(BuildContext context, {DateTime? initialSelectedDate}) async {
  await Navigator.of(context).push<void>(
    SlidePageRoute(
      builder: (_) => EventsListScreen(initialSelectedDate: initialSelectedDate),
    ),
  );
}

Future<void> openEventDetailFromHome(
  BuildContext context,
  String eventId,
) async {
  await Navigator.of(context).push<void>(
    buildAdaptiveDetailRoute(EventDetailScreen(eventId: eventId)),
  );
}

Future<void> openContactDetailFromHome(
  BuildContext context,
  String contactId,
) async {
  await Navigator.of(context).push<void>(
    buildAdaptiveDetailRoute(
      ContactDetailScreen(contactId: contactId),
    ),
  );
}

Future<void> createContactFromHome(BuildContext context) async {
  await Navigator.of(context).push<void>(
    SideSheetPageRoute(builder: (_) => const ContactFormScreen(sideSheet: true)),
  );
}

Future<bool> createEventFromHome(BuildContext context) async {
  return createEventFromHomeWithInitialStart(context);
}

Future<bool> createTodayEventFromHome(BuildContext context) async {
  final now = DateTime.now();
  final initialStart = DateTime(now.year, now.month, now.day, now.hour);
  return createEventFromHomeWithInitialStart(context, initialStartAt: initialStart);
}

Future<bool> createEventFromHomeWithInitialStart(
  BuildContext context, {
  DateTime? initialStartAt,
}) async {
  final draft = await Navigator.of(context).push<EventDraft>(
    SideSheetPageRoute(
      builder: (_) => EventFormScreen(initialStartAt: initialStartAt, sideSheet: true),
    ),
  );
  if (draft == null || !context.mounted) return false;

  final provider = context.read<EventProvider>();
  await provider.createEvent(draft);
  if (!context.mounted) return false;

  showProviderResultSnackBar(
    context,
    error: provider.error,
    successMessage: '日程已创建',
    onErrorHandled: provider.clearError,
  );
  return provider.error == null;
}

Future<void> createSummaryFromHome(BuildContext context) async {
  await Navigator.of(context).push<void>(
    SlidePageRoute(builder: (_) => const SummaryFormScreen()),
  );
}

Future<void> openSummariesFromHome(BuildContext context) async {
  await Navigator.of(context).push<void>(
    SlidePageRoute(builder: (_) => const SummaryOverviewScreen()),
  );
}

Future<void> openNotesFromHome(BuildContext context) async {
  await Navigator.of(context).push<void>(
    SlidePageRoute(builder: (_) => const NotesOverviewScreen()),
  );
}

Future<void> openContactsFromHome(BuildContext context) async {
  await Navigator.of(context).push<void>(
    SlidePageRoute(builder: (_) => const ContactsListScreen()),
  );
}

Future<void> openTodosFromHome(BuildContext context) async {
  await Navigator.of(context).push<void>(
    SlidePageRoute(builder: (_) => const TodoBoardScreen()),
  );
}
