import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../providers/events_list_provider.dart';
import '../../services/event_service.dart';
import '../../services/read/event_read_service.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/search_bar.dart' as custom_search;
import '../../widgets/common/workbench_page_header.dart';
import '../../widgets/event/event_search_filter_bar.dart';
import '../../widgets/event/event_search_results_list.dart';
import '../../widgets/event/schedule_grouped_event_list.dart';
import '../../widgets/event/schedule_overview_header.dart';
import '../../widgets/event/schedule_today_timeline.dart';
import 'events_list_actions.dart';

class EventsListScreen extends StatelessWidget {
  final String? contactId;
  final String? contactName;
  final bool showAppBar;

  const EventsListScreen({
    super.key,
    this.contactId,
    this.contactName,
    this.showAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => EventsListProvider(
        context.read<EventReadService>(),
        context.read<EventService>(),
        contactId: contactId,
      ),
      child: _EventsListView(
        contactId: contactId,
        contactName: contactName,
        showAppBar: showAppBar,
      ),
    );
  }
}

class _EventsListView extends StatefulWidget {
  final String? contactId;
  final String? contactName;
  final bool showAppBar;

  const _EventsListView({
    this.contactId,
    this.contactName,
    required this.showAppBar,
  });

  @override
  State<_EventsListView> createState() => _EventsListViewState();
}

class _EventsListViewState extends State<_EventsListView> {
  late DateTime _selectedDate;
  late final TextEditingController _searchController;
  ScheduleCalendarMode _calendarMode = ScheduleCalendarMode.week;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EventsListProvider>();
      if (!provider.initialized && !provider.loading) {
        provider.load();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchEvents(String keyword) {
    context.read<EventsListProvider>().searchByKeyword(keyword);
  }

  Widget _buildBody(BuildContext context, EventsListProvider provider) {
    if (provider.loading && provider.data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.data == null) {
      return _buildErrorState(provider);
    }

    final data = provider.data;
    if (data == null) {
      return const SizedBox.shrink();
    }

    if (provider.keyword.trim().isNotEmpty) {
      if (data.items.isEmpty) {
        return EmptyState(
          icon: Icons.search_off_outlined,
          message: widget.contactId == null ? '未找到匹配的日程' : '该联系人下没有匹配的日程',
        );
      }

      return RefreshIndicator(
        onRefresh: provider.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          children: [
            EventSearchResultsList(
              items: data.items,
              highlightQuery: provider.keyword,
              onItemTap: (item) => _handleOpenScheduleDetail(context, item.event.id, provider),
            ),
          ],
        ),
      );
    }

    if (widget.contactId == null) {
      return RefreshIndicator(
        onRefresh: provider.refresh,
        child: ScheduleTodayTimeline(
          items: data.items,
          referenceDate: _selectedDate,
          onItemTap: (item) => _handleOpenScheduleDetail(context, item.event.id, provider),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        children: [
          if (data.contact != null) ...[
            _buildContextCard(context, data),
            const SizedBox(height: AppSpacing.md),
          ],
          ScheduleGroupedEventList(
            items: data.items,
            selectedDate: null,
            onItemTap: (item) => _handleOpenScheduleDetail(context, item.event.id, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildContextCard(BuildContext context, EventsListReadModel data) {
    final contact = data.contact!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Text(
        '与 ${contact.name} 相关的日程',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildErrorState(EventsListProvider provider) {
    return ErrorState(
      message: provider.error?.message ?? '日程列表加载失败',
      onRetry: provider.load,
    );
  }

  Future<void> _handleOpenScheduleDetail(
    BuildContext context,
    String eventId,
    EventsListProvider provider,
  ) async {
    await openScheduleDetailFromList(context, eventId);

    if (!context.mounted) {
      return;
    }

    await provider.refresh();
  }

  Future<void> _handleCreateSchedule(
    BuildContext context,
    EventsListProvider provider,
  ) async {
    final created = await createScheduleFromList(
      context,
      suggestedContactId: widget.contactId,
    );

    if (!created || !context.mounted) {
      return;
    }

    await provider.refresh();
  }

  Widget _buildTopHeader(BuildContext context, EventsListProvider provider) {
    final isScoped = widget.contactId != null && widget.contactName != null;

    if (!isScoped) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: WorkbenchPageHeader(
          eyebrow: 'Schedule',
          title: '日程',
          titleKey: const Key('eventsPageHeaderTitle'),
          trailing: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.end,
            children: [
              SegmentedButton<ScheduleCalendarMode>(
                key: const Key('scheduleCalendarModeToggle'),
                segments: const [
                  ButtonSegment(
                    value: ScheduleCalendarMode.week,
                    label: Text('本周'),
                    icon: Icon(Icons.view_week_outlined),
                  ),
                  ButtonSegment(
                    value: ScheduleCalendarMode.month,
                    label: Text('本月'),
                    icon: Icon(Icons.calendar_month_outlined),
                  ),
                ],
                selected: <ScheduleCalendarMode>{_calendarMode},
                onSelectionChanged: (selection) {
                  setState(() {
                    _calendarMode = selection.first;
                  });
                },
              ),
              FilledButton.icon(
                onPressed: () => _handleCreateSchedule(context, provider),
                icon: const Icon(Icons.add),
                label: const Text('新建日程'),
              ),
            ],
          ),
          metadata: [
            ScheduleOverviewHeader(
              items: provider.data?.items ?? const [],
              calendarMode: _calendarMode,
              selectedDate: _selectedDate,
              referenceDate: _selectedDate,
              onDateSelected: (value) {
                setState(() {
                  _selectedDate = _resolveSelectedDate(value ?? DateTime.now());
                });
              },
              onItemTap: (item) => _handleOpenScheduleDetail(context, item.event.id, provider),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: WorkbenchPageHeader(
        eyebrow: 'Schedule',
        title: '${widget.contactName} 的日程',
        titleKey: const Key('eventsPageHeaderTitle'),
        trailing: FilledButton.icon(
          onPressed: () => _handleCreateSchedule(context, provider),
          icon: const Icon(Icons.add),
          label: const Text('新建日程'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EventsListProvider>(
      builder: (context, provider, _) => Scaffold(
        appBar: widget.showAppBar
            ? AppBar(
                title: Text(widget.contactName == null ? '日程' : '${widget.contactName} 的日程'),
              )
            : null,
        body: SafeArea(
          child: Column(
            children: [
              if (!widget.showAppBar) _buildTopHeader(context, provider),
              custom_search.SearchBar(
                controller: _searchController,
                hintText: widget.contactId == null ? '搜索日程、地点或备注...' : '搜索该联系人的日程...',
                onChanged: _searchEvents,
                onClear: provider.clearFilters,
              ),
              EventSearchFilterBar(
                eventTypes: provider.eventTypes,
                selectedEventTypeId: provider.selectedEventTypeId,
                onChanged: provider.filterByEventType,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    provider.keyword.trim().isEmpty
                        ? '共 ${provider.data?.items.length ?? 0} 条日程'
                        : '找到 ${provider.data?.items.length ?? 0} 条日程',
                    style: TextStyle(
                      fontSize: AppFontSize.bodySmall,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ),
              Expanded(child: _buildBody(context, provider)),
            ],
          ),
        ),
        floatingActionButton: widget.showAppBar
            ? FloatingActionButton(
                onPressed: () => _handleCreateSchedule(context, provider),
                tooltip: '创建日程',
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _resolveSelectedDate(DateTime value) {
    final now = DateTime.now();
    if (_normalizeDate(value) == _normalizeDate(now)) {
      return now;
    }
    return _normalizeDate(value);
  }
}