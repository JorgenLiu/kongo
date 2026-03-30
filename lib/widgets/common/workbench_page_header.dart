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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.sm,
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
                    // Eyebrow：主题色 + 宽字距，更强的版式信号
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 11,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          eyebrow.toUpperCase(),
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary.withValues(alpha: 0.75),
                            letterSpacing: 1.6,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Title：放大到 displaySmall 级别，更强的视觉锚点
                    Text(
                      title,
                      key: titleKey,
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (description != null && description!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Text(
                          description!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.55),
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