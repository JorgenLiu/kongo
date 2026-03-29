import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/event.dart';

enum QuickCaptureEventChoice {
  /// 关联到已有事件
  linkExisting,

  /// 创建新事件
  createNew,

  /// 跳过，存为 knowledge note
  skip,
}

class QuickCaptureEventConfirmResult {
  final QuickCaptureEventChoice choice;

  /// non-null 当 choice == linkExisting
  final String? existingEventId;

  /// non-null 当 choice == createNew
  final String? newEventTitle;

  /// 事件日期
  final DateTime? eventDate;

  const QuickCaptureEventConfirmResult._({
    required this.choice,
    this.existingEventId,
    this.newEventTitle,
    this.eventDate,
  });

  factory QuickCaptureEventConfirmResult.linkExisting(String eventId) =>
      QuickCaptureEventConfirmResult._(
        choice: QuickCaptureEventChoice.linkExisting,
        existingEventId: eventId,
      );

  factory QuickCaptureEventConfirmResult.createNew({
    required String title,
    required DateTime date,
  }) =>
      QuickCaptureEventConfirmResult._(
        choice: QuickCaptureEventChoice.createNew,
        newEventTitle: title,
        eventDate: date,
      );

  const QuickCaptureEventConfirmResult.skip()
      : choice = QuickCaptureEventChoice.skip,
        existingEventId = null,
        newEventTitle = null,
        eventDate = null;
}

/// 弹出 Quick Capture 事件确认对话框。
///
/// - 当 [existingEvents] 非空时，提供"关联到已有事件"选项列表。
/// - 始终提供"创建新事件"选项（标题可编辑）。
/// - 任何路径都提供"跳过"出口。
///
/// 对话框被直接关闭（点击外部或 ESC）时返回 null，行为等同于跳过。
Future<QuickCaptureEventConfirmResult?> showQuickCaptureEventConfirmDialog(
  BuildContext context, {
  required String suggestedTitle,
  required DateTime detectedDate,
  required List<Event> existingEvents,
}) {
  return showDialog<QuickCaptureEventConfirmResult>(
    context: context,
    builder: (context) => _QuickCaptureEventConfirmDialog(
      suggestedTitle: suggestedTitle,
      detectedDate: detectedDate,
      existingEvents: existingEvents,
    ),
  );
}

class _QuickCaptureEventConfirmDialog extends StatefulWidget {
  final String suggestedTitle;
  final DateTime detectedDate;
  final List<Event> existingEvents;

  const _QuickCaptureEventConfirmDialog({
    required this.suggestedTitle,
    required this.detectedDate,
    required this.existingEvents,
  });

  @override
  State<_QuickCaptureEventConfirmDialog> createState() =>
      _QuickCaptureEventConfirmDialogState();
}

class _QuickCaptureEventConfirmDialogState
    extends State<_QuickCaptureEventConfirmDialog> {
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.suggestedTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  bool get _hasExisting => widget.existingEvents.isNotEmpty;

  String get _formattedDate {
    final date = widget.detectedDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    final dayLabel = switch (diff) {
      0 => '今天',
      1 => '明天',
      2 => '后天',
      _ => '${date.month}月${date.day}日',
    };

    if (date.hour > 0) {
      final timeOfDay = switch (date.hour) {
        >= 5 && < 12 => '上午',
        >= 12 && < 14 => '中午',
        >= 14 && < 18 => '下午',
        _ => '晚上',
      };
      return '$dayLabel$timeOfDay';
    }
    return dayLabel;
  }

  void _linkExisting(String eventId) {
    Navigator.of(context).pop(
      QuickCaptureEventConfirmResult.linkExisting(eventId),
    );
  }

  void _createNew() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(
      QuickCaptureEventConfirmResult.createNew(
        title: title,
        date: widget.detectedDate,
      ),
    );
  }

  void _skip() {
    Navigator.of(context).pop(const QuickCaptureEventConfirmResult.skip());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('识别到时间'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '检测到「$_formattedDate」，是否创建事件或关联到已有事件？',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            // 事件标题编辑
            TextField(
              controller: _titleController,
              autofocus: !_hasExisting,
              decoration: const InputDecoration(
                labelText: '事件标题',
                hintText: '输入或修改事件标题',
              ),
              onSubmitted: (_) => _createNew(),
            ),
            // 已有事件列表
            if (_hasExisting) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                '同日已有事件：',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.existingEvents.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    final event = widget.existingEvents[index];
                    final timeStr = event.startAt != null
                        ? '${event.startAt!.hour.toString().padLeft(2, '0')}:${event.startAt!.minute.toString().padLeft(2, '0')}'
                        : '';
                    return OutlinedButton.icon(
                      onPressed: () => _linkExisting(event.id),
                      icon: const Icon(Icons.link, size: 16),
                      label: Text(
                        timeStr.isNotEmpty
                            ? '$timeStr ${event.title}'
                            : event.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _skip,
          child: const Text('跳过'),
        ),
        FilledButton(
          onPressed: _createNew,
          child: const Text('创建新事件'),
        ),
      ],
    );
  }
}
