import 'package:flutter/material.dart';

import '../../config/app_constants.dart';

class HomeDailyBriefSummaryPanel extends StatelessWidget {
  final String summary;

  const HomeDailyBriefSummaryPanel({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今日判断',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            summary,
            key: const Key('aiDailyBriefSummaryText'),
            style: textTheme.headlineSmall?.copyWith(
              height: 1.35,
              fontWeight: FontWeight.w800,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}