import '../../models/calendar_time_node.dart';

List<CalendarTimeNodeReadModel> buildPublicHolidayCalendarNodes() {
  return _publicHolidayDefinitions
      .map(
        (definition) => CalendarTimeNodeReadModel(
          id: 'public-holiday-${definition.month}-${definition.day}',
          kind: CalendarTimeNodeKind.publicHoliday,
          title: definition.title,
          subtitle: '公共纪念日',
          leadingText: definition.leadingText,
          anchorDate: DateTime(2026, definition.month, definition.day),
          linkedContactId: null,
          isRecurring: true,
          isLunar: false,
        ),
      )
      .toList(growable: false);
}

List<CalendarTimeNodeReadModel> buildMarketingCampaignCalendarNodes() {
  return _marketingCampaignDefinitions
      .map(
        (definition) => CalendarTimeNodeReadModel(
          id: 'marketing-campaign-${definition.month}-${definition.day}',
          kind: CalendarTimeNodeKind.marketingCampaign,
          title: definition.title,
          subtitle: '营销节点',
          leadingText: definition.leadingText,
          anchorDate: DateTime(2026, definition.month, definition.day),
          linkedContactId: null,
          isRecurring: true,
          isLunar: false,
        ),
      )
      .toList(growable: false);
}

class _PublicHolidayDefinition {
  final int month;
  final int day;
  final String title;
  final String leadingText;

  const _PublicHolidayDefinition({
    required this.month,
    required this.day,
    required this.title,
    required this.leadingText,
  });
}

const List<_PublicHolidayDefinition> _publicHolidayDefinitions = [
  _PublicHolidayDefinition(month: 1, day: 1, title: '元旦', leadingText: '🗓️'),
  _PublicHolidayDefinition(month: 3, day: 8, title: '妇女节', leadingText: '🌷'),
  _PublicHolidayDefinition(month: 5, day: 1, title: '劳动节', leadingText: '🛠️'),
  _PublicHolidayDefinition(month: 6, day: 1, title: '儿童节', leadingText: '🎈'),
  _PublicHolidayDefinition(month: 9, day: 10, title: '教师节', leadingText: '📚'),
  _PublicHolidayDefinition(month: 10, day: 1, title: '国庆节', leadingText: '🎉'),
];

const List<_PublicHolidayDefinition> _marketingCampaignDefinitions = [
  _PublicHolidayDefinition(month: 2, day: 14, title: '情人节档期', leadingText: '💘'),
  _PublicHolidayDefinition(month: 5, day: 20, title: '520 营销节点', leadingText: '💝'),
  _PublicHolidayDefinition(month: 6, day: 18, title: '618 大促', leadingText: '🛍️'),
  _PublicHolidayDefinition(month: 9, day: 9, title: '开学季', leadingText: '🎒'),
  _PublicHolidayDefinition(month: 11, day: 11, title: '双 11', leadingText: '🔥'),
  _PublicHolidayDefinition(month: 12, day: 12, title: '双 12', leadingText: '🎁'),
];