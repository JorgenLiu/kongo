import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/tag.dart';
import '../common/section_card.dart';

class ContactDetailTagsSection extends StatelessWidget {
  final List<Tag> tags;

  const ContactDetailTagsSection({
    super.key,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SectionCard(
      title: '分组',
      child: tags.isEmpty
          ? Text(
              '当前联系人还没有分组。',
              style: TextStyle(color: colorScheme.outline),
            )
          : Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: tags
                  .map(
                    (tag) => Chip(
                      label: Text(tag.name),
                      backgroundColor: colorScheme.primaryContainer,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}