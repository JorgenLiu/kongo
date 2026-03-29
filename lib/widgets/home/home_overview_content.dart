import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../services/read/home_read_service.dart';
import 'home_stat_row.dart';
import 'home_week_plan_section.dart';
import 'pending_actions_section.dart';
import 'quick_actions_bar.dart';
import 'today_schedule_section.dart';
import 'upcoming_milestones_section.dart';

class HomeOverviewContent extends StatelessWidget {
  final HomeReadModel data;
  final VoidCallback onCreateContact;
  final VoidCallback onCreateEvent;
  final VoidCallback onCreateTodayEvent;
  final VoidCallback onOpenEvents;
  final VoidCallback onOpenContacts;
  final VoidCallback onOpenTodos;
  final ValueChanged<DateTime> onOpenEventsByDate;
  final ValueChanged<String> onOpenEventDetail;
  final VoidCallback onOpenSummaries;
  final VoidCallback onOpenNotes;
  final ValueChanged<String> onOpenContactDetail;

  const HomeOverviewContent({
    super.key,
    required this.data,
    required this.onCreateContact,
    required this.onCreateEvent,
    required this.onCreateTodayEvent,
    required this.onOpenEvents,
    required this.onOpenContacts,
    required this.onOpenTodos,
    required this.onOpenEventsByDate,
    required this.onOpenEventDetail,
    required this.onOpenSummaries,
    required this.onOpenNotes,
    required this.onOpenContactDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('home_content'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSupportEntryBar(context),
        const SizedBox(height: AppSpacing.lg),
        // 周历全宽：横向日期列越多，导航感越强
        HomeWeekPlanSection(
          items: data.weekEvents,
          calendarTimeNodes: data.weekCalendarTimeNodes,
          onViewAll: onOpenEvents,
          onDateTap: onOpenEventsByDate,
          onEventTap: onOpenEventDetail,
        ),
        const SizedBox(height: AppSpacing.lg),
        // 下方三联操作面板：今日日程 | 待办事项 | 近期里程碑
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= AppBreakpoints.compact;

            if (isWide) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: TodayScheduleSection(
                        events: data.todayEvents,
                        onViewAll: onOpenEvents,
                        onCreateTodayEvent: onCreateTodayEvent,
                        onEventTap: onOpenEventDetail,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: PendingActionsSection(
                        actions: data.pendingActions,
                        onViewSummaries: onOpenSummaries,
                        onViewTodos: onOpenTodos,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: UpcomingMilestonesSection(
                        milestones: data.upcomingMilestones,
                        onContactTap: onOpenContactDetail,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                TodayScheduleSection(
                  events: data.todayEvents,
                  onViewAll: onOpenEvents,
                  onCreateTodayEvent: onCreateTodayEvent,
                  onEventTap: onOpenEventDetail,
                ),
                const SizedBox(height: AppSpacing.lg),
                PendingActionsSection(
                  actions: data.pendingActions,
                  onViewSummaries: onOpenSummaries,
                  onViewTodos: onOpenTodos,
                ),
                const SizedBox(height: AppSpacing.lg),
                UpcomingMilestonesSection(
                  milestones: data.upcomingMilestones,
                  onContactTap: onOpenContactDetail,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSupportEntryBar(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= AppBreakpoints.standard;
        final stats = HomeStatRow(
          contactCount: data.totalContacts,
          weekEventCount: data.weekEvents.length,
          pendingActionCount: data.pendingActions.length,
          onContactsTap: onOpenContacts,
          onWeekEventsTap: onOpenEvents,
          onPendingActionsTap: onOpenTodos,
        );
        final actions = QuickActionsBar(
          onCreateContact: onCreateContact,
          onCreateEvent: onCreateEvent,
        );
        final notesEntry = _NotesQuickEntry(
          todayNotesCount: data.todayNotesCount,
          onTap: onOpenNotes,
        );

        if (wide) {
          return Row(
            key: const Key('homeSupportEntryBarWide'),
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: stats),
              const SizedBox(width: AppSpacing.sm),
              notesEntry,
              const SizedBox(width: AppSpacing.sm),
              actions,
            ],
          );
        }

        return Column(
          key: const Key('homeSupportEntryBarCompact'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            stats,
            const SizedBox(height: AppSpacing.sm),
            notesEntry,
            const SizedBox(height: AppSpacing.sm),
            actions,
          ],
        );
      },
    );
  }
}

class _NotesQuickEntry extends StatelessWidget {
  final int todayNotesCount;
  final VoidCallback onTap;

  const _NotesQuickEntry({required this.todayNotesCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final label = todayNotesCount > 0 ? '今日已记 $todayNotesCount 条' : '今日记录';

    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.edit_note, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        textStyle: theme.textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
    );
  }
}