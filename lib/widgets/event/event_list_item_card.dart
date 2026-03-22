import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/event.dart';
import '../../utils/display_formatters.dart';
import '../search/highlighted_search_text.dart';

class EventListItemCard extends StatelessWidget {
  final Event event;
  final String? eventTypeName;
  final List<String> participantNames;
  final String? highlightQuery;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EventListItemCard({
    super.key,
    required this.event,
    this.eventTypeName,
    this.participantNames = const [],
    this.highlightQuery,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final metadata = <_MetaItem>[
      if (eventTypeName != null && eventTypeName!.isNotEmpty)
        _MetaItem(icon: Icons.sell_outlined, label: eventTypeName!),
      if (event.location != null && event.location!.isNotEmpty)
        _MetaItem(icon: Icons.place_outlined, label: event.location!),
      if (event.startAt != null)
        _MetaItem(icon: Icons.schedule_outlined, label: formatDateTimeLabel(event.startAt!)),
    ];

    return Card(
      child: GestureDetector(
        onSecondaryTapDown: (onEdit != null || onDelete != null)
            ? (details) => _showContextMenu(context, details.globalPosition)
            : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          hoverColor: colorScheme.primary.withValues(alpha: AppOpacity.subtle),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.event_note_outlined,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: HighlightedSearchText(
                        text: event.title,
                        query: highlightQuery,
                        style: const TextStyle(
                          fontSize: AppFontSize.titleMedium,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                if (participantNames.isNotEmpty) ...[
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
                          text: participantNames.join('、'),
                          query: highlightQuery,
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
                      query: highlightQuery,
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
              query: highlightQuery,
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
}

class _MetaItem {
  final IconData icon;
  final String label;

  const _MetaItem({
    required this.icon,
    required this.label,
  });
}