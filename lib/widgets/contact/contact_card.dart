import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/contact.dart';
import '../../utils/avatar_colors.dart';

/// 联系人列表项卡片
class ContactCard extends StatefulWidget {
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
  State<ContactCard> createState() => _ContactCardState();
}

class _ContactCardState extends State<ContactCard> {
  static const double _actionSlotWidth = 76;
  bool _hovering = false;
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final contact = widget.contact;
    final groupLabels = contact.tags.take(2).toList();
    final remainingGroupCount = contact.tags.length > 2 ? contact.tags.length - 2 : 0;
    final hasActions = widget.onEdit != null || widget.onDelete != null;

    return Semantics(
      label: '联系人 ${contact.name}${contact.phone != null && contact.phone!.isNotEmpty ? '，电话 ${contact.phone}' : ''}',
      button: true,
      child: MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() { _hovering = false; _pressing = false; }),
      child: AnimatedScale(
      scale: _pressing ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, (_hovering && !_pressing) ? -2.0 : 0.0, 0),
      transformAlignment: Alignment.center,
      child: Card(
      elevation: _hovering ? 4 : null,
      color: widget.selected ? colorScheme.primaryContainer.withValues(alpha: AppOpacity.half) : null,
      child: GestureDetector(
        onSecondaryTapDown: hasActions
            ? (details) => _showContextMenu(context, details.globalPosition)
            : null,
        onTapDown: widget.onTap != null ? (_) => setState(() => _pressing = true) : null,
        onTapUp: (_) => setState(() => _pressing = false),
        onTapCancel: () => setState(() => _pressing = false),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: widget.onTap,
          hoverColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 12,
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
                if (hasActions)
                  SizedBox(
                    width: _actionSlotWidth,
                    child: IgnorePointer(
                      ignoring: !_hovering,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: _hovering ? 1 : 0,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.onEdit != null)
                                _buildHoverAction(
                                  icon: Icons.edit_outlined,
                                  tooltip: '编辑',
                                  onPressed: widget.onEdit!,
                                  color: colorScheme.primary,
                                ),
                              if (widget.onDelete != null)
                                _buildHoverAction(
                                  icon: Icons.delete_outline,
                                  tooltip: '删除',
                                  onPressed: widget.onDelete!,
                                  color: colorScheme.error,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
    ),
    ),
    ),
    );
  }

  Widget _buildHoverAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: Icon(icon, size: 18),
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        color: color,
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = <PopupMenuEntry<String>>[];
    if (widget.onEdit != null) {
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
    if (widget.onDelete != null) {
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
      if (value == 'edit') widget.onEdit?.call();
      if (value == 'delete') widget.onDelete?.call();
    });
  }

  Widget _buildAvatar(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final name = widget.contact.name;
    final gradient = AvatarColors.gradient(name, brightness: brightness);
    final avatarTextColor = AvatarColors.textColor(name, brightness: brightness);

    return ExcludeSemantics(
      child: Container(
        width: AppDimensions.contactAvatarSize,
        height: AppDimensions.contactAvatarSize,
        decoration: BoxDecoration(
          gradient: widget.contact.avatar == null ? gradient : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.center,
        child: widget.contact.avatar != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.network(
                  widget.contact.avatar!,
                  width: AppDimensions.contactAvatarSize,
                  height: AppDimensions.contactAvatarSize,
                  fit: BoxFit.cover,
                ),
              )
            : Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: avatarTextColor,
                  fontSize: AppFontSize.titleMedium,
                  fontWeight: FontWeight.bold,
                ),
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
        // 果冻感：用主题色透明叠加，去除硬边框
        color: colorScheme.primary.withValues(alpha: AppOpacity.subtle),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: AppFontSize.labelSmall,
          color: colorScheme.primary.withValues(alpha: 0.85),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
