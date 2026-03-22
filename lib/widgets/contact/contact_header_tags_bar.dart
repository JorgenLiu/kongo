import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/tag.dart';

class ContactHeaderTagsBar extends StatelessWidget {
  final List<Tag> tags;
  final List<String> selectedTagIds;
  final bool expanded;
  final ValueChanged<Tag> onTagTap;
  final VoidCallback onToggleExpanded;

  const ContactHeaderTagsBar({
    super.key,
    required this.tags,
    required this.selectedTagIds,
    required this.expanded,
    required this.onTagTap,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final previewCount = expanded ? tags.length : 8;
    final visibleTags = tags.take(previewCount).toList();
    final remainingCount = tags.length - visibleTags.length;

    if (tags.isEmpty) {
      return Chip(
        label: const Text('暂无联系人分组'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          ...visibleTags.map((tag) {
            return ChoiceChip(
              key: Key('contactsHeaderTag_${tag.id}'),
              label: Text(tag.name),
              selected: selectedTagIds.contains(tag.id),
              onSelected: (_) => onTagTap(tag),
            );
          }),
          if (remainingCount > 0)
            ActionChip(
              key: const Key('contactsHeaderTagsExpandButton'),
              label: Text('展开 +$remainingCount'),
              onPressed: onToggleExpanded,
            ),
          if (expanded && tags.length > 8)
            ActionChip(
              key: const Key('contactsHeaderTagsCollapseButton'),
              label: const Text('收起'),
              onPressed: onToggleExpanded,
            ),
        ],
      ),
    );
  }
}