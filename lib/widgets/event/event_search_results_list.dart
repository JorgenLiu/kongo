import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../services/read/event_read_service.dart';
import 'event_list_item_card.dart';

class EventSearchResultsList extends StatelessWidget {
  final List<EventListItemReadModel> items;
  final String? highlightQuery;
  final ValueChanged<EventListItemReadModel> onItemTap;

  const EventSearchResultsList({
    super.key,
    required this.items,
    this.highlightQuery,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: EventListItemCard(
                event: item.event,
                eventTypeName: item.eventTypeName,
                participantNames: item.participantNames,
                highlightQuery: highlightQuery,
                onTap: () => onItemTap(item),
              ),
            ),
          )
          .toList(),
    );
  }
}