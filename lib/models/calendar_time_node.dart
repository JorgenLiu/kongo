import 'contact.dart';
import 'contact_milestone.dart';

enum CalendarTimeNodeKind {
  contactMilestone,
  publicHoliday,
  marketingCampaign,
}

extension CalendarTimeNodeKindPresentation on CalendarTimeNodeKind {
  String get label {
    switch (this) {
      case CalendarTimeNodeKind.contactMilestone:
        return '联系人重要日期';
      case CalendarTimeNodeKind.publicHoliday:
        return '公共纪念日';
      case CalendarTimeNodeKind.marketingCampaign:
        return '营销节点';
    }
  }

  String get description {
    switch (this) {
      case CalendarTimeNodeKind.contactMilestone:
        return '展示联系人生日、纪念日等已录入的重要日期。';
      case CalendarTimeNodeKind.publicHoliday:
        return '展示内置的公历公共纪念日节点。';
      case CalendarTimeNodeKind.marketingCampaign:
        return '展示内置的营销节奏节点，如 520、618、双 11。';
    }
  }
}

class CalendarTimeNodeReadModel {
  final String id;
  final CalendarTimeNodeKind kind;
  final String title;
  final String? subtitle;
  final String leadingText;
  final DateTime anchorDate;
  final String? linkedContactId;
  final bool isRecurring;
  final bool isLunar;

  const CalendarTimeNodeReadModel({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.leadingText,
    required this.anchorDate,
    required this.linkedContactId,
    required this.isRecurring,
    required this.isLunar,
  });

  factory CalendarTimeNodeReadModel.contactMilestone({
    required Contact contact,
    required ContactMilestone milestone,
  }) {
    return CalendarTimeNodeReadModel(
      id: milestone.id,
      kind: CalendarTimeNodeKind.contactMilestone,
      title: milestone.displayName,
      subtitle: contact.name,
      leadingText: milestone.type.icon,
      anchorDate: milestone.milestoneDate,
      linkedContactId: contact.id,
      isRecurring: milestone.isRecurring,
      isLunar: milestone.isLunar,
    );
  }

  bool occursOn(DateTime date) {
    if (isLunar) {
      return false;
    }

    if (isRecurring) {
      return anchorDate.month == date.month && anchorDate.day == date.day;
    }

    return anchorDate.year == date.year &&
        anchorDate.month == date.month &&
        anchorDate.day == date.day;
  }
}