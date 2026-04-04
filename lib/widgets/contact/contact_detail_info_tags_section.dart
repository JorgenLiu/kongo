import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../common/section_card.dart';

class ContactDetailInfoTagsSection extends StatelessWidget {
  final List<String> infoTags;

  const ContactDetailInfoTagsSection({
    super.key,
    required this.infoTags,
  });

  @override
  Widget build(BuildContext context) {
    if (infoTags.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return SectionCard(
      icon: Icons.local_offer_outlined,
      title: '信息标签',
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: infoTags
            .map(
              (tag) => Chip(
                label: Text(tag),
                backgroundColor:
                    colorScheme.tertiary.withValues(alpha: 0.12),
                side: BorderSide.none,
                labelStyle: TextStyle(
                  color: colorScheme.tertiary,
                  fontWeight: FontWeight.w600,
                  fontSize: AppFontSize.bodySmall,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
