import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../providers/contact_provider.dart';
import '../../providers/tag_provider.dart';

/// 数据统计分区 — 展示联系人/分组数量。
class DataSection extends StatelessWidget {
  final VoidCallback? onOpenTagManagement;

  const DataSection({super.key, this.onOpenTagManagement});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final contactCount = context.select<ContactProvider, int>(
      (p) => p.contacts.length,
    );
    final tagCount = context.select<TagProvider, int>(
      (p) => p.tags.length,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage_outlined, size: 20, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '数据',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _DataRow(label: '联系人', value: '$contactCount 位'),
            const Divider(height: 1),
            _DataRow(label: '分组标签', value: '$tagCount 个'),
            if (onOpenTagManagement != null) ...[
              const Divider(height: AppSpacing.lg),
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                onTap: onOpenTagManagement,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Icon(Icons.label_outlined, size: 18, color: colorScheme.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text('分组管理', style: textTheme.bodyMedium),
                      ),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: colorScheme.outline),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;

  const _DataRow({required this.label, required this.value});

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
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
