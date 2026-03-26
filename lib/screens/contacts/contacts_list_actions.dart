import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/contact.dart';
import '../../models/contact_draft.dart';
import '../../models/tag.dart';
import '../../providers/contact_provider.dart';
import '../../providers/tag_provider.dart';
import '../../utils/contact_action_helpers.dart';
import '../../config/page_transitions.dart';
import '../../utils/navigation_helpers.dart';
import '../../widgets/contact/contact_tag_filter_sheet.dart';
import '../tags/tag_management_screen.dart';
import 'contact_detail_screen.dart';
import 'contact_form_screen.dart';

Future<void> createContactFromList(BuildContext context) async {
  final draft = await Navigator.of(context).push<ContactDraft>(
    SlidePageRoute(
      builder: (_) => const ContactFormScreen(),
    ),
  );

  if (draft == null || !context.mounted) {
    return;
  }

  final provider = context.read<ContactProvider>();
  await provider.createContact(draft);
  if (!context.mounted) {
    return;
  }

  showProviderResultSnackBar(
    context,
    successMessage: '联系人已创建',
    error: provider.error,
    onErrorHandled: provider.clearError,
  );
}

Future<void> editContactFromList(BuildContext context, Contact contact) async {
  final draft = await Navigator.of(context).push<ContactDraft>(
    SlidePageRoute(
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
    successMessage: '联系人已更新',
    error: provider.error,
    onErrorHandled: provider.clearError,
  );
}

Future<void> openContactDetailFromList(BuildContext context, Contact contact) async {
  await Navigator.of(context).push<void>(
    buildAdaptiveDetailRoute(
      ContactDetailScreen(contactId: contact.id),
    ),
  );
}

Future<void> deleteContactFromList(BuildContext context, Contact contact) async {
  final confirmed = await showDeleteContactConfirmDialog(
    context,
    contact: contact,
  );

  if (confirmed != true || !context.mounted) {
    return;
  }

  final provider = context.read<ContactProvider>();
  await provider.deleteContact(contact.id);
  if (!context.mounted) {
    return;
  }

  showProviderResultSnackBar(
    context,
    successMessage: '联系人已删除',
    error: provider.error,
    onErrorHandled: provider.clearError,
  );
}

Future<void> openTagManagementFromList(BuildContext context) async {
  await Navigator.of(context).push<void>(
    SlidePageRoute(
      builder: (_) => const TagManagementScreen(),
    ),
  );

  if (!context.mounted) {
    return;
  }

  await context.read<TagProvider>().loadTags();
}

Future<void> openTagFilterFromList(BuildContext context) async {
  final tagProvider = context.read<TagProvider>();
  if (!tagProvider.initialized) {
    await tagProvider.loadTags();
  }
  if (!context.mounted) {
    return;
  }

  final contactProvider = context.read<ContactProvider>();
  final selection = await showModalBottomSheet<ContactTagFilterSelection>(
    context: context,
    isScrollControlled: true,
    builder: (context) => ContactTagFilterSheet(
      tags: tagProvider.tags,
      initialTagIds: contactProvider.selectedTagIds,
    ),
  );

  if (selection == null || !context.mounted) {
    return;
  }

  if (selection.isEmpty) {
    await contactProvider.clearFilters();
    return;
  }

  await contactProvider.searchByTags(selection);
}

List<Tag> resolveSelectedTags(List<Tag> allTags, List<String> selectedTagIds) {
  final selectedIdSet = selectedTagIds.toSet();
  return allTags.where((tag) => selectedIdSet.contains(tag.id)).toList();
}