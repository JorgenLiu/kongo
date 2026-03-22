import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event_summary.dart';
import '../../models/event_summary_draft.dart';
import '../../providers/summary_provider.dart';
import '../../utils/contact_action_helpers.dart';
import 'summary_form_screen.dart';

Future<void> createDailySummary(BuildContext context) async {
  final draft = await Navigator.of(context).push<DailySummaryDraft>(
    MaterialPageRoute(
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
    MaterialPageRoute(
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