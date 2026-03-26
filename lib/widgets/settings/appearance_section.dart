import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../providers/theme_notifier.dart';

/// 外观设置分区 — 主题模式切换。
class AppearanceSection extends StatelessWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeNotifier = context.watch<ThemeNotifier>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette_outlined, size: 20, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '外观',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text('主题模式', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_outlined, size: 18),
                  label: Text('跟随系统'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined, size: 18),
                  label: Text('亮色'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined, size: 18),
                  label: Text('暗色'),
                ),
              ],
                selected: {themeNotifier.mode},
                onSelectionChanged: (selection) async {
                  try {
                    await themeNotifier.setMode(selection.first);
                  } catch (_) {
                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('主题设置保存失败，请稍后重试')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
