import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../exceptions/app_exception.dart';
import '../../models/attachment.dart';
import '../../models/attachment_link.dart';
import '../../models/event.dart';
import '../../models/event_draft.dart';
import '../../providers/attachment_provider.dart';
import '../../providers/event_detail_provider.dart';
import '../../providers/event_provider.dart';
import '../../services/event_service.dart';
import '../../utils/attachment_action_helpers.dart';
import '../../utils/contact_action_helpers.dart';
import '../../utils/event_follow_up_note_formatter.dart';
import '../../utils/event_action_helpers.dart';
import '../../config/page_transitions.dart';
import '../../utils/navigation_helpers.dart';
import '../contacts/contact_detail_screen.dart';
import 'event_form_screen.dart';

Future<void> openEventParticipantContactDetail(BuildContext context, String contactId) async {
  await Navigator.of(context).push(
    buildAdaptiveDetailRoute(
      ContactDetailScreen(contactId: contactId),
    ),
  );
}

Future<void> editEventDetail(
  BuildContext context, {
  required Event event,
  required Map<String, String> participantRoles,
}) async {
  final draft = await Navigator.of(context).push<EventDraft>(
    SideSheetPageRoute(
      builder: (_) => EventFormScreen(
        initialEvent: event,
        initialParticipantRoles: participantRoles,
        sideSheet: true,
      ),
    ),
  );

  if (draft == null || !context.mounted) {
    return;
  }

  final provider = context.read<EventProvider>();
  await provider.updateEvent(
    event.copyWith(
      title: draft.title,
      eventTypeId: draft.eventTypeId,
      startAt: draft.startAt,
      endAt: draft.endAt,
      location: draft.location,
      description: draft.description,
      reminderEnabled: draft.reminderEnabled,
      reminderAt: draft.reminderAt,
      createdByContactId: draft.createdByContactId,
    ),
    draft.participantIds,
    participantRoles: draft.participantRoles,
  );

  if (!context.mounted) {
    return;
  }

  showProviderResultSnackBar(
    context,
    error: provider.error,
    successMessage: '事件已更新',
    onErrorHandled: provider.clearError,
  );

  if (provider.error == null) {
    await context.read<EventDetailProvider>().refresh();
  }
}

Future<void> deleteEventDetail(
  BuildContext context, {
  required Event event,
}) async {
  final confirmed = await showDeleteEventConfirmDialog(
    context,
    event: event,
  );

  if (!confirmed || !context.mounted) {
    return;
  }

  final provider = context.read<EventProvider>();
  await provider.deleteEvent(event.id);

  if (!context.mounted) {
    return;
  }

  showProviderResultSnackBar(
    context,
    error: provider.error,
    successMessage: '事件已删除',
    onErrorHandled: provider.clearError,
  );

  if (provider.error == null) {
    Navigator.of(context).pop(true);
  }
}

Future<void> addEventAttachment(
  BuildContext context, {
  required Event event,
}) async {
  final importSelection = await pickAttachmentImportSelection(context);
  if (importSelection == null || !context.mounted) {
    return;
  }

  final provider = context.read<AttachmentProvider>();
  await provider.addAttachmentFromPath(
    importSelection.sourcePath,
    ownerType: AttachmentOwnerType.event,
    ownerId: event.id,
    preferredStorageMode: importSelection.preferredStorageMode,
    importPolicy: importSelection.importPolicy,
    allowLargeFile: importSelection.allowLargeFile,
  );

  if (!context.mounted) {
    return;
  }

  showProviderResultSnackBar(
    context,
    error: provider.error,
    successMessage: '附件已添加',
    onErrorHandled: provider.clearError,
  );

  if (provider.error == null) {
    await context.read<EventDetailProvider>().refresh();
  }
}

Future<void> openEventAttachment(
  BuildContext context, {
  required Attachment attachment,
}) async {
  final provider = context.read<AttachmentProvider>();
  await provider.openAttachment(attachment);

  if (!context.mounted) {
    return;
  }

  showProviderResultSnackBar(
    context,
    error: provider.error,
    successMessage: '正在打开附件',
    onErrorHandled: provider.clearError,
  );
}

Future<void> unlinkEventAttachment(
  BuildContext context, {
  required Event event,
  required Attachment attachment,
}) async {
  final confirmed = await showUnlinkAttachmentConfirmDialog(
    context,
    attachment: attachment,
  );

  if (!confirmed || !context.mounted) {
    return;
  }

  final provider = context.read<AttachmentProvider>();
  await provider.unlinkAttachment(
    attachment.id,
    ownerType: AttachmentOwnerType.event,
    ownerId: event.id,
  );

  if (!context.mounted) {
    return;
  }

  showProviderResultSnackBar(
    context,
    error: provider.error,
    successMessage: '附件关联已移除',
    onErrorHandled: provider.clearError,
  );

  if (provider.error == null) {
    await context.read<EventDetailProvider>().refresh();
  }
}

Future<void> deleteEventAttachment(
  BuildContext context, {
  required Event event,
  required Attachment attachment,
}) async {
  final confirmed = await showDeleteAttachmentConfirmDialog(
    context,
    attachment: attachment,
  );

  if (!confirmed || !context.mounted) {
    return;
  }

  final provider = context.read<AttachmentProvider>();
  await provider.deleteAttachment(
    attachment.id,
    ownerType: AttachmentOwnerType.event,
    ownerId: event.id,
  );

  if (!context.mounted) {
    return;
  }

  showProviderResultSnackBar(
    context,
    error: provider.error,
    successMessage: '附件已删除',
    onErrorHandled: provider.clearError,
  );

  if (provider.error == null) {
    await context.read<EventDetailProvider>().refresh();
  }
}

Future<void> saveEventFollowUpNote(
  BuildContext context, {
  required Event event,
  required String note,
}) async {
  final normalizedNote = note.trim();
  if (normalizedNote.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('请先输入会后补充内容')),
    );
    return;
  }

  final eventService = context.read<EventService>();
  try {
    await eventService.updateEvent(
      event.copyWith(
        description: appendEventFollowUpNote(event.description, normalizedNote),
      ),
    );

    if (!context.mounted) {
      return;
    }

    await context.read<EventDetailProvider>().refresh();
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('会后补充已保存')));
  } on AppException catch (error) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error.message)));
  } catch (_) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('保存会后补充失败，请稍后重试')));
  }
}
