import 'package:flutter/material.dart';

import '../../config/app_constants.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool asCard;
  final double iconSize;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.asCard = false,
    this.iconSize = 56,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: colorScheme.outline.withValues(alpha: 0.45),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          message,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSpacing.lg),
          FilledButton.tonal(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
        ],
      ],
    );

    if (asCard) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: content,
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: content,
      ),
    );
  }
}