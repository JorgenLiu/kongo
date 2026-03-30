import 'package:flutter/material.dart';

import '../../config/app_constants.dart';

/// Side Sheet 面板骨架：统一的右侧抽屉标题栏 + 可展开内容区。
///
/// 配合 [SideSheetPageRoute] 使用，提供关闭按钮、标题和操作按钮区域。
class SideSheetScaffold extends StatelessWidget {
  final String title;

  /// 点击关闭按钮时触发（应处理 unsaved changes 逻辑）。
  final VoidCallback onClose;

  /// 标题栏右侧操作区（通常为"保存"按钮）。
  final Widget? action;

  final Widget body;

  const SideSheetScaffold({
    super.key,
    required this.title,
    required this.onClose,
    this.action,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      shadowColor: theme.colorScheme.shadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题栏
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerTheme.color ?? theme.dividerColor,
                  width: theme.dividerTheme.thickness ?? 1,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                  tooltip: '关闭',
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (action != null) action!,
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
          ),
          // 内容区
          Expanded(child: body),
        ],
      ),
    );
  }
}
