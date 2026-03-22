import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/tag.dart';

class ContactFormTagsSection extends StatelessWidget {
  final List<Tag> tags;
  final Set<String> selectedTagIds;
  final bool loading;
  final VoidCallback onManageTagsTap;
  final ValueChanged<String> onTagToggle;

  const ContactFormTagsSection({
    super.key,
    required this.tags,
    required this.selectedTagIds,
    required this.loading,
    required this.onManageTagsTap,
    required this.onTagToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '分组',
                style: TextStyle(
                  fontSize: AppFontSize.titleMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: onManageTagsTap,
              child: const Text('管理分组'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (loading && tags.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (tags.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              '暂无可选分组，请先创建分组。',
              style: TextStyle(color: colorScheme.outline),
            ),
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: tags.map((tag) {
              final selected = selectedTagIds.contains(tag.id);
              return FilterChip(
                label: Text(tag.name),
                selected: selected,
                onSelected: (_) => onTagToggle(tag.id),
              );
            }).toList(),
          ),
      ],
    );
  }
}