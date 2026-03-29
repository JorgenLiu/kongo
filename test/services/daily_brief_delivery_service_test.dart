import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/models/daily_brief_delivery_status.dart';
import 'package:kongo/models/home_daily_brief.dart';
import 'package:kongo/models/reminder_authorization_status.dart';
import 'package:kongo/repositories/daily_brief_delivery_repository.dart';
import 'package:kongo/services/daily_brief_delivery_service.dart';

void main() {
  late _FakeDailyBriefDeliveryRepository repository;
  late DefaultDailyBriefDeliveryService service;
  late DateTime now;
  late HomeDailyBrief brief;

  setUp(() {
    repository = _FakeDailyBriefDeliveryRepository();
    service = DefaultDailyBriefDeliveryService(repository);
    now = DateTime(2026, 3, 27, 9, 30);
    brief = const HomeDailyBrief(
      status: HomeDailyBriefStatus.ready,
      summary: '今天先准备合作复盘，再清理关键待办。',
      items: [
        HomeDailyBriefItem(
          type: HomeDailyBriefItemType.scheduleFocus,
          title: '先准备合作复盘',
          reason: '上午 10 点有年度合作复盘。',
          primaryAction: HomeDailyBriefActionType.openEvent,
          primaryTargetId: 'event-1',
        ),
      ],
    );
  });

  test('prepareSystemReminder returns request when brief is ready after scheduled time', () async {
    final decision = await service.prepareSystemReminder(
      brief: brief,
      remindersEnabled: true,
      schedule: const DailyBriefReminderSchedule(hour: 9, minute: 0),
      authorizationStatus: ReminderAuthorizationStatus.authorized,
      now: now,
    );

    expect(decision.shouldDeliver, isTrue);
    expect(decision.reason, DailyBriefDeliveryDecisionReason.deliverNow);
    expect(decision.request, isNotNull);
    expect(decision.request!.id, 'kongo.daily_brief.2026-03-27');
    expect(decision.request!.title, DefaultDailyBriefDeliveryService.reminderTitle);
    expect(decision.request!.body, brief.summary);
    expect(decision.request!.payload['entry'], 'home_daily_brief');
    expect(decision.request!.payload['dateKey'], '2026-03-27');
  });

  test('prepareSystemReminder blocks delivery before scheduled time', () async {
    final decision = await service.prepareSystemReminder(
      brief: brief,
      remindersEnabled: true,
      schedule: const DailyBriefReminderSchedule(hour: 10, minute: 0),
      authorizationStatus: ReminderAuthorizationStatus.authorized,
      now: now,
    );

    expect(decision.shouldDeliver, isFalse);
    expect(decision.reason, DailyBriefDeliveryDecisionReason.beforeScheduledTime);
    expect(decision.request, isNull);
  });

  test('prepareSystemReminder blocks delivery when already delivered today', () async {
    repository.statusByKey['system_reminder|2026-03-27'] = DailyBriefDeliveryStatus(
      dateKey: '2026-03-27',
      channel: DailyBriefDeliveryChannel.systemReminder,
      deliveredAt: now.subtract(const Duration(minutes: 10)),
      briefStatus: 'ready',
      summaryHash: 'cached',
    );

    final decision = await service.prepareSystemReminder(
      brief: brief,
      remindersEnabled: true,
      schedule: const DailyBriefReminderSchedule(hour: 9, minute: 0),
      authorizationStatus: ReminderAuthorizationStatus.authorized,
      now: now,
    );

    expect(decision.shouldDeliver, isFalse);
    expect(decision.reason, DailyBriefDeliveryDecisionReason.alreadyDelivered);
  });

  test('prepareSystemReminder blocks delivery when brief is not ready', () async {
    final decision = await service.prepareSystemReminder(
      brief: HomeDailyBrief.empty(summary: '今天节奏平稳'),
      remindersEnabled: true,
      schedule: const DailyBriefReminderSchedule(hour: 9, minute: 0),
      authorizationStatus: ReminderAuthorizationStatus.authorized,
      now: now,
    );

    expect(decision.shouldDeliver, isFalse);
    expect(decision.reason, DailyBriefDeliveryDecisionReason.briefNotReady);
  });

  test('markSystemReminderDelivered persists a daily delivery status', () async {
    await service.markSystemReminderDelivered(
      brief: brief,
      deliveredAt: now,
    );

    final stored = repository.statusByKey['system_reminder|2026-03-27'];
    expect(stored, isNotNull);
    expect(stored!.briefStatus, 'ready');
    expect(stored.summaryHash, isNotEmpty);
  });
}

class _FakeDailyBriefDeliveryRepository implements DailyBriefDeliveryRepository {
  final Map<String, DailyBriefDeliveryStatus> statusByKey =
      <String, DailyBriefDeliveryStatus>{};

  @override
  Future<DailyBriefDeliveryStatus?> getStatus({
    required String dateKey,
    required DailyBriefDeliveryChannel channel,
  }) async {
    return statusByKey['${channel.value}|$dateKey'];
  }

  @override
  Future<void> pruneOldStatuses({
    Duration maxAge = const Duration(days: 45),
    DateTime? now,
  }) async {}

  @override
  Future<void> saveStatus(DailyBriefDeliveryStatus status) async {
    statusByKey['${status.channel.value}|${status.dateKey}'] = status;
  }
}