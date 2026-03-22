import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/event.dart';

class EventDetailHeader extends StatelessWidget {
  final Event event;
  final String? eventTypeName;
  final int participantCount;
  final int attachmentCount;

  const EventDetailHeader({
    super.key,
    required this.event,
    required this.eventTypeName,
    required this.participantCount,
    required this.attachmentCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (eventTypeName != null)
                  Chip(label: Text(eventTypeName!)),
                Chip(label: Text('参与人 $participantCount')),
                Chip(label: Text('附件 $attachmentCount')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}