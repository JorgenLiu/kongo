import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/attachment.dart';
import '../common/section_card.dart';
import 'attachment_list.dart';

class EventDetailAttachmentsSection extends StatelessWidget {
  final List<Attachment> attachments;
  final VoidCallback? onOpenInLibrary;
  final VoidCallback? onAddAttachment;
  final ValueChanged<Attachment>? onOpenAttachment;
  final ValueChanged<Attachment>? onUnlinkAttachment;
  final ValueChanged<Attachment>? onDeleteAttachment;

  const EventDetailAttachmentsSection({
    super.key,
    required this.attachments,
    this.onOpenInLibrary,
    this.onAddAttachment,
    this.onOpenAttachment,
    this.onUnlinkAttachment,
    this.onDeleteAttachment,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      icon: Icons.attach_file_outlined,
      title: '事件附件',
      collapsible: true,
      initiallyExpanded: false,
      trailing: Wrap(
        spacing: AppSpacing.xs,
        children: [
          if (onOpenInLibrary != null)
            TextButton(
              onPressed: onOpenInLibrary,
              child: const Text('查看全部'),
            ),
          if (onAddAttachment != null)
            TextButton.icon(
              onPressed: onAddAttachment,
              icon: const Icon(Icons.attach_file_outlined),
              label: const Text('添加'),
            ),
        ],
      ),
      child: AttachmentList(
        attachments: attachments,
        emptyText: '当前没有事件附件。',
        onTap: onOpenAttachment,
        onUnlink: onUnlinkAttachment,
        onDelete: onDeleteAttachment,
      ),
    );
  }
}