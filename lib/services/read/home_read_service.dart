import '../../models/action_item.dart';
import '../../models/calendar_time_node.dart';
import '../../models/contact.dart';
import '../../models/contact_milestone.dart';
import '../../models/contact_upcoming_milestone.dart';
import '../../models/event.dart';
import '../../repositories/contact_repository.dart';
import '../contact_milestone_service.dart';
import '../summary_service.dart';
import 'event_read_service.dart';

abstract class HomeReadService {
  Future<HomeReadModel> loadWorkbench();
}

class DefaultHomeReadService implements HomeReadService {
  final EventReadService _eventReadService;
  final ContactRepository _contactRepository;
  final ContactMilestoneService _milestoneService;
  final SummaryService _summaryService;

  DefaultHomeReadService(
    this._eventReadService,
    this._contactRepository,
    this._milestoneService,
    this._summaryService,
  );

  @override
  Future<HomeReadModel> loadWorkbench() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final weekStart = todayStart.subtract(Duration(days: now.weekday - DateTime.monday));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final eventsList = await _eventReadService.getEventsList();
    final allItems = eventsList.items;

    final todayEvents = allItems
      .where((item) =>
        item.event.startAt != null &&
        !item.event.startAt!.isBefore(todayStart) &&
        item.event.startAt!.isBefore(todayEnd))
        .toList()
      ..sort((a, b) => a.event.startAt!.compareTo(b.event.startAt!));

    final weekEvents = allItems
      .where((item) =>
        item.event.startAt != null &&
        !item.event.startAt!.isBefore(weekStart) &&
        item.event.startAt!.isBefore(weekEnd))
      .toList(growable: false);

    // Upcoming milestones (30 days)
    final rawMilestones = await _milestoneService.getUpcomingMilestones();
    final milestoneContactIds =
        rawMilestones.map((m) => m.contactId).toSet().toList();
    final contacts = <String, Contact>{};
    for (final id in milestoneContactIds) {
      try {
        contacts[id] = await _contactRepository.getById(id);
      } catch (_) {
        // contact may have been deleted
      }
    }

    final upcomingMilestones = rawMilestones
        .where((m) => contacts.containsKey(m.contactId))
        .map((m) => _buildUpcomingMilestone(m, contacts[m.contactId]!, now))
        .whereType<ContactUpcomingMilestone>()
        .toList()
      ..sort((a, b) {
        final dayDiff = a.daysUntil.compareTo(b.daysUntil);
        return dayDiff != 0 ? dayDiff : a.contact.name.compareTo(b.contact.name);
      });

    // Today's summary → pending action items
    final todaySummary = await _summaryService.getSummaryByDate(todayStart);
    List<ActionItem> pendingActions = const [];
    if (todaySummary != null) {
      pendingActions =
          await _summaryService.extractActionItemsFromSummary(todaySummary.id);
    }

    // Contact count
    final allContacts = await _contactRepository.getAll();
    final totalContacts = allContacts.length;

    return HomeReadModel(
      todayEvents: todayEvents
          .map(
            (item) => TodayEventItem(
              event: item.event,
              eventTypeName: item.eventTypeName,
              participantNames: item.participantNames,
            ),
          )
          .toList(growable: false),
      weekEvents: weekEvents,
      weekCalendarTimeNodes: eventsList.calendarTimeNodes,
      pendingActions: pendingActions,
      upcomingMilestones: upcomingMilestones,
      totalEvents: allItems.length,
      totalContacts: totalContacts,
      todayEventCount: todayEvents.length,
    );
  }

  ContactUpcomingMilestone? _buildUpcomingMilestone(
    ContactMilestone milestone,
    Contact contact,
    DateTime now,
  ) {
    final nextOccurrence =
        ContactUpcomingMilestone.resolveNextOccurrence(milestone, now);
    if (nextOccurrence == null) return null;
    final today = DateTime(now.year, now.month, now.day);
    return ContactUpcomingMilestone(
      contact: contact,
      milestone: milestone,
      nextOccurrence: nextOccurrence,
      daysUntil: nextOccurrence.difference(today).inDays,
    );
  }
}

class HomeReadModel {
  final List<TodayEventItem> todayEvents;
  final List<EventListItemReadModel> weekEvents;
  final List<CalendarTimeNodeReadModel> weekCalendarTimeNodes;
  final List<ActionItem> pendingActions;
  final List<ContactUpcomingMilestone> upcomingMilestones;
  final int totalEvents;
  final int totalContacts;
  final int todayEventCount;

  const HomeReadModel({
    required this.todayEvents,
    required this.weekEvents,
    this.weekCalendarTimeNodes = const [],
    required this.pendingActions,
    required this.upcomingMilestones,
    required this.totalEvents,
    required this.totalContacts,
    required this.todayEventCount,
  });
}

class TodayEventItem {
  final Event event;
  final String? eventTypeName;
  final List<String> participantNames;

  const TodayEventItem({
    required this.event,
    required this.eventTypeName,
    required this.participantNames,
  });
}
