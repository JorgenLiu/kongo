import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../providers/calendar_time_node_settings_provider.dart';
import '../../providers/events_list_provider.dart';
import '../../services/event_service.dart';
import '../../services/read/event_read_service.dart';
import '../../utils/input_debouncer.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/skeleton_list.dart';
import '../../widgets/common/search_bar.dart' as custom_search;
import '../../widgets/event/event_search_filter_bar.dart';
import '../../widgets/event/event_search_results_list.dart';
import '../../widgets/event/schedule_grouped_event_list.dart';
import '../../widgets/event/schedule_list_header.dart';
import '../../widgets/event/schedule_overview_header.dart';
import '../../widgets/event/schedule_today_timeline.dart';
import 'events_list_actions.dart';

class EventsListScreen extends StatelessWidget {
  final String? contactId;
  final String? contactName;
  final bool showAppBar;
  final DateTime? initialSelectedDate;

  const EventsListScreen({
    super.key,
    this.contactId,
    this.contactName,
    this.showAppBar = false,
    this.initialSelectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => EventsListProvider(
        context.read<EventReadService>(),
        context.read<EventService>(),
        contactId: contactId,
        calendarTimeNodeSettingsListenable:
            context.read<CalendarTimeNodeSettingsProvider>(),
      ),
      child: _EventsListView(
        contactId: contactId,
        contactName: contactName,
        showAppBar: showAppBar,
        initialSelectedDate: initialSelectedDate,
      ),
    );
  }
}

class _EventsListView extends StatefulWidget {
  final String? contactId;
  final String? contactName;
  final bool showAppBar;
  final DateTime? initialSelectedDate;

  const _EventsListView({
    this.contactId,
    this.contactName,
    required this.showAppBar,
    this.initialSelectedDate,
  });

  @override
  State<_EventsListView> createState() => _EventsListViewState();
}

class _EventsListViewState extends State<_EventsListView> {
  late DateTime _selectedDate;
  late final TextEditingController _searchController;
  late final InputDebouncer _searchDebouncer;
  ScheduleCalendarMode _calendarMode = ScheduleCalendarMode.week;
  bool _showSearchFilter = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = _resolveSelectedDate(widget.initialSelectedDate ?? DateTime.now());
    _searchController = TextEditingController();
    _searchDebouncer = InputDebouncer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EventsListProvider>();
      if (!provider.initialized && !provider.loading) {
        provider.load();
      }
    });
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _searchEvents(String keyword) {
    _searchDebouncer.run(() {
      if (!mounted) {
        return;
      }

      context.read<EventsListProvider>().searchByKeyword(keyword);
    });
  }

  void _clearSearch() {
    _searchDebouncer.cancel();
    context.read<EventsListProvider>().clearFilters();
  }

  Widget _buildBody(BuildContext context, EventsListProvider provider) {
    if (provider.loading && provider.data == null) {
      return const SkeletonList(key: ValueKey('events_skeleton'));
    }

    if (provider.error != null && provider.data == null) {
      return KeyedSubtree(
        key: const ValueKey('events_error'),
        child: _buildErrorState(provider),
      );
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
          onCreateEvent: () => _handleCreateScheduleForDate(context, provider, _selectedDate),
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

  Future<void> _handleCreateScheduleForDate(
    BuildContext context,
    EventsListProvider provider,
    DateTime date,
  ) async {
    final initialStart = DateTime(date.year, date.month, date.day, DateTime.now().hour);
    final created = await createScheduleFromList(
      context,
      suggestedContactId: widget.contactId,
      initialStartAt: initialStart,
    );

    if (!created || !context.mounted) {
      return;
    }

    await provider.refresh();
  }

  Widget _buildTopHeader(BuildContext context, EventsListProvider provider) {
    return ScheduleListHeaderWidget(
      contactName: widget.contactName,
      calendarMode: _calendarMode,
      selectedDate: _selectedDate,
      items: provider.data?.items ?? const [],
      calendarTimeNodes: provider.data?.calendarTimeNodes ?? const [],
      onCalendarModeChanged: (mode) {
        setState(() {
          _calendarMode = mode;
        });
      },
      onWeekNavigate: (date) {
        setState(() {
          _selectedDate = date;
        });
      },
      onDateSelected: (value) {
        setState(() {
          _selectedDate = _resolveSelectedDate(value ?? DateTime.now());
        });
      },
      onCreateSchedule: () => _handleCreateSchedule(context, provider),
      onItemTap: (item) => _handleOpenScheduleDetail(context, item.event.id, provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(widget.contactName == null ? '日程' : '${widget.contactName} 的日程'),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            if (!widget.showAppBar)
              Consumer<EventsListProvider>(
                builder: (context, provider, _) => _buildTopHeader(context, provider),
              ),
            Consumer<EventsListProvider>(
              builder: (context, provider, _) {
                final hasActiveFilter = provider.keyword.trim().isNotEmpty ||
                    provider.selectedEventTypeId != null;
                return Column(
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: (_showSearchFilter || hasActiveFilter)
                          ? Column(
                              children: [
                                custom_search.SearchBar(
                                  controller: _searchController,
                                  hintText: widget.contactId == null
                                      ? '搜索日程、地点或备注...'
                                      : '搜索该联系人的日程...',
                                  onChanged: _searchEvents,
                                  onClear: _clearSearch,
                                ),
                                EventSearchFilterBar(
                                  eventTypes: provider.eventTypes,
                                  selectedEventTypeId:
                                      provider.selectedEventTypeId,
                                  onChanged: provider.filterByEventType,
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Expanded(
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
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 18,
                              icon: Icon(
                                _showSearchFilter
                                    ? Icons.search_off_outlined
                                    : Icons.search_outlined,
                              ),
                              tooltip: _showSearchFilter ? '收起筛选' : '搜索与筛选',
                              onPressed: () {
                                setState(() {
                                  _showSearchFilter = !_showSearchFilter;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            Expanded(
              child: Consumer<EventsListProvider>(
                builder: (context, provider, _) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildBody(context, provider),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.showAppBar
          ? Consumer<EventsListProvider>(
              builder: (context, provider, _) {
                return FloatingActionButton(
                  onPressed: () => _handleCreateSchedule(context, provider),
                  tooltip: '创建日程',
                  child: const Icon(Icons.add),
                );
              },
            )
          : null,
    );
  }

  DateTime _resolveSelectedDate(DateTime value) {
    final now = DateTime.now();
    final normalizedValue = DateTime(value.year, value.month, value.day);
    final normalizedNow = DateTime(now.year, now.month, now.day);
    if (normalizedValue == normalizedNow) {
      return now;
    }
    return normalizedValue;
  }
}