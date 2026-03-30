import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../models/quick_note.dart';
import '../../services/quick_capture_parser.dart';

/// 单条 QuickNote 的卡片展示。
class NoteCard extends StatefulWidget {
  final QuickNote note;
  final String? linkedContactName;

  /// 调用方处理删除（软删除整条笔记）。
  final VoidCallback? onDelete;

  /// 调用方处理清除 AI topics。
  final VoidCallback? onClearTopics;

  const NoteCard({
    super.key,
    required this.note,
    this.linkedContactName,
    this.onDelete,
    this.onClearTopics,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  bool _hovered = false;
  bool _pressing = false;

  List<String> get _topics {
    final raw = widget.note.aiMetadata?['topics'];
    if (raw is List) return raw.whereType<String>().toList();
    return const [];
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() { _hovered = false; _pressing = false; }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressing = true),
        onTapUp: (_) => setState(() => _pressing = false),
        onTapCancel: () => setState(() => _pressing = false),
        child: AnimatedScale(
          scale: _pressing ? 0.99 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, (_hovered && !_pressing) ? -1.0 : 0.0, 0),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered
                  ? colorScheme.primary.withValues(alpha: 0.04)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NoteTypeIndicator(noteType: widget.note.noteType),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.note.content,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (widget.linkedContactName != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _ContactChip(name: widget.linkedContactName!),
                  ],
                  if (_topics.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _TopicsRow(
                      topics: _topics,
                      onClearAll: widget.onClearTopics,
                      hovered: _hovered,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _formatTime(widget.note.createdAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
            if (widget.onDelete != null) ...[
              const SizedBox(width: AppSpacing.xs),
              AnimatedOpacity(
                opacity: _hovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  iconSize: 16,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  tooltip: '删除笔记',
                  color: colorScheme.error,
                  onPressed: widget.onDelete,
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
}

class _TopicsRow extends StatelessWidget {
  final List<String> topics;
  final VoidCallback? onClearAll;
  final bool hovered;

  const _TopicsRow({
    required this.topics,
    this.onClearAll,
    this.hovered = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        ...topics.map((t) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Text(
              t,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          );
        }),
        if (onClearAll != null && hovered)
          GestureDetector(
            onTap: onClearAll,
            child: Tooltip(
              message: '移除 topics',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Icon(
                  Icons.close,
                  size: 12,
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NoteTypeIndicator extends StatelessWidget {
  final QuickNoteType noteType;

  const _NoteTypeIndicator({required this.noteType});

  @override
  Widget build(BuildContext context) {
    final isStructured = noteType == QuickNoteType.structured;
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Icon(
        isStructured ? Icons.person_outline : Icons.lightbulb_outline,
        size: 14,
        color: isStructured ? AppColors.primary : AppColors.info,
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  final String name;

  const _ContactChip({required this.name});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person,
            size: 10,
            color: colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 3),
          Text(
            name,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
