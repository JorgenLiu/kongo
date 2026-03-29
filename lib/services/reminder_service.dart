import '../models/contact_milestone.dart';
import '../models/event.dart';
import '../models/reminder_authorization_status.dart';
import '../models/reminder_interaction.dart';
import '../models/reminder_request.dart';
import '../models/reminder_settings.dart';
import '../repositories/contact_milestone_repository.dart';
import '../repositories/contact_repository.dart';
import '../repositories/event_repository.dart';
import '../utils/display_formatters.dart';
import '../utils/reminder_default_time_resolver.dart';
import 'reminder_platform_gateway.dart';
import 'settings_preferences_store.dart';

abstract class ReminderService {
  Future<ReminderAuthorizationStatus> getAuthorizationStatus();
  Future<ReminderAuthorizationStatus> requestAuthorization();
  Future<ReminderSettings> getSettings();
  Future<ReminderSettings> updateSettings(ReminderSettings settings);
  Future<void> scheduleDailyBriefReminder(ReminderRequest request);
  Future<void> syncEventReminder(Event event);
  Future<void> removeEventReminder(String eventId);
  Future<void> syncMilestoneReminder(ContactMilestone milestone);
  Future<void> removeMilestoneReminder(String milestoneId);
  Future<void> snoozeReminder(ReminderInteraction interaction);
  Future<void> rebuildPendingReminders({int eventDays = 30, int milestoneDays = 30});
}

class DefaultReminderService implements ReminderService {
  static const String _eventPrefix = 'kongo.event.';
  static const String _eventFollowUpPrefix = 'kongo.event_follow_up.';
  static const String _eventSnoozePrefix = 'kongo.event_snooze.';
  static const String _eventFollowUpSnoozePrefix = 'kongo.event_follow_up_snooze.';
  static const String _milestonePrefix = 'kongo.milestone.';

  final ReminderPlatformGateway _platformGateway;
  final SettingsPreferencesStore _settingsPreferencesStore;
  final EventRepository _eventRepository;
  final ContactMilestoneRepository _contactMilestoneRepository;
  final ContactRepository _contactRepository;
  final DateTime Function() _nowProvider;

  DefaultReminderService(
    this._platformGateway,
    this._settingsPreferencesStore,
    this._eventRepository,
    this._contactMilestoneRepository,
    this._contactRepository, {
    DateTime Function()? nowProvider,
  }) : _nowProvider = nowProvider ?? DateTime.now;

  @override
  Future<ReminderAuthorizationStatus> getAuthorizationStatus() {
    return _platformGateway.getAuthorizationStatus();
  }

  @override
  Future<ReminderAuthorizationStatus> requestAuthorization() async {
    final status = await _platformGateway.requestAuthorization();
    if (status.allowsScheduling) {
      await rebuildPendingReminders();
    }
    return status;
  }

  @override
  Future<ReminderSettings> getSettings() {
    return _settingsPreferencesStore.getReminderSettings();
  }

  @override
  Future<ReminderSettings> updateSettings(ReminderSettings settings) async {
    await _settingsPreferencesStore.setReminderSettings(settings);
    if (!settings.remindersEnabled) {
      await _platformGateway.cancelAll();
      return settings;
    }

    await rebuildPendingReminders();
    return settings;
  }

  @override
  Future<void> scheduleDailyBriefReminder(ReminderRequest request) async {
    final settings = await getSettings();
    if (!settings.remindersEnabled || !settings.dailyBriefReminderEnabled) {
      return;
    }

    final authorizationStatus = await getAuthorizationStatus();
    if (!authorizationStatus.allowsScheduling) {
      return;
    }

    await _platformGateway.schedule(request);
  }

  @override
  Future<void> syncEventReminder(Event event) async {
    final settings = await getSettings();
    if (!settings.remindersEnabled) {
      await _platformGateway.cancel(eventReminderId(event.id));
      await _platformGateway.cancel(eventFollowUpReminderId(event.id));
      await _platformGateway.cancel(eventSnoozeReminderId(event.id));
      await _platformGateway.cancel(eventFollowUpSnoozeReminderId(event.id));
      return;
    }

    final authorizationStatus = await getAuthorizationStatus();
    if (!authorizationStatus.allowsScheduling) {
      return;
    }

    final eventRequest = settings.eventRemindersEnabled ? _buildEventReminderRequest(event) : null;
    if (eventRequest == null) {
      await _platformGateway.cancel(eventReminderId(event.id));
    } else {
      await _platformGateway.schedule(eventRequest);
    }
    await _platformGateway.cancel(eventSnoozeReminderId(event.id));

    final followUpRequest = settings.postEventFollowUpEnabled
        ? _buildEventFollowUpReminderRequest(event)
        : null;
    if (followUpRequest == null) {
      await _platformGateway.cancel(eventFollowUpReminderId(event.id));
    } else {
      await _platformGateway.schedule(followUpRequest);
    }
    await _platformGateway.cancel(eventFollowUpSnoozeReminderId(event.id));
  }

