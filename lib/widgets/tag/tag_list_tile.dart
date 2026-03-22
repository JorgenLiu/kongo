import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/tag.dart';

class TagListTile extends StatelessWidget {
  final Tag tag;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TagListTile({
    super.key,
    required this.tag,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            Icons.label,
            size: 18,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          tag.name,
          style: const TextStyle(
            fontSize: AppFontSize.bodyLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '创建于 ${tag.createdAt.year}-${tag.createdAt.month.toString().padLeft(2, '0')}-${tag.createdAt.day.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: AppFontSize.bodySmall,
            color: colorScheme.outline,
          ),
        ),
        trailing: PopupMenuButton<_TagMenuAction>(
          onSelected: (action) {
            switch (action) {
              case _TagMenuAction.edit:
                onEdit?.call();
              case _TagMenuAction.delete:
                onDelete?.call();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem<_TagMenuAction>(
              value: _TagMenuAction.edit,
              child: Text('编辑'),
            ),
            PopupMenuItem<_TagMenuAction>(
              value: _TagMenuAction.delete,
              child: Text('删除'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _TagMenuAction { edit, delete }