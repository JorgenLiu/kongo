import 'package:flutter/material.dart';

import '../../config/app_constants.dart';

class HomeOverviewScreen extends StatelessWidget {
  final VoidCallback onOpenContacts;
  final VoidCallback onOpenEvents;
  final VoidCallback onOpenTags;
  final VoidCallback onOpenSettings;

  const HomeOverviewScreen({
    super.key,
    required this.onOpenContacts,
    required this.onOpenEvents,
    required this.onOpenTags,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('主页')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            '当前建议优先查看附件闭环、导航入口和搜索状态。',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          _ModuleCard(
            title: '通讯录',
            description: '查看联系人、分组过滤、详情聚合。',
            actionLabel: '进入通讯录',
            onTap: onOpenContacts,
          ),
          const SizedBox(height: AppSpacing.md),
          _ModuleCard(
            title: '事件',
            description: '查看事件列表、事件详情、总结和附件。',
            actionLabel: '进入事件',
            onTap: onOpenEvents,
          ),
          const SizedBox(height: AppSpacing.md),
          _ModuleCard(
            title: '分组',
            description: '进入分组管理，检查分组和筛选状态。',
            actionLabel: '进入分组',
            onTap: onOpenTags,
          ),
          const SizedBox(height: AppSpacing.md),
          _ModuleCard(
            title: '设置',
            description: '查看当前版本、阶段和后续工作方向。',
            actionLabel: '进入设置',
            onTap: onOpenSettings,
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
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
            Text(description),
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonal(
              onPressed: onTap,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}