import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../models/event_summary.dart';
import '../../providers/notes_provider.dart';
import '../../services/read/notes_read_service.dart';
import '../../utils/display_formatters.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/notes/capture_session_group.dart';
import '../../widgets/common/workbench_page_header.dart';

class NotesOverviewScreen extends StatefulWidget {
  const NotesOverviewScreen({super.key});

  @override
  State<NotesOverviewScreen> createState() => _NotesOverviewScreenState();
}

class _NotesOverviewScreenState extends State<NotesOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotesProvider>().loadToday();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const _NotesView();
  }
}

class _NotesView extends StatelessWidget {
  const _NotesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              child: Consumer<NotesProvider>(
                builder: (context, provider, _) {
                  final date = provider.initialized
                      ? provider.currentDate
                      : DateTime.now();
                  return WorkbenchPageHeader(
                    eyebrow: 'Notes · ${formatCompactDateLabel(date)}',
                    title: '记录',
                    titleKey: const Key('notesPageHeaderTitle'),
                    trailing: _DateNavigationControls(provider: provider),
                  );
                },
              ),
            ),
            Expanded(
              child: Consumer<NotesProvider>(
                builder: (context, provider, _) {
                  if (provider.loading && provider.data == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.error != null && provider.data == null) {
                    return ErrorState(
                      message: provider.error?.message ?? '加载失败',
                      onRetry: provider.refresh,
                    );
                  }
                  final data = provider.data;
                  if (data == null) {
                    return const SizedBox.shrink();
                  }
                  return _DayNotesBody(model: data);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateNavigationControls extends StatelessWidget {
  final NotesProvider provider;

  const _DateNavigationControls({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isToday = provider.initialized &&
        _isSameDay(provider.currentDate, DateTime.now());

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: '前一天',
          onPressed: provider.initialized
              ? () => provider.navigateToDate(
                    provider.currentDate.subtract(const Duration(days: 1)),
                  )
              : null,
        ),
        TextButton(
          onPressed: isToday ? null : () => provider.loadToday(),
          child: const Text('今天'),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: '后一天',
          onPressed: (!provider.initialized || isToday)
              ? null
              : () => provider.navigateToDate(
                    provider.currentDate.add(const Duration(days: 1)),
                  ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayNotesBody extends StatelessWidget {
  final DayNotesModel model;

  const _DayNotesBody({required this.model});

  @override
  Widget build(BuildContext context) {
    if (model.isEmpty) {
      return const EmptyState(
        icon: Icons.edit_note,
        message: '今日暂无记录',
        subtitle: '通过菜单栏快捷键 ⌃⌘K 快速录入笔记',
      );
    }

    return ListView(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.xl,
      ),
      children: [
        if (model.sessions.isNotEmpty) ...[
          _SectionLabel(label: '笔记', count: _totalNotes(model)),
          const SizedBox(height: AppSpacing.sm),
          ...model.sessions.map(
            (session) => CaptureSessionGroup(
              session: session,
              onDeleteNote: (id) =>
                  context.read<NotesProvider>().deleteNote(id),
              onClearTopics: (id) =>
                  context.read<NotesProvider>().clearNoteTopics(id),
            ),
          ),
        ],
        if (model.summary != null) ...[
          const SizedBox(height: AppSpacing.lg),
          const Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
          const SizedBox(height: AppSpacing.sm),
          const _SectionLabel(label: '每日总结'),
          const SizedBox(height: AppSpacing.sm),
          _DailySummarySection(summary: model.summary!),
        ],
      ],
    );
  }

  int _totalNotes(DayNotesModel model) =>
      model.sessions.fold(0, (acc, s) => acc + s.notes.length);
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final int? count;

  const _SectionLabel({required this.label, this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              '($count)',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DailySummarySection extends StatelessWidget {
  final DailySummary summary;

  const _DailySummarySection({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (summary.todaySummary.isNotEmpty) ...[
                Text(
                  '今日总结',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  summary.todaySummary,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (summary.tomorrowPlan.isNotEmpty) ...[
                if (summary.todaySummary.isNotEmpty)
                  const SizedBox(height: AppSpacing.md),
                Text(
                  '明日计划',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  summary.tomorrowPlan,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
