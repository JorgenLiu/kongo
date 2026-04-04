import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../models/calendar_time_node.dart';

class CalendarTimeNodeVisualStyle {
  final Color backgroundColor;
  final Color foregroundColor;

  const CalendarTimeNodeVisualStyle({
    required this.backgroundColor,
    required this.foregroundColor,
  });
}

String buildCalendarTimeNodePrimaryLabel(CalendarTimeNodeReadModel node) {
  return switch (node.kind) {
    CalendarTimeNodeKind.contactMilestone =>
      node.subtitle != null && node.subtitle!.trim().isNotEmpty
          ? '${node.leadingText} ${node.subtitle!} · ${node.title}'
          : '${node.leadingText} ${node.title}',
    CalendarTimeNodeKind.publicHoliday || CalendarTimeNodeKind.marketingCampaign =>
      '${node.leadingText} ${node.title}',
  };
}

String buildCalendarTimeNodeTooltip(CalendarTimeNodeReadModel node) {
  return switch (node.kind) {
    CalendarTimeNodeKind.contactMilestone =>
      node.subtitle != null && node.subtitle!.trim().isNotEmpty
          ? '${node.leadingText} ${node.subtitle!} · ${node.title}'
          : '${node.leadingText} ${node.title}',
    CalendarTimeNodeKind.publicHoliday || CalendarTimeNodeKind.marketingCampaign =>
      '${node.leadingText} ${node.title}（${node.kind.label}）',
  };
}

String buildCalendarTimeNodeBadgeLabel(List<CalendarTimeNodeReadModel> nodes) {
  if (nodes.isEmpty) {
    return '';
  }

  final leadingText = nodes.first.leadingText;
  return nodes.length > 1 ? '$leadingText+${nodes.length}' : leadingText;
}

String buildCalendarTimeNodeBadgeTooltip(List<CalendarTimeNodeReadModel> nodes) {
  if (nodes.isEmpty) {
    return '';
  }

  return nodes.map(buildCalendarTimeNodeTooltip).join('\n');
}

CalendarTimeNodeVisualStyle resolveCalendarTimeNodeVisualStyle(
  BuildContext context,
  CalendarTimeNodeKind kind,
) {
  final colorScheme = Theme.of(context).colorScheme;

  return switch (kind) {
    CalendarTimeNodeKind.contactMilestone => CalendarTimeNodeVisualStyle(
      backgroundColor: colorScheme.tertiary,
      foregroundColor: colorScheme.onTertiary,
    ),
    CalendarTimeNodeKind.publicHoliday => CalendarTimeNodeVisualStyle(
      backgroundColor: AppColors.warning,
      foregroundColor: Colors.white,
    ),
    CalendarTimeNodeKind.marketingCampaign => CalendarTimeNodeVisualStyle(
      backgroundColor: colorScheme.secondary,
      foregroundColor: colorScheme.onSecondary,
    ),
  };
}