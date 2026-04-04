import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/tag.dart';

class ContactFormTagsSection extends StatefulWidget {
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
  State<ContactFormTagsSection> createState() => _ContactFormTagsSectionState();
}

class _ContactFormTagsSectionState extends State<ContactFormTagsSection> {
  bool _expanded = false;
  static const int _collapseAt = 8;

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
              onPressed: widget.onManageTagsTap,
              child: const Text('管理分组'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (widget.loading && widget.tags.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (widget.tags.isEmpty)
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
            children: [
              ...(_expanded ? widget.tags : widget.tags.take(_collapseAt)).map((tag) {
                final selected = widget.selectedTagIds.contains(tag.id);
                return FilterChip(
                  label: Text(tag.name),
                  selected: selected,
                  onSelected: (_) => widget.onTagToggle(tag.id),
                );
              }),
              if (!_expanded && widget.tags.length > _collapseAt)
                ActionChip(
                  label: Text('+${widget.tags.length - _collapseAt}'),
                  onPressed: () => setState(() => _expanded = true),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
      ],
    );
  }
}