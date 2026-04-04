import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/quick_note.dart';
import '../../services/read/notes_read_service.dart';
import 'note_card.dart';

/// 一个会话分组的时间轴视图：左侧时间锚点 + 渐变竖线 + 笔记内容流。
///
/// 取消了折叠交互，改为始终展开的 Timeline 范式。
class CaptureSessionGroup extends StatelessWidget {
  final CaptureSession session;

  /// contactId → contactName 映射，用于渲染关联联系人姓名。
  final Map<String, String> contactNames;

  /// eventId → eventTitle 映射，用于渲染关联事件标题。
  final Map<String, String> eventTitles;

  /// 删除笔记回调（传入 noteId）。
  final void Function(String noteId)? onDeleteNote;

  /// 清除笔记 topics 回调（传入 noteId）。
  final void Function(String noteId)? onClearTopics;

  /// 点击联系人 chip（传入 contactId）。
  final void Function(String contactId)? onContactTap;

  /// 点击事件 chip（传入 eventId）。
  final void Function(String eventId)? onEventTap;

  const CaptureSessionGroup({
    super.key,
    required this.session,
    this.contactNames = const {},
    this.eventTitles = const {},
    this.onDeleteNote,
    this.onClearTopics,
    this.onContactTap,
    this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final sessionLabel = _sessionLabel();

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 时间段标题行 ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 时间标签（固定宽度，右对齐）
              SizedBox(
                width: 42,
                child: Text(
                  _formatTime(session.startAt),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.35),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // 横向延伸的分隔线
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.onSurface.withValues(alpha: 0.10),
                        colorScheme.onSurface.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
              ),
              if (sessionLabel != null) ...[
                const SizedBox(width: AppSpacing.sm),
                _SessionLabelChip(label: sessionLabel),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // ── 时间轴主体：竖线 + 笔记 ──
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 左侧占位（与时间标签对齐）
                const SizedBox(width: 42),
                const SizedBox(width: AppSpacing.sm),
                // 渐变竖线 — 主题色从上到下淡出
                Container(
                  width: 2,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.45),
                        colorScheme.primary.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                // 笔记内容列
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: session.notes
                        .map(
                          (note) => NoteCard(
                            note: note,
                            linkedContactName: _contactName(note),
                            linkedEventTitle: _eventTitle(note),
                            onDelete: onDeleteNote != null
                                ? () => onDeleteNote!(note.id)
                                : null,
                            onClearTopics: onClearTopics != null
                                ? () => onClearTopics!(note.id)
                                : null,
                            onContactTap: (onContactTap != null && note.linkedContactId != null)
                                ? () => onContactTap!(note.linkedContactId!)
                                : null,
                            onEventTap: (onEventTap != null && note.linkedEventId != null)
                                ? () => onEventTap!(note.linkedEventId!)
                                : null,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _contactName(QuickNote note) {
    if (note.linkedContactId == null) return null;
    return contactNames[note.linkedContactId];
  }

  String? _eventTitle(QuickNote note) {
    if (note.linkedEventId == null) return null;
    return eventTitles[note.linkedEventId];
  }

  /// 从会话内任意笔记的 aiMetadata 中取 sessionLabel（取第一个非 null 值）。
  String? _sessionLabel() {
    for (final note in session.notes) {
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
        vertical: 2,
      ),
      decoration: BoxDecoration(
        // 果冻感：主题色极低不透明度背景
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.primary.withValues(alpha: 0.85),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
