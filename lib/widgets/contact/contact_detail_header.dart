import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/contact.dart';

class ContactDetailHeader extends StatelessWidget {
  final Contact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ContactDetailHeader({
    super.key,
    required this.contact,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final identity = contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                identity,
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontSize: AppFontSize.titleLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (contact.phone != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      contact.phone!,
                      style: TextStyle(color: colorScheme.outline),
                    ),
                  ],
                  if (contact.email != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      contact.email!,
                      style: TextStyle(color: colorScheme.outline),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.end,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('编辑'),
                ),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}