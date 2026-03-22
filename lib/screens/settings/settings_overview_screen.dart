import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../widgets/common/workbench_page_header.dart';
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
            const SizedBox(height: AppSpacing.md),
            const _SettingsInfoCard(
              title: '当前阶段',
              body: '当前产品结构已经调整为事件主驱动，通讯录与文件作为辅助入口，分组管理收纳为次级工具。',
            ),
            const SizedBox(height: AppSpacing.md),
            _SettingsActionCard(
              title: '分组管理',
              body: '集中维护分组命名和筛选维度，不再单独占用底部导航。',
              actionLabel: '打开分组管理',
              onPressed: () => openTagManagementFromSettings(context),
            ),
            const SizedBox(height: AppSpacing.md),
            const _SettingsInfoCard(
              title: '当前验证平台',
              body: 'macOS 作为当前主要验证平台，便于你直接检查桌面 UI 和文件附件体验。',
            ),
            const SizedBox(height: AppSpacing.md),
            const _SettingsInfoCard(
              title: '下一步重点',
              body: '下一轮重点会落在更完整搜索、联系人详情模块深化，以及文件体验继续细化。',
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsInfoCard extends StatelessWidget {
  final String title;
  final String body;

  const _SettingsInfoCard({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(body),
          ],
        ),
      ),
    );
  }
}

class _SettingsActionCard extends StatelessWidget {
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onPressed;

  const _SettingsActionCard({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(body),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: onPressed,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}