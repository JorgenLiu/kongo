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
    final colorScheme = Theme.of(context).colorScheme;

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
            if (event.startAt != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.schedule_outlined, size: 16, color: colorScheme.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _formatTimeRange(event.startAt!, event.endAt),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ],
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

  String _formatTimeRange(DateTime start, DateTime? end) {
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    String timeFmt(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    if (end == null) return fmt(start);
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return '${fmt(start)} – ${timeFmt(end)}';
    }
    return '${fmt(start)} – ${fmt(end)}';
  }
}