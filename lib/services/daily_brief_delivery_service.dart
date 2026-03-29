import '../models/daily_brief_delivery_status.dart';
import '../models/home_daily_brief.dart';
import '../models/reminder_authorization_status.dart';
import '../models/reminder_request.dart';
import '../repositories/daily_brief_delivery_repository.dart';
import '../utils/display_formatters.dart';

enum DailyBriefDeliveryDecisionReason {
  deliverNow,
  briefNotReady,
  summaryMissing,
  beforeScheduledTime,
  alreadyDelivered,
  remindersDisabled,
  unauthorized,
}

class DailyBriefReminderSchedule {
  final int hour;
  final int minute;

  const DailyBriefReminderSchedule({
    required this.hour,
    required this.minute,
  }) : assert(hour >= 0 && hour <= 23),
       assert(minute >= 0 && minute <= 59);
}

class DailyBriefDeliveryDecision {
  final bool shouldDeliver;
  final DailyBriefDeliveryDecisionReason reason;
  final String dateKey;
  final ReminderRequest? request;

  const DailyBriefDeliveryDecision({
    required this.shouldDeliver,
    required this.reason,
    required this.dateKey,
    this.request,
  });
}

abstract class DailyBriefDeliveryService {
  Future<DailyBriefDeliveryDecision> prepareSystemReminder({
    required HomeDailyBrief brief,
    required bool remindersEnabled,
    required DailyBriefReminderSchedule schedule,
    required ReminderAuthorizationStatus authorizationStatus,
    DateTime? now,
  });

  Future<void> markSystemReminderDelivered({
    required HomeDailyBrief brief,
    DateTime? deliveredAt,
  });
}

class DefaultDailyBriefDeliveryService implements DailyBriefDeliveryService {
  static const String reminderTitle = '今日 AI 简报';
  static const String reminderIdPrefix = 'kongo.daily_brief.';

  final DailyBriefDeliveryRepository _repository;

  DefaultDailyBriefDeliveryService(this._repository);

  @override
  Future<DailyBriefDeliveryDecision> prepareSystemReminder({
    required HomeDailyBrief brief,
    required bool remindersEnabled,
    required DailyBriefReminderSchedule schedule,
    required ReminderAuthorizationStatus authorizationStatus,
    DateTime? now,
  }) async {
    final resolvedNow = now ?? DateTime.now();
    final dateKey = formatIsoDate(resolvedNow);

    if (!remindersEnabled) {
      return DailyBriefDeliveryDecision(
        shouldDeliver: false,
        reason: DailyBriefDeliveryDecisionReason.remindersDisabled,
        dateKey: dateKey,
      );
    }

    if (!authorizationStatus.allowsScheduling) {
      return DailyBriefDeliveryDecision(
        shouldDeliver: false,
        reason: DailyBriefDeliveryDecisionReason.unauthorized,
        dateKey: dateKey,
      );
    }

    if (brief.status != HomeDailyBriefStatus.ready) {
      return DailyBriefDeliveryDecision(
        shouldDeliver: false,
        reason: DailyBriefDeliveryDecisionReason.briefNotReady,
        dateKey: dateKey,
      );
    }

    final summary = brief.summary?.trim();
    if (summary == null || summary.isEmpty) {
      return DailyBriefDeliveryDecision(
        shouldDeliver: false,
        reason: DailyBriefDeliveryDecisionReason.summaryMissing,
        dateKey: dateKey,
      );
    }

    final scheduledAt = DateTime(
      resolvedNow.year,
      resolvedNow.month,
      resolvedNow.day,
      schedule.hour,
      schedule.minute,
    );
    if (resolvedNow.isBefore(scheduledAt)) {
      return DailyBriefDeliveryDecision(
        shouldDeliver: false,
        reason: DailyBriefDeliveryDecisionReason.beforeScheduledTime,
        dateKey: dateKey,
      );
    }

    final existingStatus = await _repository.getStatus(
      dateKey: dateKey,
      channel: DailyBriefDeliveryChannel.systemReminder,
    );
    if (existingStatus != null) {
      return DailyBriefDeliveryDecision(
        shouldDeliver: false,
        reason: DailyBriefDeliveryDecisionReason.alreadyDelivered,
        dateKey: dateKey,
      );
    }

    return DailyBriefDeliveryDecision(
      shouldDeliver: true,
      reason: DailyBriefDeliveryDecisionReason.deliverNow,
      dateKey: dateKey,
      request: ReminderRequest(
        id: '$reminderIdPrefix$dateKey',
        title: reminderTitle,
        body: summary,
        fireAt: resolvedNow,
        payload: {
          'entry': 'home_daily_brief',
          'targetType': 'dailyBrief',
          'targetId': dateKey,
          'dateKey': dateKey,
        },
      ),
    );
  }

  @override
  Future<void> markSystemReminderDelivered({
    required HomeDailyBrief brief,
    DateTime? deliveredAt,
  }) async {
    final resolvedDeliveredAt = deliveredAt ?? DateTime.now();
    final summary = brief.summary?.trim();
    if (brief.status != HomeDailyBriefStatus.ready || summary == null || summary.isEmpty) {
      return;
    }

    await _repository.saveStatus(
      DailyBriefDeliveryStatus(
        dateKey: formatIsoDate(resolvedDeliveredAt),
        channel: DailyBriefDeliveryChannel.systemReminder,
        deliveredAt: resolvedDeliveredAt,
        briefStatus: brief.status.name,
        summaryHash: _summaryHash(summary),
      ),
    );
  }

  String _summaryHash(String summary) {
    var hash = 2166136261;
    for (final codeUnit in summary.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return hash.toUnsigned(32).toRadixString(16);
  }
}