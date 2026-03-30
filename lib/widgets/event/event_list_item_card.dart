import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/event.dart';
import '../../utils/display_formatters.dart';
import '../search/highlighted_search_text.dart';

class EventListItemCard extends StatefulWidget {
  final Event event;
  final String? eventTypeName;
  final String? eventTypeColor;
  final List<String> participantNames;
  final String? highlightQuery;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EventListItemCard({
    super.key,
    required this.event,
    this.eventTypeName,
    this.eventTypeColor,
    this.participantNames = const [],
    this.highlightQuery,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<EventListItemCard> createState() => _EventListItemCardState();
}

class _EventListItemCardState extends State<EventListItemCard> {
  bool _hovering = false;
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final event = widget.event;
    final hasActions = widget.onEdit != null || widget.onDelete != null;
    final metadata = <_MetaItem>[
      if (widget.eventTypeName != null && widget.eventTypeName!.isNotEmpty)
        _MetaItem(icon: Icons.sell_outlined, label: widget.eventTypeName!),
      if (event.location != null && event.location!.isNotEmpty)
        _MetaItem(icon: Icons.place_outlined, label: event.location!),
      if (event.startAt != null)
        _MetaItem(icon: Icons.schedule_outlined, label: formatDateTimeLabel(event.startAt!)),
    ];

    return Semantics(
      label: '日程 ${event.title}${widget.eventTypeName != null ? '，类型 ${widget.eventTypeName}' : ''}${event.startAt != null ? '，时间 ${formatDateTimeLabel(event.startAt!)}' : ''}',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _eventTypeContainerColor(colorScheme),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.event_note_outlined,
                        size: 20,
                        color: _eventTypeIconColor(colorScheme),
                      ),
                    ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: HighlightedSearchText(
                        text: event.title,
                        query: widget.highlightQuery,
                        style: const TextStyle(
                          fontSize: AppFontSize.titleMedium,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: _hovering && hasActions
                          ? Row(
                              key: const ValueKey('actions'),
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
                            )
                          : const SizedBox.shrink(key: ValueKey('empty')),
                    ),
                  ],
                ),
                if (metadata.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: metadata.map((item) => _buildMetaPill(context, item)).toList(),
                  ),
                ],
                if (widget.participantNames.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.group_outlined,
                        size: 16,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: HighlightedSearchText(
                          text: widget.participantNames.join('、'),
                          query: widget.highlightQuery,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colorScheme.outline),
                        ),
                      ),
                    ],
                  ),
                ],
                if (event.description != null && event.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: HighlightedSearchText(
                      text: event.description!,
                      query: widget.highlightQuery,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
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

  Widget _buildMetaPill(BuildContext context, _MetaItem item) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: AppOpacity.elevated),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.icon,
            size: 14,
            color: colorScheme.outline,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: HighlightedSearchText(
              text: item.label,
              query: widget.highlightQuery,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final raw = hex.replaceFirst('#', '');
    final value = int.tryParse(raw, radix: 16);
    if (value == null) return null;
    return raw.length == 6 ? Color(0xFF000000 | value) : Color(value);
  }

  Color _eventTypeContainerColor(ColorScheme scheme) {
    final c = _parseHex(widget.eventTypeColor);
    return c?.withAlpha(38) ?? scheme.primaryContainer;
  }

  Color _eventTypeIconColor(ColorScheme scheme) {
    return _parseHex(widget.eventTypeColor) ?? scheme.primary;
  }
}

class _MetaItem {
  final IconData icon;
  final String label;

  const _MetaItem({
    required this.icon,
    required this.label,
  });
}