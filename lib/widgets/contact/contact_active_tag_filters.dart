import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../models/tag.dart';

class ContactActiveTagFilters extends StatelessWidget {
  final List<Tag> selectedTags;
  final VoidCallback onOpenFilter;
  final VoidCallback onClear;

  const ContactActiveTagFilters({
    super.key,
    required this.selectedTags,
    required this.onOpenFilter,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onOpenFilter,
              tooltip: '调整分组筛选',
              icon: const Icon(Icons.tune, size: 18),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: selectedTags
                      .map(
                        (tag) => Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xs),
                          child: Chip(
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            label: Text(tag.name),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            IconButton(
              onPressed: onClear,
              tooltip: '清空分组筛选',
              icon: const Icon(Icons.close, size: 18),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}