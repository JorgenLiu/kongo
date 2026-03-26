import 'package:flutter/material.dart';

import '../../config/app_constants.dart';

class HomeDashboardSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;
  final String? subtitle;
  final double? minHeight;
  final Color? accentBorderColor;

  const HomeDashboardSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    this.subtitle,
    this.minHeight,
    this.accentBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: accentBorderColor != null ? Clip.antiAlias : Clip.none,
      child: Stack(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight ?? 0),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 20, color: colorScheme.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (subtitle != null && subtitle!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                subtitle!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.outline,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  child,
                ],
              ),
            ),
          ),
          if (accentBorderColor != null)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: Container(
                width: 4,
                color: accentBorderColor,
              ),
            ),
        ],
      ),
    );
  }
}