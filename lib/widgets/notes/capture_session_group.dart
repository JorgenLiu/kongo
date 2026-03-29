import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/quick_note.dart';
import '../../services/read/notes_read_service.dart';
import 'note_card.dart';

/// 一个会话分组：展示时间范围标题 + 可展开/收起的笔记列表。
class CaptureSessionGroup extends StatefulWidget {
  final CaptureSession session;

  /// contactId → contactName 映射，用于渲染关联联系人姓名。
  final Map<String, String> contactNames;

  /// 删除笔记回调（传入 noteId）。
  final void Function(String noteId)? onDeleteNote;

  /// 清除笔记 topics 回调（传入 noteId）。
  final void Function(String noteId)? onClearTopics;

  const CaptureSessionGroup({
    super.key,
    required this.session,
    this.contactNames = const {},
    this.onDeleteNote,
    this.onClearTopics,
  });

  @override
  State<CaptureSessionGroup> createState() => _CaptureSessionGroupState();
}

class _CaptureSessionGroupState extends State<CaptureSessionGroup> {
  bool _expanded = true;

  CaptureSession get _session => widget.session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: colorScheme.outline,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _buildSessionHeader(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (_sessionLabel() != null) ...[
                  _SessionLabelChip(label: _sessionLabel()!),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    '${_session.notes.length} 条',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          ...widget.session.notes.map((note) => NoteCard(
                note: note,
                linkedContactName: _contactName(note),
                onDelete: widget.onDeleteNote != null
                    ? () => widget.onDeleteNote!(note.id)
                    : null,
                onClearTopics: widget.onClearTopics != null
                    ? () => widget.onClearTopics!(note.id)
                    : null,
              )),
      ],
    );
  }

  String _buildSessionHeader() {
    final start = _formatTime(_session.startAt);
    if (_session.notes.length == 1) {
      return start;
    }
    final end = _formatTime(_session.endAt);
    return '$start – $end';
  }

  String? _contactName(QuickNote note) {
    if (note.linkedContactId == null) return null;
    return widget.contactNames[note.linkedContactId];
  }

  /// 从会话内任意笔记的 aiMetadata 中取 sessionLabel（取第一个非 null 值）。
  String? _sessionLabel() {
    for (final note in _session.notes) {
      final label = note.aiMetadata?['sessionLabel'];
      if (label is String && label.isNotEmpty) return label;
    }
    return null;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _SessionLabelChip extends StatelessWidget {
  final String label;

  const _SessionLabelChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onTertiaryContainer,
        ),
      ),
    );
  }
}
