import 'package:flutter/material.dart';

import '../../config/app_constants.dart';

/// 详情页骨架屏加载占位组件
class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _sectionCard(
          context,
          child: Row(
            children: [
              _box(context, 52, 52, borderRadius: AppRadius.md),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(context, double.infinity, 18),
                    const SizedBox(height: AppSpacing.sm),
                    _box(context, 160, 12),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _sectionCard(
          context,
          child: Column(
            children: [
              _box(context, double.infinity, 40),
              const SizedBox(height: AppSpacing.sm),
              _box(context, double.infinity, 40),
              const SizedBox(height: AppSpacing.sm),
              _box(context, double.infinity, 40),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _sectionCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(context, 108, 14),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _box(context, 56, 24, borderRadius: AppRadius.sm),
                  const SizedBox(width: AppSpacing.sm),
                  _box(context, 72, 24, borderRadius: AppRadius.sm),
                  const SizedBox(width: AppSpacing.sm),
                  _box(context, 48, 24, borderRadius: AppRadius.sm),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _sectionCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(context, 96, 14),
              const SizedBox(height: AppSpacing.sm),
              _box(context, double.infinity, 64),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionCard(BuildContext context, {required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: child,
    );
  }

  Widget _box(BuildContext context, double width, double height, {double borderRadius = AppRadius.md}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
