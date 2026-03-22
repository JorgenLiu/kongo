import 'package:flutter/material.dart';

import '../../config/app_constants.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool asCard;
  final double iconSize;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.asCard = false,
    this.iconSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: colorScheme.outline.withValues(alpha: 0.7),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppFontSize.bodyMedium,
            color: colorScheme.outline,
          ),
        ),
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

    return Center(child: content);
  }
}