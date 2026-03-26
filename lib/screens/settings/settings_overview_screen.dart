import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../widgets/common/workbench_page_header.dart';
import '../../widgets/settings/about_section.dart';
import '../../widgets/settings/appearance_section.dart';
import '../../widgets/settings/calendar_time_node_section.dart';
import '../../widgets/settings/data_section.dart';
import 'settings_overview_actions.dart';

class SettingsOverviewScreen extends StatelessWidget {
  const SettingsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const WorkbenchPageHeader(
              eyebrow: 'Settings',
              title: '设置',
              titleKey: Key('settingsPageHeaderTitle'),
            ),
            const SizedBox(height: AppSpacing.lg),
            // ── 偏好设置 ──
            _SectionHeader(icon: Icons.tune_outlined, label: '偏好设置'),
            const SizedBox(height: AppSpacing.sm),
            const AppearanceSection(),
            const SizedBox(height: AppSpacing.md),
            const CalendarTimeNodeSection(),
            const SizedBox(height: AppSpacing.xl),
            // ── 数据管理 ──
            _SectionHeader(icon: Icons.folder_outlined, label: '数据管理'),
            const SizedBox(height: AppSpacing.sm),
            DataSection(
              onOpenTagManagement: () => openTagManagementFromSettings(context),
            ),
            const SizedBox(height: AppSpacing.xl),
            // ── 关于 ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: const AboutSection(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.outline),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.outline,
                  letterSpacing: 0.8,
                ),
          ),
        ],
      ),
    );
  }
}