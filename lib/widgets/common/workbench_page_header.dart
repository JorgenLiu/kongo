import 'package:flutter/material.dart';

import '../../config/app_constants.dart';

class WorkbenchPageHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? description;
  final Key? titleKey;
  final Widget? trailing;
  final List<Widget> metadata;

  const WorkbenchPageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.description,
    this.titleKey,
    this.trailing,
    this.metadata = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      title,
                      key: titleKey,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (description != null && description!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Text(
                          description!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.md),
                trailing!,
              ],
            ],
          ),
          if (metadata.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: metadata,
            ),
          ],
        ],
      ),
    );
  }
}