import 'package:flutter/material.dart';

import '../../models/attachment.dart';
import '../common/section_card.dart';
import '../event/attachment_list.dart';

class ContactDetailAttachmentsSection extends StatelessWidget {
  final List<Attachment> attachments;
  final VoidCallback onOpenModule;

  const ContactDetailAttachmentsSection({
    super.key,
    required this.attachments,
    required this.onOpenModule,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '相关附件',
      trailing: TextButton(
        onPressed: onOpenModule,
        child: const Text('进入模块'),
      ),
      child: AttachmentList(
        attachments: attachments,
        emptyText: '当前没有相关附件。',
        maxItems: 3,
      ),
    );
  }
}