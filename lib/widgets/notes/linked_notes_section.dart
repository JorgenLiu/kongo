import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../models/quick_note.dart';
import '../../services/quick_capture_parser.dart';

/// 联系人/事件详情页的只读关联记录区块。
class LinkedNotesSection extends StatelessWidget {
  final List<QuickNote> notes;

  const LinkedNotesSection({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.edit_note, size: 18, color: colorScheme.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '关联记录',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '${notes.length}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...notes.map((note) => _LinkedNoteItem(note: note)),
      ],
    );
  }
}

class _LinkedNoteItem extends StatelessWidget {
  final QuickNote note;

  const _LinkedNoteItem({required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dateStr =
        '${note.captureDate.month.toString().padLeft(2, '0')}/${note.captureDate.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${note.createdAt.hour.toString().padLeft(2, '0')}:${note.createdAt.minute.toString().padLeft(2, '0')}';
    final isStructured = note.noteType == QuickNoteType.structured;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(
              isStructured ? Icons.person_outline : Icons.lightbulb_outline,
              size: 14,
              color: isStructured ? AppColors.primary : AppColors.info,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              note.content,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$dateStr $timeStr',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
