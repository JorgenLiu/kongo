import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/quick_note.dart';
import '../../widgets/notes/linked_notes_section.dart';

/// 联系人详情页的关联笔记预览区块，最多展示 3 条，并提供"查看全部"入口。
class ContactDetailNotesSection extends StatelessWidget {
  final List<QuickNote> notes;
  final VoidCallback? onViewAll;

  const ContactDetailNotesSection({
    super.key,
    required this.notes,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();

    final preview = notes.take(3).toList();
    final hasMore = notes.length > 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinkedNotesSection(notes: preview),
        if (onViewAll != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onViewAll,
              icon: const Icon(Icons.open_in_new, size: 14),
              label: Text(
                hasMore
                    ? '查看全部 ${notes.length} 条记录'
                    : '在记录页查看',
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
