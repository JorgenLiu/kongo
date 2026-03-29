import 'reminder_snooze_action.dart';

enum ReminderInteractionTargetType {
  dailyBrief,
  event,
  eventFollowUp,
  contactMilestone,
  unknown,
}

class ReminderInteraction {
  final ReminderInteractionTargetType targetType;
  final String targetId;
  final String? contactId;
  final ReminderSnoozeAction? snoozeAction;

  const ReminderInteraction({
    required this.targetType,
    required this.targetId,
    this.contactId,
    this.snoozeAction,
  });

  bool get isSnooze => snoozeAction != null;

  bool get opensEventDetail =>
      !isSnooze &&
      (targetType == ReminderInteractionTargetType.event ||
        targetType == ReminderInteractionTargetType.eventFollowUp);

  String get fingerprint =>
      '${targetType.name}|$targetId|${contactId ?? ''}|${snoozeAction?.id ?? ''}';

  static ReminderInteraction? fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return null;
    }

    final rawTargetId = map['targetId'];
    if (rawTargetId is! String || rawTargetId.trim().isEmpty) {
      return null;
    }

    final rawTargetType = map['targetType'] as String?;
    return ReminderInteraction(
      targetType: _parseTargetType(rawTargetType),
      targetId: rawTargetId,
      contactId: map['contactId'] as String?,
      snoozeAction: _parseSnoozeAction(map['actionId'] as String?),
    );
  }

  static ReminderInteractionTargetType _parseTargetType(String? rawTargetType) {
    switch (rawTargetType) {
      case 'dailyBrief':
        return ReminderInteractionTargetType.dailyBrief;
      case 'event':
        return ReminderInteractionTargetType.event;
      case 'eventFollowUp':
        return ReminderInteractionTargetType.eventFollowUp;
      case 'contactMilestone':
        return ReminderInteractionTargetType.contactMilestone;
      default:
        return ReminderInteractionTargetType.unknown;
    }
  }

  static ReminderSnoozeAction? _parseSnoozeAction(String? rawActionId) {
    if (rawActionId == null || rawActionId.isEmpty || rawActionId == 'open') {
      return null;
    }

    for (final action in ReminderSnoozeAction.values) {
      if (action.id == rawActionId) {
        return action;
      }
    }

    return null;
  }
}