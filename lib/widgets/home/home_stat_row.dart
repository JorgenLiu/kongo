import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_constants.dart';

class HomeStatRow extends StatelessWidget {
  final int contactCount;
  final int weekEventCount;
  final int pendingActionCount;
  final VoidCallback? onContactsTap;
  final VoidCallback? onWeekEventsTap;
  final VoidCallback? onPendingActionsTap;

  const HomeStatRow({
    super.key,
    required this.contactCount,
    required this.weekEventCount,
    required this.pendingActionCount,
    this.onContactsTap,
    this.onWeekEventsTap,
    this.onPendingActionsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _StatChip(
          icon: Icons.people_outline,
          label: '$contactCount 位联系人',
          onTap: onContactsTap,
        ),
        _StatChip(
          icon: Icons.event_outlined,
          label: '本周 $weekEventCount 项安排',
          onTap: onWeekEventsTap,
        ),
        _StatChip(
          icon: Icons.checklist_outlined,
          label: '待处理 $pendingActionCount 项',
          subdued: pendingActionCount == 0,
          urgent: pendingActionCount > 0,
          onTap: onPendingActionsTap,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool subdued;
  final bool urgent;
  final VoidCallback? onTap;

  const _StatChip({
    required this.icon,
    required this.label,
    this.subdued = false,
    this.urgent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final chip = Container(
      decoration: BoxDecoration(
        color: subdued
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (urgent) ...[                Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Icon(
              icon,
              size: 16,
              color: subdued ? colorScheme.outline : colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: subdued ? colorScheme.outline : colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
              ),
          ],
        ),
      ),
    );

    if (onTap == null) return chip;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: chip,
      ),
    );
  }
}
