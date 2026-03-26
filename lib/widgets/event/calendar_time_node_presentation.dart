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
  final brightness = Theme.of(context).brightness;

  return switch (kind) {
    CalendarTimeNodeKind.contactMilestone => CalendarTimeNodeVisualStyle(
      backgroundColor: brightness == Brightness.light
          ? const Color(0xFFE9DBC5)
          : const Color(0xFF3E3123),
      foregroundColor: brightness == Brightness.light
          ? AppColors.tertiary
          : const Color(0xFFF2E8DA),
    ),
    CalendarTimeNodeKind.publicHoliday => CalendarTimeNodeVisualStyle(
      backgroundColor: brightness == Brightness.light
          ? const Color(0xFFF1E5BF)
          : const Color(0xFF48391E),
      foregroundColor: brightness == Brightness.light
          ? const Color(0xFF6D5313)
          : const Color(0xFFF3E4BF),
    ),
    CalendarTimeNodeKind.marketingCampaign => CalendarTimeNodeVisualStyle(
      backgroundColor: brightness == Brightness.light
          ? const Color(0xFFF0D5A7)
          : const Color(0xFF4A3218),
      foregroundColor: brightness == Brightness.light
          ? const Color(0xFF714410)
          : const Color(0xFFF8E0B6),
    ),
  };
}