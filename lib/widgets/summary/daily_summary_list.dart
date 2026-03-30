import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/event_summary.dart';
import 'summary_markdown_content.dart';

class DailySummaryList extends StatelessWidget {
  final List<DailySummary> summaries;
  final ValueChanged<DailySummary>? onTap;
  final ValueChanged<DailySummary>? onEdit;
  final ValueChanged<DailySummary>? onDelete;
  final ValueChanged<DailySummary>? onManageAttachments;

  const DailySummaryList({
    super.key,
    required this.summaries,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onManageAttachments,
  });

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return Text(
        '还没有每日总结摘要。',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }

    return Column(
      children: summaries
          .map(
            (summary) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _DailySummaryCard(
                summary: summary,
                onTap: onTap == null ? null : () => onTap!(summary),
                onEdit: onEdit == null ? null : () => onEdit!(summary),
                onDelete: onDelete == null ? null : () => onDelete!(summary),
                onManageAttachments: onManageAttachments == null
                    ? null
                    : () => onManageAttachments!(summary),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DailySummaryCard extends StatefulWidget {
  final DailySummary summary;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onManageAttachments;

  const _DailySummaryCard({
    required this.summary,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onManageAttachments,
  });

  @override
  State<_DailySummaryCard> createState() => _DailySummaryCardState();
}

class _DailySummaryCardState extends State<_DailySummaryCard> {
  bool _hovering = false;
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final hasContextMenuActions = widget.onEdit != null || widget.onDelete != null || widget.onManageAttachments != null;

    return Semantics(
      label: '总结 ${summary.summaryDate.year}年${summary.summaryDate.month}月${summary.summaryDate.day}日',
      button: true,
      child: MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() { _hovering = false; _pressing = false; }),
      child: AnimatedScale(
      scale: _pressing ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
      onSecondaryTapDown: hasContextMenuActions
          ? (details) => _showContextMenu(context, details.globalPosition)
          : null,
      onTapDown: widget.onTap != null ? (_) => setState(() => _pressing = true) : null,
      onTapUp: (_) => setState(() => _pressing = false),
      onTapCancel: () => setState(() => _pressing = false),
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, (_hovering && !_pressing) ? -2.0 : 0.0, 0),
      transformAlignment: Alignment.center,
      child: Card(
      elevation: _hovering ? 4 : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
      onTap: widget.onTap,
      hoverColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${summary.summaryDate.year} 年 ${summary.summaryDate.month} 月 ${summary.summaryDate.day} 日',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (widget.onEdit != null || widget.onDelete != null || widget.onManageAttachments != null)
                  PopupMenuButton<_SummaryMenuAction>(
                    onSelected: (action) {
                      switch (action) {
                        case _SummaryMenuAction.attachments:
                          widget.onManageAttachments?.call();
                        case _SummaryMenuAction.edit:
                          widget.onEdit?.call();
                        case _SummaryMenuAction.delete:
                          widget.onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      if (widget.onManageAttachments != null)
                        const PopupMenuItem<_SummaryMenuAction>(
                          value: _SummaryMenuAction.attachments,
                          child: Text('附件'),
                        ),
                      if (widget.onEdit != null)
                        const PopupMenuItem<_SummaryMenuAction>(
                          value: _SummaryMenuAction.edit,
                          child: Text('编辑'),
                        ),
                      if (widget.onDelete != null)
                        const PopupMenuItem<_SummaryMenuAction>(
                          value: _SummaryMenuAction.delete,
                          child: Text('删除'),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _SummaryBlock(
              title: '当日总结',
              content: summary.todaySummary,
            ),
            const SizedBox(height: AppSpacing.sm),
            _SummaryBlock(
              title: '明日计划',
              content: summary.tomorrowPlan,
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

  void _showContextMenu(BuildContext context, Offset position) {
    final colorScheme = Theme.of(context).colorScheme;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        if (widget.onManageAttachments != null)
          PopupMenuItem(
            value: 'attachments',
            child: Row(
              children: [
                Icon(Icons.attach_file_outlined, size: 18, color: colorScheme.onSurface),
                const SizedBox(width: AppSpacing.sm),
                const Text('附件'),
              ],
            ),
          ),
        if (widget.onEdit != null)
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 18, color: colorScheme.onSurface),
                const SizedBox(width: AppSpacing.sm),
                const Text('编辑'),
              ],
            ),
          ),
        if (widget.onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
                const SizedBox(width: AppSpacing.sm),
                Text('删除', style: TextStyle(color: colorScheme.error)),
              ],
            ),
          ),
      ],
    ).then((value) {
      if (value == 'attachments') widget.onManageAttachments?.call();
      if (value == 'edit') widget.onEdit?.call();
      if (value == 'delete') widget.onDelete?.call();
    });
  }
}

class _SummaryBlock extends StatelessWidget {
  final String title;
  final String content;

  const _SummaryBlock({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SummaryMarkdownContent(
          content: content,
          selectable: false,
        ),
      ],
    );
  }
}

enum _SummaryMenuAction { attachments, edit, delete }