  @override
  Future<void> removeEventReminder(String eventId) async {
    await _platformGateway.cancel(eventReminderId(eventId));
    await _platformGateway.cancel(eventFollowUpReminderId(eventId));
    await _platformGateway.cancel(eventSnoozeReminderId(eventId));
    await _platformGateway.cancel(eventFollowUpSnoozeReminderId(eventId));
  }

  @override
  Future<void> syncMilestoneReminder(ContactMilestone milestone) async {
    final reminderId = milestoneReminderId(milestone.id);
    final settings = await getSettings();
    if (!settings.remindersEnabled || !settings.milestoneRemindersEnabled) {
      await _platformGateway.cancel(reminderId);
      return;
    }

    final authorizationStatus = await getAuthorizationStatus();
    if (!authorizationStatus.allowsScheduling) {
      return;
    }

    final contact = await _contactRepository.getById(milestone.contactId);
    final request = _buildMilestoneReminderRequest(
      milestone,
      contactName: contact.name,
    );
    if (request == null) {
      await _platformGateway.cancel(reminderId);
      return;
    }

    await _platformGateway.schedule(request);
  }

  @override
  Future<void> removeMilestoneReminder(String milestoneId) {
    return _platformGateway.cancel(milestoneReminderId(milestoneId));
  }

  @override
  Future<void> snoozeReminder(ReminderInteraction interaction) async {
    final action = interaction.snoozeAction;
    if (action == null) {
      return;
    }

    final settings = await getSettings();
    if (!settings.remindersEnabled) {
      return;
    }

    final authorizationStatus = await getAuthorizationStatus();
    if (!authorizationStatus.allowsScheduling) {
      return;
    }

    final fireAt = resolveSnoozeReminderAt(
      now: _nowProvider(),
      action: action,
    );
    if (fireAt == null) {
      return;
    }

    switch (interaction.targetType) {
      case ReminderInteractionTargetType.dailyBrief:
        return;
      case ReminderInteractionTargetType.event:
        if (!settings.eventRemindersEnabled) {
          return;
        }
        final event = await _eventRepository.getById(interaction.targetId);
        await _platformGateway.schedule(
          _buildEventSnoozedReminderRequest(event, fireAt: fireAt),
        );
        return;
      case ReminderInteractionTargetType.eventFollowUp:
        if (!settings.postEventFollowUpEnabled) {
          return;
        }
        final event = await _eventRepository.getById(interaction.targetId);
        await _platformGateway.schedule(
          _buildEventFollowUpSnoozedReminderRequest(event, fireAt: fireAt),
        );
        return;
      case ReminderInteractionTargetType.contactMilestone:
      case ReminderInteractionTargetType.unknown:
        return;
    }
  }

  @override
  Future<void> rebuildPendingReminders({int eventDays = 30, int milestoneDays = 30}) async {
    await _platformGateway.cancelAll();

    final settings = await getSettings();
    if (!settings.remindersEnabled) {
      return;
    }

    final authorizationStatus = await getAuthorizationStatus();
    if (!authorizationStatus.allowsScheduling) {
      return;
    }

    if (settings.eventRemindersEnabled) {
      final events = await _eventRepository.getUpcomingEvents(days: eventDays);
      for (final event in events) {
        final request = _buildEventReminderRequest(event);
        if (request != null) {
          await _platformGateway.schedule(request);
        }

        final followUpRequest = settings.postEventFollowUpEnabled
            ? _buildEventFollowUpReminderRequest(event)
            : null;
        if (followUpRequest != null) {
          await _platformGateway.schedule(followUpRequest);
        }
      }
    } else if (settings.postEventFollowUpEnabled) {
      final events = await _eventRepository.getUpcomingEvents(days: eventDays);
      for (final event in events) {
        final followUpRequest = _buildEventFollowUpReminderRequest(event);
        if (followUpRequest != null) {
          await _platformGateway.schedule(followUpRequest);
        }
      }
    }

    if (settings.milestoneRemindersEnabled) {
      final milestones = await _contactMilestoneRepository.getUpcoming(days: milestoneDays);
      for (final milestone in milestones) {
        final contact = await _contactRepository.getById(milestone.contactId);
        final request = _buildMilestoneReminderRequest(
          milestone,
          contactName: contact.name,
        );
        if (request != null) {
          await _platformGateway.schedule(request);
        }
      }
    }
  }

  String eventReminderId(String eventId) => '$_eventPrefix$eventId';

  String eventFollowUpReminderId(String eventId) => '$_eventFollowUpPrefix$eventId';

  String eventSnoozeReminderId(String eventId) => '$_eventSnoozePrefix$eventId';

