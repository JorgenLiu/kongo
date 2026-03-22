import 'package:flutter/material.dart';

import '../../config/app_constants.dart';

class ContactDetailQuickEntryRow extends StatelessWidget {
  final int eventCount;
  final int attachmentCount;
  final VoidCallback onEventsTap;
  final VoidCallback onAttachmentsTap;

  const ContactDetailQuickEntryRow({
    super.key,
    required this.eventCount,
    required this.attachmentCount,
    required this.onEventsTap,
    required this.onAttachmentsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ContactDetailEntryCard(
            key: const Key('contactDetail_eventsEntry'),
            title: '相关事件',
            count: eventCount,
            icon: Icons.event_note_outlined,
            onTap: onEventsTap,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ContactDetailEntryCard(
            key: const Key('contactDetail_attachmentsEntry'),
            title: '相关附件',
            count: attachmentCount,
            icon: Icons.attach_file_outlined,
            onTap: onAttachmentsTap,
          ),
        ),
      ],
    );
  }
}

class _ContactDetailEntryCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final VoidCallback onTap;

  const _ContactDetailEntryCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Ink(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: AppFontSize.titleMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: AppFontSize.titleLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}