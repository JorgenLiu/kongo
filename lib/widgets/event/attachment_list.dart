import 'package:flutter/material.dart';

import '../../models/attachment.dart';
import '../../utils/display_formatters.dart';

class AttachmentList extends StatelessWidget {
  final List<Attachment> attachments;
  final String emptyText;
  final int? maxItems;
  final ValueChanged<Attachment>? onTap;
  final ValueChanged<Attachment>? onUnlink;
  final ValueChanged<Attachment>? onDelete;

  const AttachmentList({
    super.key,
    required this.attachments,
    required this.emptyText,
    this.maxItems,
    this.onTap,
    this.onUnlink,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (attachments.isEmpty) {
      return Text(
        emptyText,
        style: TextStyle(color: colorScheme.outline),
      );
    }

    final visibleItems = maxItems == null ? attachments : attachments.take(maxItems!).toList();
    return Column(
      children: visibleItems
          .map(
            (attachment) => ListTile(
              onTap: onTap == null ? null : () => onTap!(attachment),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.attach_file_outlined),
              title: Text(attachment.fileName),
              subtitle: Text(formatFileSizeLabel(attachment.sizeBytes)),
              trailing: onUnlink == null && onDelete == null
                  ? null
                  : PopupMenuButton<_AttachmentMenuAction>(
                      onSelected: (action) {
                        switch (action) {
                          case _AttachmentMenuAction.unlink:
                            onUnlink?.call(attachment);
                          case _AttachmentMenuAction.delete:
                            onDelete?.call(attachment);
                        }
                      },
                      itemBuilder: (context) => [
                        if (onUnlink != null)
                          const PopupMenuItem<_AttachmentMenuAction>(
                            value: _AttachmentMenuAction.unlink,
                            child: Text('移除关联'),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem<_AttachmentMenuAction>(
                            value: _AttachmentMenuAction.delete,
                            child: Text('删除附件'),
                          ),
                      ],
                    ),
            ),
          )
          .toList(),
    );
  }
}

enum _AttachmentMenuAction { unlink, delete }