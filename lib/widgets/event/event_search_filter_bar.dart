import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/event_type.dart';

class EventSearchFilterBar extends StatelessWidget {
  final List<EventType> eventTypes;
  final String? selectedEventTypeId;
  final ValueChanged<String?> onChanged;

  const EventSearchFilterBar({
    super.key,
    required this.eventTypes,
    required this.selectedEventTypeId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        0,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('全部类型'),
                selected: selectedEventTypeId == null,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onSelected: (_) => onChanged(null),
              ),
              for (final eventType in eventTypes) ...[
                const SizedBox(width: AppSpacing.sm),
                ChoiceChip(
                  avatar: eventType.color != null
                      ? CircleAvatar(
                          radius: 6,
                          backgroundColor: _parseColor(eventType.color!),
                        )
                      : null,
                  label: Text(eventType.name),
                  selected: selectedEventTypeId == eventType.id,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onSelected: (_) => onChanged(
                    selectedEventTypeId == eventType.id ? null : eventType.id,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Color _parseColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    return Color(int.parse(cleaned, radix: 16));
  }
}