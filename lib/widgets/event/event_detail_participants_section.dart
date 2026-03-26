import 'package:flutter/material.dart';

import '../../services/read/event_read_service.dart';
import '../../utils/event_participant_roles.dart';
import '../common/section_card.dart';

class EventDetailParticipantsSection extends StatelessWidget {
  final List<EventParticipantDetailReadModel> participants;
  final ValueChanged<EventParticipantDetailReadModel> onOpenContact;

  const EventDetailParticipantsSection({
    super.key,
    required this.participants,
    required this.onOpenContact,
  });

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<EventParticipantDetailReadModel>>{};
    for (final participant in participants) {
      groups.putIfAbsent(participant.role, () => <EventParticipantDetailReadModel>[]).add(participant);
    }

    final orderedRoles = groups.keys.toList()
      ..sort((left, right) => EventParticipantRoles.sortIndexOf(left).compareTo(EventParticipantRoles.sortIndexOf(right)));

    return SectionCard(
      icon: Icons.people_outlined,
      title: '参与人',
      child: participants.isEmpty
          ? Text(
              '当前没有参与人信息。',
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: orderedRoles.map((role) {
                final group = groups[role] ?? const <EventParticipantDetailReadModel>[];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        EventParticipantRoles.labelOf(role),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...group.map(
                        (participant) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ParticipantRow(
                            participant: participant,
                            onTap: () => onOpenContact(participant),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  final EventParticipantDetailReadModel participant;
  final VoidCallback onTap;

  const _ParticipantRow({
    required this.participant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final contact = participant.contact;
    final identity = contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
          color: colorScheme.surfaceContainerLow,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              child: Text(identity),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact.phone ?? contact.email ?? '无联系方式',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}