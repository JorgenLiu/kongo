import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/contact.dart';

/// 联系人列表项卡片
class ContactCard extends StatelessWidget {
  final Contact contact;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ContactCard({
    super.key,
    required this.contact,
    this.selected = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final groupLabels = contact.tags.take(3).toList();
    final remainingGroupCount = contact.tags.length > 3 ? contact.tags.length - 3 : 0;

    return Card(
      color: selected ? colorScheme.primaryContainer.withValues(alpha: AppOpacity.half) : null,
      child: GestureDetector(
        onSecondaryTapDown: (onEdit != null || onDelete != null)
            ? (details) => _showContextMenu(context, details.globalPosition)
            : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          hoverColor: colorScheme.primary.withValues(alpha: AppOpacity.subtle),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(context),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              contact.name,
                              style: const TextStyle(
                                fontSize: AppFontSize.titleMedium,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Align(
                              alignment: Alignment.topRight,
                              child: groupLabels.isEmpty
                                  ? Text(
                                      '未分组',
                                      style: TextStyle(
                                        fontSize: AppFontSize.labelSmall,
                                        color: colorScheme.outline,
                                      ),
                                    )
                                  : Wrap(
                                      alignment: WrapAlignment.end,
                                      spacing: AppSpacing.xs,
                                      runSpacing: AppSpacing.xs,
                                      children: [
                                        ...groupLabels.map((label) => _buildGroupChip(context, label)),
                                        if (remainingGroupCount > 0)
                                          _buildGroupChip(context, '+$remainingGroupCount'),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        (contact.phone != null && contact.phone!.isNotEmpty)
                            ? contact.phone!
                            : '未填写联系电话',
                        style: TextStyle(
                          fontSize: AppFontSize.bodySmall,
                          color: colorScheme.outline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = <PopupMenuEntry<String>>[];
    if (onEdit != null) {
      items.add(PopupMenuItem(
        value: 'edit',
        child: Row(
          children: [
            Icon(Icons.edit_outlined, size: 18, color: colorScheme.onSurface),
            const SizedBox(width: AppSpacing.sm),
            const Text('编辑'),
          ],
        ),
      ));
    }
    if (onDelete != null) {
      items.add(PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
            const SizedBox(width: AppSpacing.sm),
            Text('删除', style: TextStyle(color: colorScheme.error)),
          ],
        ),
      ));
    }
    if (items.isEmpty) return;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: items,
    ).then((value) {
      if (value == 'edit') onEdit?.call();
      if (value == 'delete') onDelete?.call();
    });
  }

  Widget _buildAvatar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: AppDimensions.contactAvatarSize,
      height: AppDimensions.contactAvatarSize,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      alignment: Alignment.center,
      child: contact.avatar != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md - 2),
              child: Image.network(
                contact.avatar!,
                width: AppDimensions.contactAvatarSize,
                height: AppDimensions.contactAvatarSize,
                fit: BoxFit.cover,
              ),
            )
          : Text(
              contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontSize: AppFontSize.titleMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildGroupChip(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: AppOpacity.half),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: AppFontSize.labelSmall,
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
