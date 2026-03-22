import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/event_summary.dart';

class DailySummaryList extends StatelessWidget {
  final List<DailySummary> summaries;
  final ValueChanged<DailySummary>? onTap;
  final ValueChanged<DailySummary>? onEdit;
  final ValueChanged<DailySummary>? onDelete;

  const DailySummaryList({
    super.key,
    required this.summaries,
    this.onTap,
    this.onEdit,
    this.onDelete,
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
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  final DailySummary summary;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _DailySummaryCard({
    required this.summary,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Ink(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
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
                if (onEdit != null || onDelete != null)
                  PopupMenuButton<_SummaryMenuAction>(
                    onSelected: (action) {
                      switch (action) {
                        case _SummaryMenuAction.edit:
                          onEdit?.call();
                        case _SummaryMenuAction.delete:
                          onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<_SummaryMenuAction>(
                        value: _SummaryMenuAction.edit,
                        child: Text('编辑'),
                      ),
                      PopupMenuItem<_SummaryMenuAction>(
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
    );
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
    final displayContent = content.trim().isEmpty ? '未填写' : content.trim();

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
        Text(
          displayContent,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
        ),
      ],
    );
  }
}

enum _SummaryMenuAction { edit, delete }