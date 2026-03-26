import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/attachment_link.dart';
import '../../models/event_summary.dart';
import '../../models/event_summary_draft.dart';
import '../../providers/attachment_provider.dart';
import '../../utils/attachment_action_helpers.dart';
import '../../providers/summary_provider.dart';
import '../../utils/contact_action_helpers.dart';
import '../../widgets/summary/summary_attachments_dialog.dart';
import '../../config/page_transitions.dart';
import 'summary_form_screen.dart';

Future<void> createDailySummary(BuildContext context) async {
  final draft = await Navigator.of(context).push<DailySummaryDraft>(
    SlidePageRoute(
      builder: (_) => const SummaryFormScreen(),
    ),
  );

  if (draft == null || !context.mounted) {
    return;
  }

  final provider = context.read<SummaryProvider>();
  await provider.createSummary(draft);
  if (!context.mounted) {
    return;
  }

  showProviderResultSnackBar(
    context,
    error: provider.error,
    successMessage: '总结已创建',
    onErrorHandled: provider.clearError,
  );
}

Future<void> editDailySummary(
  BuildContext context, {
  required DailySummary summary,
}) async {
  final draft = await Navigator.of(context).push<DailySummaryDraft>(
    SlidePageRoute(
      builder: (_) => SummaryFormScreen(initialSummary: summary),
    ),
  );

  if (draft == null || !context.mounted) {
    return;
  }

  final provider = context.read<SummaryProvider>();
  await provider.updateSummary(
    summary.copyWith(
      summaryDate: draft.summaryDate,
      todaySummary: draft.todaySummary,
      tomorrowPlan: draft.tomorrowPlan,
      source: draft.source,
      createdByContactId: draft.createdByContactId,
      aiJobId: draft.aiJobId,
    ),
  );
  if (!context.mounted) {
    return;
  }

  showProviderResultSnackBar(
    context,
    error: provider.error,
    successMessage: '总结已更新',
    onErrorHandled: provider.clearError,
  );
}

Future<void> deleteDailySummary(
  BuildContext context, {
  required DailySummary summary,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('删除总结'),
      content: Text('确定要删除 ${summary.summaryDate.month} 月 ${summary.summaryDate.day} 日的总结吗？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('删除'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) {
    return;
  }

  final provider = context.read<SummaryProvider>();
  await provider.deleteSummary(summary.id);
  if (!context.mounted) {
    return;
  }

  showProviderResultSnackBar(
    context,
    error: provider.error,
    successMessage: '总结已删除',
    onErrorHandled: provider.clearError,
  );
}

Future<void> manageDailySummaryAttachments(
  BuildContext context, {
  required DailySummary summary,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => SummaryAttachmentsDialog(
      summary: summary,
      onRetry: () => _loadSummaryAttachments(context, summary.id),
      onAddAttachment: () => addSummaryAttachment(context, summary: summary),
      onOpenAttachment: (attachmentId) => openSummaryAttachment(
        context,
        attachmentId: attachmentId,
      ),
      onUnlinkAttachment: (attachmentId) => unlinkSummaryAttachment(
        context,
        summary: summary,
        attachmentId: attachmentId,
      ),
      onDeleteAttachment: (attachmentId) => deleteSummaryAttachment(
        context,
        summary: summary,
        attachmentId: attachmentId,
      ),
    ),
  );
}

Future<void> addSummaryAttachment(
  BuildContext context, {
  required DailySummary summary,
}) async {
  final importSelection = await pickAttachmentImportSelection(context);
  if (importSelection == null || !context.mounted) {
    return;
  }

  final provider = context.read<AttachmentProvider>();
  await provider.addAttachmentFromPath(
    importSelection.sourcePath,
    ownerType: AttachmentOwnerType.summary,
    ownerId: summary.id,
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
}

Future<void> openSummaryAttachment(
  BuildContext context, {
  required String attachmentId,
}) async {
  final provider = context.read<AttachmentProvider>();
  final attachment = provider.attachments.firstWhere((item) => item.id == attachmentId);
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

Future<void> unlinkSummaryAttachment(
  BuildContext context, {
  required DailySummary summary,
  required String attachmentId,
}) async {
  final provider = context.read<AttachmentProvider>();
  final attachment = provider.attachments.firstWhere((item) => item.id == attachmentId);
  final confirmed = await showUnlinkAttachmentConfirmDialog(
    context,
    attachment: attachment,
  );

  if (!confirmed || !context.mounted) {
    return;
  }

  await provider.unlinkAttachment(
    attachment.id,
    ownerType: AttachmentOwnerType.summary,
    ownerId: summary.id,
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
}

Future<void> deleteSummaryAttachment(
  BuildContext context, {
  required DailySummary summary,
  required String attachmentId,
}) async {
  final provider = context.read<AttachmentProvider>();
  final attachment = provider.attachments.firstWhere((item) => item.id == attachmentId);
  final confirmed = await showDeleteAttachmentConfirmDialog(
    context,
    attachment: attachment,
  );

  if (!confirmed || !context.mounted) {
    return;
  }

  await provider.deleteAttachment(
    attachment.id,
    ownerType: AttachmentOwnerType.summary,
    ownerId: summary.id,
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
}

Future<void> _loadSummaryAttachments(BuildContext context, String summaryId) {
  return context.read<AttachmentProvider>().loadSummaryAttachments(summaryId);
}