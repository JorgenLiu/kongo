import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../models/contact.dart';
import '../../models/event.dart';
import '../common/section_card.dart';
import '../event/event_list_item_card.dart';

class ContactDetailEventsSection extends StatelessWidget {
  final Contact contact;
  final List<Event> events;
  final Map<String, String> eventTypeNames;
  final VoidCallback onOpenModule;
  final ValueChanged<String> onOpenEvent;

  const ContactDetailEventsSection({
    super.key,
    required this.contact,
    required this.events,
    required this.eventTypeNames,
    required this.onOpenModule,
    required this.onOpenEvent,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '相关事件',
      trailing: TextButton(
        onPressed: onOpenModule,
        child: const Text('进入模块'),
      ),
      child: events.isEmpty
          ? const Text(
              '该联系人还没有关联事件。',
              style: TextStyle(color: AppColors.outline),
            )
          : Column(
              children: events
                  .map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: EventListItemCard(
                        event: event,
                        eventTypeName: eventTypeNames[event.eventTypeId],
                        onTap: () => onOpenEvent(event.id),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}