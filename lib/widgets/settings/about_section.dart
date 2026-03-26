import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../config/app_constants.dart';

/// 关于分区 — 版本与平台信息。
class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '关于',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _AboutRow(label: '应用名称', value: 'Kongo'),
            const Divider(height: 1),
            _AboutRow(label: '版本', value: '0.1.0'),
            const Divider(height: 1),
            _AboutRow(label: '运行平台', value: _platformLabel()),
            const Divider(height: 1),
            _AboutRow(label: '框架', value: 'Flutter'),
          ],
        ),
      ),
    );
  }

  static String _platformLabel() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.fuchsia:
        return 'Fuchsia';
    }
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;

  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodyMedium),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
