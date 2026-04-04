import 'package:flutter/material.dart';

import '../../config/app_constants.dart';

/// 首页"今日记录"摘要卡片。
/// 展示当日 Quick Capture 记录数 + 涉及的联系人（最多 3 个）。
/// todayNoteCount 为 0 时隐藏。
class TodayNotesSummaryCard extends StatelessWidget {
  final int count;
  final List<String> contactNames;
  final VoidCallback? onTap;

  const TodayNotesSummaryCard({
    super.key,
    required this.count,
    required this.contactNames,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(Icons.edit_note, size: 20, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '今天记了 $count 条',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (contactNames.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                const Text('·'),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ContactChips(names: contactNames),
                ),
              ] else
                const Spacer(),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactChips extends StatelessWidget {
  final List<String> names;

  const _ContactChips({required this.names});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final display = names.take(3).toList();

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final name in display)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              name,
              style: TextStyle(
                fontSize: AppFontSize.bodySmall,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
      ],
    );
  }
}
