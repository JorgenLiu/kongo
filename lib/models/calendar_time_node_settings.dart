import 'calendar_time_node.dart';

class CalendarTimeNodeSettings {
  final bool contactMilestonesEnabled;
  final bool publicHolidaysEnabled;
  final bool marketingCampaignsEnabled;

  const CalendarTimeNodeSettings({
    this.contactMilestonesEnabled = true,
    this.publicHolidaysEnabled = true,
    this.marketingCampaignsEnabled = true,
  });

  bool isEnabled(CalendarTimeNodeKind kind) {
    switch (kind) {
      case CalendarTimeNodeKind.contactMilestone:
        return contactMilestonesEnabled;
      case CalendarTimeNodeKind.publicHoliday:
        return publicHolidaysEnabled;
      case CalendarTimeNodeKind.marketingCampaign:
        return marketingCampaignsEnabled;
    }
  }

  CalendarTimeNodeSettings copyWith({
    bool? contactMilestonesEnabled,
    bool? publicHolidaysEnabled,
    bool? marketingCampaignsEnabled,
  }) {
    return CalendarTimeNodeSettings(
      contactMilestonesEnabled:
          contactMilestonesEnabled ?? this.contactMilestonesEnabled,
      publicHolidaysEnabled:
          publicHolidaysEnabled ?? this.publicHolidaysEnabled,
      marketingCampaignsEnabled:
          marketingCampaignsEnabled ?? this.marketingCampaignsEnabled,
    );
  }
}