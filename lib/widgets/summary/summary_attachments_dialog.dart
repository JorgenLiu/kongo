import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../models/event_summary.dart';
import '../../providers/attachment_provider.dart';
import '../event/event_summary_attachments_section.dart';

class SummaryAttachmentsDialog extends StatefulWidget {
  final DailySummary summary;
  final Future<void> Function() onAddAttachment;
  final Future<void> Function() onRetry;
  final Future<void> Function(String attachmentId) onOpenAttachment;
  final Future<void> Function(String attachmentId) onUnlinkAttachment;
  final Future<void> Function(String attachmentId) onDeleteAttachment;

  const SummaryAttachmentsDialog({
    super.key,
    required this.summary,
    required this.onAddAttachment,
    required this.onRetry,
    required this.onOpenAttachment,
    required this.onUnlinkAttachment,
    required this.onDeleteAttachment,
  });

  @override
  State<SummaryAttachmentsDialog> createState() => _SummaryAttachmentsDialogState();
}

class _SummaryAttachmentsDialogState extends State<SummaryAttachmentsDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      widget.onRetry();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 720,
          maxHeight: 560,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '总结附件',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${widget.summary.summaryDate.year} 年 ${widget.summary.summaryDate.month} 月 ${widget.summary.summaryDate.day} 日',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: '关闭',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: Consumer<AttachmentProvider>(
                  builder: (context, provider, _) {
                    return SingleChildScrollView(
                      child: EventSummaryAttachmentsSection(
                        attachments: provider.attachments,
                        loading: provider.loading,
                        errorMessage: provider.error?.message,
                        onRetry: () => widget.onRetry(),
                        onAddAttachment: () => widget.onAddAttachment(),
                        onOpenAttachment: (attachment) => widget.onOpenAttachment(attachment.id),
                        onUnlinkAttachment: (attachment) => widget.onUnlinkAttachment(attachment.id),
                        onDeleteAttachment: (attachment) => widget.onDeleteAttachment(attachment.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}