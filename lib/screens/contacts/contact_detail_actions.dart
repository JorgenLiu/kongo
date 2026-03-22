import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/contact.dart';
import '../../models/contact_draft.dart';
import '../../providers/contact_detail_provider.dart';
import '../../providers/contact_provider.dart';
import '../../utils/contact_action_helpers.dart';
import '../../utils/navigation_helpers.dart';
import '../events/event_detail_screen.dart';
import '../events/events_list_screen.dart';
import 'contact_form_screen.dart';

Future<void> openContactEventsModule(BuildContext context, Contact contact) async {
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => EventsListScreen(
        contactId: contact.id,
        contactName: contact.name,
        showAppBar: true,
      ),
    ),
  );

  if (!context.mounted) {
    return;
  }

  await context.read<ContactDetailProvider>().refresh();
}

Future<void> openRelatedEventDetail(BuildContext context, String eventId) async {
  await Navigator.of(context).push(
    buildAdaptiveDetailRoute(
      EventDetailScreen(eventId: eventId),
    ),
  );

  if (!context.mounted) {
    return;
  }

  await context.read<ContactDetailProvider>().refresh();
}

Future<void> editContactDetail(BuildContext context, Contact contact) async {
  final draft = await Navigator.of(context).push<ContactDraft>(
    MaterialPageRoute(
      builder: (_) => ContactFormScreen(initialContact: contact),
    ),
  );

  if (draft == null || !context.mounted) {
    return;
  }

  final provider = context.read<ContactProvider>();
  await provider.updateContact(
    contact.copyWith(
      name: draft.name,
      phone: draft.phone,
      email: draft.email,
      address: draft.address,
      notes: draft.notes,
    ),
    tagIds: draft.tagIds,
  );

  if (!context.mounted) {
    return;
  }

  showProviderResultSnackBar(
    context,
    error: provider.error,
    successMessage: '联系人已更新',
    onErrorHandled: provider.clearError,
  );
  await context.read<ContactDetailProvider>().refresh();
}

Future<void> deleteContactDetail(
  BuildContext context,
  Contact contact,
) async {
  final confirmed = await showDeleteContactConfirmDialog(
    context,
    contact: contact,
  );

  if (!confirmed || !context.mounted) {
    return;
  }

  final provider = context.read<ContactProvider>();
  await provider.deleteContact(contact.id);
  if (!context.mounted) {
    return;
  }

  if (provider.error != null) {
    showProviderResultSnackBar(
      context,
      error: provider.error,
      successMessage: '联系人已删除',
      onErrorHandled: provider.clearError,
    );
    return;
  }

  showProviderResultSnackBar(
    context,
    error: null,
    successMessage: '联系人已删除',
  );

  Navigator.of(context).pop();
}

void showPendingContactModuleHint(BuildContext context, String moduleName) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$moduleName 模块的完整页面将在下一步接入')),
  );
}