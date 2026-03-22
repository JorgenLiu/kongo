import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../models/contact.dart';

class ParticipantList extends StatelessWidget {
  final List<Contact> participants;
  final String emptyText;
  final ValueChanged<Contact>? onTap;

  const ParticipantList({
    super.key,
    required this.participants,
    required this.emptyText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return Text(
        emptyText,
        style: const TextStyle(color: AppColors.outline),
      );
    }

    return Column(
      children: participants
          .map(
            (participant) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(
                  participant.name.isNotEmpty ? participant.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(participant.name),
              subtitle: Text(participant.phone ?? participant.email ?? '无联系方式'),
              trailing: onTap == null ? null : const Icon(Icons.chevron_right),
              onTap: onTap == null ? null : () => onTap!(participant),
            ),
          )
          .toList(),
    );
  }
}