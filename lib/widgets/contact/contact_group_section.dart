import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/contact.dart';
import 'contact_card.dart';

class ContactGroupSection extends StatelessWidget {
  final String label;
  final List<Contact> contacts;
  final Key? headerKey;
  final ValueChanged<Contact> onTap;
  final ValueChanged<Contact> onEdit;
  final ValueChanged<Contact> onDelete;

  const ContactGroupSection({
    super.key,
    required this.label,
    required this.contacts,
    this.headerKey,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: headerKey,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                    ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${contacts.length} 位',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...contacts.map(
          (contact) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ContactCard(
              contact: contact,
              onTap: () => onTap(contact),
              onEdit: () => onEdit(contact),
              onDelete: () => onDelete(contact),
            ),
          ),
        ),
      ],
    );
  }
}