  String eventFollowUpSnoozeReminderId(String eventId) =>
      '$_eventFollowUpSnoozePrefix$eventId';

  String milestoneReminderId(String milestoneId) => '$_milestonePrefix$milestoneId';

  ReminderRequest? _buildEventReminderRequest(Event event) {
    final reminderAt = event.reminderAt;
    if (!event.reminderEnabled || reminderAt == null || !reminderAt.isAfter(_nowProvider())) {
      return null;
    }

    final bodyParts = <String>[];
    if (event.startAt != null) {
      bodyParts.add('开始时间：${formatDateTimeLabel(event.startAt!)}');
    }
    if (event.location != null && event.location!.trim().isNotEmpty) {
      bodyParts.add('地点：${event.location!.trim()}');
    }

    return ReminderRequest(
      id: eventReminderId(event.id),
      title: '即将开始：${event.title}',
      body: bodyParts.isEmpty ? '你有一个即将到来的事件需要关注。' : bodyParts.join(' · '),
      fireAt: reminderAt,
      payload: {
        'targetType': 'event',
        'targetId': event.id,
      },
    );
  }

  ReminderRequest? _buildEventFollowUpReminderRequest(Event event) {
    final anchorTime = event.endAt ?? event.startAt;
    if (anchorTime == null) {
      return null;
    }

    final fireAt = anchorTime.add(const Duration(minutes: 5));
    if (!fireAt.isAfter(_nowProvider())) {
      return null;
    }

    return ReminderRequest(
      id: eventFollowUpReminderId(event.id),
      title: '会后补充：${event.title}',
      body: '记下一句话，补充这次沟通的决定、承诺或后续动作。',
      fireAt: fireAt,
      payload: {
        'targetType': 'eventFollowUp',
        'targetId': event.id,
      },
    );
  }

  ReminderRequest _buildEventSnoozedReminderRequest(
    Event event, {
    required DateTime fireAt,
  }) {
    final bodyParts = <String>[];
    if (event.startAt != null) {
      bodyParts.add('开始时间：${formatDateTimeLabel(event.startAt!)}');
    }
    if (event.location != null && event.location!.trim().isNotEmpty) {
      bodyParts.add('地点：${event.location!.trim()}');
    }

    return ReminderRequest(
      id: eventSnoozeReminderId(event.id),
      title: '稍后提醒：${event.title}',
      body: bodyParts.isEmpty ? '继续处理这条事件提醒。' : bodyParts.join(' · '),
      fireAt: fireAt,
      payload: {
        'targetType': 'event',
        'targetId': event.id,
      },
    );
  }

  ReminderRequest _buildEventFollowUpSnoozedReminderRequest(
    Event event, {
    required DateTime fireAt,
  }) {
    return ReminderRequest(
      id: eventFollowUpSnoozeReminderId(event.id),
      title: '稍后补充：${event.title}',
      body: '把这次沟通的决定、承诺或后续动作补充进事件记录。',
      fireAt: fireAt,
      payload: {
        'targetType': 'eventFollowUp',
        'targetId': event.id,
      },
    );
  }

  ReminderRequest? _buildMilestoneReminderRequest(
    ContactMilestone milestone, {
    required String contactName,
  }) {
    if (!milestone.reminderEnabled || milestone.isLunar) {
      return null;
    }

    final occurrence = _resolveNextMilestoneOccurrence(milestone);
    if (occurrence == null) {
      return null;
    }

    final fireAt = DateTime(
      occurrence.year,
      occurrence.month,
      occurrence.day,
      9,
    ).subtract(Duration(days: milestone.reminderDaysBefore));

    if (!fireAt.isAfter(_nowProvider())) {
      return null;
    }

    return ReminderRequest(
      id: milestoneReminderId(milestone.id),
      title: '$contactName · ${milestone.displayName}',
      body: '${milestone.displayName}日期：${formatChineseDateLabel(occurrence)}',
      fireAt: fireAt,
      payload: {
        'targetType': 'contactMilestone',
        'targetId': milestone.id,
        'contactId': milestone.contactId,
      },
    );
  }

  DateTime? _resolveNextMilestoneOccurrence(ContactMilestone milestone) {
    final now = _nowProvider();
    final today = DateTime(now.year, now.month, now.day);

    if (!milestone.isRecurring) {
      final oneTimeDate = DateTime(
        milestone.milestoneDate.year,
        milestone.milestoneDate.month,
        milestone.milestoneDate.day,
      );
      if (oneTimeDate.isBefore(today)) {
        return null;
      }
      return oneTimeDate;
    }

    final thisYear = DateTime(
      today.year,
      milestone.milestoneDate.month,
      milestone.milestoneDate.day,
    );
    if (!thisYear.isBefore(today)) {
      return thisYear;
    }

    return DateTime(
      today.year + 1,
      milestone.milestoneDate.month,
      milestone.milestoneDate.day,
    );
  }
}