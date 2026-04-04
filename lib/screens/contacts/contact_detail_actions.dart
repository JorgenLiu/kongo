import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/attachment_link.dart';
import '../../models/contact.dart';
import '../../models/contact_draft.dart';
import '../../models/contact_milestone.dart';
import '../../providers/contact_detail_provider.dart';
import '../../providers/contact_provider.dart';
import '../../providers/files_provider.dart';
import '../../providers/notes_provider.dart';
import '../../services/attachment_service.dart';
import '../../services/contact_milestone_service.dart';
import '../../services/read/notes_read_service.dart';
import '../../utils/contact_action_helpers.dart';
import '../../config/page_transitions.dart';
import '../../utils/navigation_helpers.dart';
import '../../widgets/contact/contact_milestone_form_dialog.dart';
import '../events/event_detail_screen.dart';
import '../events/events_list_screen.dart';
import '../files/files_overview_screen.dart';
import '../notes/notes_overview_screen.dart';
import 'contact_form_screen.dart';

Future<void> openContactEventsModule(BuildContext context, Contact contact) async {
  await Navigator.of(context).push(
    SlidePageRoute(
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
    SideSheetPageRoute(
      builder: (_) => ContactFormScreen(initialContact: contact, sideSheet: true),
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

  showProviderResultSnackBar(
    context,
    error: provider.error,
    successMessage: '联系人已删除',
    onErrorHandled: provider.clearError,
  );

  if (provider.error == null) {
    Navigator.of(context).pop();
  }
}

Future<void> openContactFilesLibrary(
  BuildContext context, {
  required Contact contact,
  required List<String> eventIds,
}) async {
  final attachmentService = context.read<AttachmentService>();
  await Navigator.of(context).push(
    buildAdaptiveDetailRoute(
      ChangeNotifierProvider(
        create: (_) => FilesProvider(
          attachmentService,
          scope: FilesScope(
            ownerType: AttachmentOwnerType.event,
            ownerIds: eventIds,
          ),
          enableBackgroundPreviewWarmup: false,
        )..loadFiles(),
        child: FilesOverviewScreen(
          scopeLabel: '${contact.name} 的相关附件',
        ),
      ),
    ),
  );

  if (!context.mounted) return;
  await context.read<ContactDetailProvider>().refresh();
}

Future<void> addMilestoneAction(BuildContext context, String contactId) async {
  final draft = await showMilestoneFormDialog(context);
  if (draft == null || !context.mounted) return;

  final service = context.read<ContactMilestoneService>();
  await service.createMilestone(contactId, draft);

  if (!context.mounted) return;
  await context.read<ContactDetailProvider>().refresh();
}

Future<void> editMilestoneAction(
  BuildContext context,
  ContactMilestone milestone,
) async {
  final draft = await showMilestoneFormDialog(context, existing: milestone);
  if (draft == null || !context.mounted) return;

  final service = context.read<ContactMilestoneService>();
  await service.updateMilestone(milestone.copyWith(
    type: draft.type,
    label: draft.label,
    milestoneDate: draft.milestoneDate,
    isLunar: draft.isLunar,
    isRecurring: draft.isRecurring,
    reminderEnabled: draft.reminderEnabled,
    reminderDaysBefore: draft.reminderDaysBefore,
    notes: draft.notes,
  ));

  if (!context.mounted) return;
  await context.read<ContactDetailProvider>().refresh();
}

Future<void> deleteMilestoneAction(
  BuildContext context,
  ContactMilestone milestone,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('删除重要日期'),
      content: Text('确定删除「${milestone.displayName}」吗？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('删除'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final service = context.read<ContactMilestoneService>();
  await service.deleteMilestone(milestone.id);

  if (!context.mounted) return;
  await context.read<ContactDetailProvider>().refresh();
}

/// 切换到 Notes 页并激活该联系人的筛选，让用户查看与该联系人关联的所有笔记。
Future<void> openNotesFilteredByContact(
  BuildContext context,
  Contact contact,
) async {
  await context.read<NotesProvider>().setFilter(
    NotesFilter(contactId: contact.id, contactName: contact.name),
  );

  if (!context.mounted) return;

  await Navigator.of(context).push(
    buildAdaptiveDetailRoute(const NotesOverviewScreen()),
  );

  if (!context.mounted) return;
  context.read<NotesProvider>().clearFilter();
}