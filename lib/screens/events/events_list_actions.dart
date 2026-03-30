import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event_draft.dart';
import '../../providers/event_provider.dart';
import '../../utils/contact_action_helpers.dart';
import '../../config/page_transitions.dart';
import '../../utils/navigation_helpers.dart';
import 'event_detail_screen.dart';
import 'event_form_screen.dart';

Future<void> openScheduleDetailFromList(BuildContext context, String eventId) async {
  await Navigator.of(context).push<void>(
    buildAdaptiveDetailRoute(
      EventDetailScreen(eventId: eventId),
    ),
  );
}

Future<bool> createScheduleFromList(
  BuildContext context, {
  String? suggestedContactId,
  DateTime? initialStartAt,
}) async {
  final draft = await Navigator.of(context).push<EventDraft>(
    SideSheetPageRoute(
      builder: (_) => EventFormScreen(
        suggestedContactId: suggestedContactId,
        initialStartAt: initialStartAt,
        sideSheet: true,
      ),
    ),
  );

  if (draft == null || !context.mounted) {
    return false;
  }

  final provider = context.read<EventProvider>();
  await provider.createEvent(draft);
  if (!context.mounted) {
    return false;
  }

  showProviderResultSnackBar(
    context,
    error: provider.error,
    successMessage: '日程已创建',
    onErrorHandled: provider.clearError,
  );

  return provider.error == null;
}