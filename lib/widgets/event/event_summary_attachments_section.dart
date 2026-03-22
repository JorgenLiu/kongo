import 'package:flutter/material.dart';

import '../../models/attachment.dart';
import '../common/section_card.dart';
import 'attachment_list.dart';

class EventSummaryAttachmentsSection extends StatelessWidget {
  final List<Attachment> attachments;
  final bool loading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onAddAttachment;
  final ValueChanged<Attachment>? onOpenAttachment;
  final ValueChanged<Attachment>? onUnlinkAttachment;
  final ValueChanged<Attachment>? onDeleteAttachment;

  const EventSummaryAttachmentsSection({
    super.key,
    required this.attachments,
    this.loading = false,
    this.errorMessage,
    this.onRetry,
    this.onAddAttachment,
    this.onOpenAttachment,
    this.onUnlinkAttachment,
    this.onDeleteAttachment,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '总结附件',
      trailing: onAddAttachment == null
          ? null
          : TextButton.icon(
              onPressed: onAddAttachment,
              icon: const Icon(Icons.attach_file_outlined),
              label: const Text('添加'),
            ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (loading && attachments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null && attachments.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(errorMessage!),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('重试'),
            ),
        ],
      );
    }

    return AttachmentList(
      attachments: attachments,
      emptyText: '当前没有总结附件。',
      onTap: onOpenAttachment,
      onUnlink: onUnlinkAttachment,
      onDelete: onDeleteAttachment,
    );
  }
}