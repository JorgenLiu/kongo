import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/page_transitions.dart';
import '../../models/contact.dart';
import '../../models/contact_draft.dart';
import '../../models/event.dart';
import '../../models/event_draft.dart';
import '../../models/tag.dart';
import '../../providers/contact_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/provider_error.dart';
import '../../providers/tag_provider.dart';
import '../../utils/event_participant_roles.dart';
import '../contacts/contact_form_screen.dart';
import '../events/event_form_screen.dart';

Future<List<Tag>> loadTodoFormTags(BuildContext context) async {
  try {
    final provider = Provider.of<TagProvider>(context, listen: false);
    if (!provider.initialized && !provider.loading) {
      await provider.loadTags();
    }
    return provider.tags;
  } on ProviderNotFoundException {
    return const [];
  }
}

Future<Contact?> quickCreateTodoContact(
  BuildContext context, {
  String? initialName,
}) async {
  final draft = await Navigator.of(context).push<ContactDraft>(
    SideSheetPageRoute(
      builder: (_) => ContactFormScreen(
        initialName: _normalizePrefill(initialName),
        sideSheet: true,
      ),
    ),
  );

  if (draft == null || !context.mounted) {
    return null;
  }

  final provider = context.read<ContactProvider>();
  await provider.createContact(draft);
  if (!context.mounted) {
    return null;
  }

  _showQuickCreateError(context, provider.error);
  return provider.error == null ? provider.currentContact : null;
}

Future<Event?> quickCreateTodoEvent(
  BuildContext context, {
  String? initialTitle,
  List<String> participantIds = const [],
}) async {
  final normalizedParticipantIds = participantIds.toSet().toList(growable: false);
  final initialParticipantRoles = {
    for (final contactId in normalizedParticipantIds)
      contactId: EventParticipantRoles.participant,
  };
  final draft = await Navigator.of(context).push<EventDraft>(
    SideSheetPageRoute(
      builder: (_) => EventFormScreen(
        initialTitle: _normalizePrefill(initialTitle),
        suggestedContactId: normalizedParticipantIds.isEmpty ? null : normalizedParticipantIds.first,
        initialParticipantRoles: initialParticipantRoles,
        sideSheet: true,
      ),
    ),
  );

  if (draft == null || !context.mounted) {
    return null;
  }

  final provider = context.read<EventProvider>();
  await provider.createEvent(draft);
  if (!context.mounted) {
    return null;
  }

  _showQuickCreateError(context, provider.error);
  return provider.error == null ? provider.currentEvent : null;
}

String? _normalizePrefill(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

void _showQuickCreateError(BuildContext context, Object? error) {
  if (error is! ProviderError) {
    return;
  }

  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) {
    return;
  }

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(content: Text(error.message)),
  );
}