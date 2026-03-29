import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/ai/ai_service.dart';
import 'package:kongo/exceptions/app_exception.dart';
import 'package:kongo/models/action_item.dart';
import 'package:kongo/models/ai_job.dart';
import 'package:kongo/models/ai_output.dart';
import 'package:kongo/models/contact.dart';
import 'package:kongo/models/contact_milestone.dart';
import 'package:kongo/models/contact_upcoming_milestone.dart';
import 'package:kongo/models/event.dart';
import 'package:kongo/models/home_daily_brief.dart';
import 'package:kongo/services/home_daily_brief_service.dart';
import 'package:kongo/services/read/event_read_service.dart';
import 'package:kongo/services/read/home_read_service.dart';

void main() {
  late _FakeAiService aiService;
  late DefaultHomeDailyBriefService service;
  late DateTime now;
  late HomeReadModel homeData;

  setUp(() {
    aiService = _FakeAiService();
    service = DefaultHomeDailyBriefService(aiService);
    now = DateTime(2026, 3, 27, 9, 30);
    homeData = _buildHomeReadModel(now);
  });

  test('returns cached brief without calling AI when daily cache exists', () async {
    aiService.jobHistoryByTarget['home_daily_brief|2026-03-27'] = [
      _job(id: 'job-cache', createdAt: now.subtract(const Duration(minutes: 5))),
    ];
    aiService.outputsByJobId['job-cache'] = [
      _output(
        id: 'output-cache',
        aiJobId: 'job-cache',
        createdAt: now.subtract(const Duration(minutes: 5)),
        content: jsonEncode({
          'summary': '缓存简报',
          'items': [
            {
              'type': 'follow_up',
              'title': '优先跟进张三',
              'reason': '今天有合作复盘会议。',
              'primaryAction': 'open_contact',
              'primaryTargetId': 'contact-1',
            },
          ],
        }),
      ),
    ];

    final brief = await service.getDailyBrief(homeData: homeData, now: now);

    expect(brief.status, HomeDailyBriefStatus.ready);
    expect(brief.summary, '缓存简报');
    expect(brief.items, hasLength(1));
    expect(brief.fromCache, isTrue);
    expect(aiService.executeCallCount, 0);
  });

  test('returns unavailable state when AI is not available and cache is absent', () async {
    aiService.available = false;

    final brief = await service.getDailyBrief(homeData: homeData, now: now);

    expect(brief.status, HomeDailyBriefStatus.unavailable);
    expect(brief.summary, contains('配置 AI 后可获得今日秘书简报'));
    expect(aiService.executeCallCount, 0);
  });

  test('getCachedDailyBrief returns cached brief for the requested date', () async {
    aiService.jobHistoryByTarget['home_daily_brief|2026-03-27'] = [
      _job(id: 'job-cache', createdAt: now.subtract(const Duration(minutes: 5))),
    ];
    aiService.outputsByJobId['job-cache'] = [
      _output(
        id: 'output-cache',
        aiJobId: 'job-cache',
        createdAt: now.subtract(const Duration(minutes: 5)),
        content: jsonEncode({
          'summary': '缓存读取',
          'items': [
            {
              'type': 'follow_up',
              'title': '先联系张三',
              'reason': '今天需要确认会前材料。',
              'primaryAction': 'open_contact',
              'primaryTargetId': 'contact-1',
            },
          ],
        }),
      ),
    ];

    final brief = await service.getCachedDailyBrief(date: now);

    expect(brief, isNotNull);
    expect(brief!.summary, '缓存读取');
    expect(brief.fromCache, isTrue);
    expect(aiService.executeCallCount, 0);
  });

  test('force refresh bypasses cache and executes AI request', () async {
    aiService.jobHistoryByTarget['home_daily_brief|2026-03-27'] = [
      _job(id: 'job-cache', createdAt: now.subtract(const Duration(minutes: 5))),
    ];
    aiService.outputsByJobId['job-cache'] = [
      _output(
        id: 'output-cache',
        aiJobId: 'job-cache',
        createdAt: now.subtract(const Duration(minutes: 5)),
        content: jsonEncode({'summary': '旧简报', 'items': []}),
      ),
    ];
    aiService.nextResult = AiResult(
      job: _job(id: 'job-fresh', createdAt: now),
      output: _output(
        id: 'output-fresh',
        aiJobId: 'job-fresh',
        createdAt: now,
        content: jsonEncode({
          'summary': '新的今日简报',
          'items': [
            {
              'type': 'pending_action',
              'title': '先处理待办',
              'reason': '今天上午会议前有一项待处理。',
              'primaryAction': 'open_todos',
            },
          ],
        }),
      ),
    );

    final brief = await service.getDailyBrief(
      homeData: homeData,
      now: now,
      forceRefresh: true,
    );

    expect(brief.summary, '新的今日简报');
    expect(brief.fromCache, isFalse);
    expect(aiService.executeCallCount, 1);
  });

  test('builds AI request with structured home context', () async {
    aiService.nextResult = AiResult(
      job: _job(id: 'job-1', createdAt: now),
      output: _output(
        id: 'output-1',
        aiJobId: 'job-1',
        createdAt: now,
        content: jsonEncode({
          'summary': '今天请先准备合作复盘',
          'items': [
            {
              'type': 'schedule_focus',
              'title': '先准备合作复盘',
              'reason': '上午 10 点有年度合作复盘。',
              'primaryAction': 'open_event',
              'primaryTargetId': 'event-1',
            },
          ],
        }),
      ),
    );

    await service.getDailyBrief(homeData: homeData, now: now);

    expect(aiService.lastRequest, isNotNull);
    expect(aiService.lastRequest!.feature, DefaultHomeDailyBriefService.featureName);
    expect(aiService.lastRequest!.targetType, DefaultHomeDailyBriefService.targetType);
    expect(aiService.lastRequest!.targetId, '2026-03-27');
    expect(aiService.lastRequest!.outputType, DefaultHomeDailyBriefService.outputType);
    expect(aiService.lastRequest!.messages, hasLength(2));
    final userPayload = jsonDecode(aiService.lastRequest!.messages.last.content) as Map<String, dynamic>;
    expect(userPayload['todayEvents'], isNotEmpty);
    expect((userPayload['todayEvents'] as List).first['title'], '年度合作复盘');
    expect((userPayload['pendingActions'] as List).first['title'], '整理会议纪要');
    expect((userPayload['upcomingMilestones'] as List).first['contactName'], '李四');
  });

  test('returns failed state when AI returns invalid json', () async {
    aiService.nextResult = AiResult(
      job: _job(id: 'job-invalid', createdAt: now),
      output: _output(
        id: 'output-invalid',
        aiJobId: 'job-invalid',
        createdAt: now,
        content: '{not-valid-json}',
      ),
    );

    final brief = await service.getDailyBrief(homeData: homeData, now: now);

    expect(brief.status, HomeDailyBriefStatus.failed);
    expect(brief.errorMessage, contains('解析失败'));
  });

  test('returns failed state when AI returns unsupported action', () async {
    aiService.nextResult = AiResult(
      job: _job(id: 'job-invalid', createdAt: now),
      output: _output(
        id: 'output-invalid',
        aiJobId: 'job-invalid',
        createdAt: now,
        content: jsonEncode({
          'summary': '今天有建议',
          'items': [
            {
              'type': 'follow_up',
              'title': '优先跟进张三',
              'reason': '有共同会议。',
              'primaryAction': 'delete_everything',
            },
          ],
        }),
      ),
    );

    final brief = await service.getDailyBrief(homeData: homeData, now: now);

    expect(brief.status, HomeDailyBriefStatus.failed);
    expect(brief.errorMessage, contains('解析失败'));
  });

  test('returns failed state when AI execution throws', () async {
    aiService.executeError = const AiException(
      message: 'provider unavailable',
      code: 'ai_request_failed',
    );

    final brief = await service.getDailyBrief(homeData: homeData, now: now);

    expect(brief.status, HomeDailyBriefStatus.failed);
    expect(brief.errorMessage, contains('provider unavailable'));
  });
}

HomeReadModel _buildHomeReadModel(DateTime now) {
  final createdAt = now.subtract(const Duration(days: 10));
  final todayEvent = Event(
    id: 'event-1',
    title: '年度合作复盘',
    startAt: DateTime(now.year, now.month, now.day, 10),
    createdAt: createdAt,
    updatedAt: createdAt,
  );
  final weekEvent = Event(
    id: 'event-2',
    title: '产品演示预约',
    startAt: now.add(const Duration(days: 2)),
    createdAt: createdAt,
    updatedAt: createdAt,
  );
  final contact = Contact(
    id: 'contact-2',
    name: '李四',
    createdAt: createdAt,
    updatedAt: createdAt,
  );
  final milestone = ContactMilestone(
    id: 'milestone-1',
    contactId: contact.id,
    type: ContactMilestoneType.birthday,
    milestoneDate: DateTime(2020, now.month, now.day + 2),
    createdAt: createdAt,
    updatedAt: createdAt,
  );

  return HomeReadModel(
    todayEvents: [
      TodayEventItem(
        event: todayEvent,
        eventTypeName: '会议',
        participantNames: const ['张三', '李四'],
      ),
    ],
    weekEvents: [
      EventListItemReadModel(
        event: todayEvent,
        eventTypeName: '会议',
        participantNames: const ['张三', '李四'],
      ),
      EventListItemReadModel(
        event: weekEvent,
        eventTypeName: '演示',
        participantNames: const ['王五'],
      ),
    ],
    pendingActions: const [
      ActionItem(title: '整理会议纪要'),
      ActionItem(title: '确认报价邮件', completed: true),
    ],
    upcomingMilestones: [
      ContactUpcomingMilestone(
        contact: contact,
        milestone: milestone,
        nextOccurrence: DateTime(now.year, now.month, now.day + 2),
        daysUntil: 2,
      ),
    ],
    totalEvents: 2,
    totalContacts: 10,
    todayEventCount: 1,
  );
}

AiJob _job({required String id, required DateTime createdAt}) {
  return AiJob(
    id: id,
    feature: DefaultHomeDailyBriefService.featureName,
    provider: 'mock',
    targetType: DefaultHomeDailyBriefService.targetType,
    targetId: '2026-03-27',
    status: AiJobStatus.completed,
    createdAt: createdAt,
    completedAt: createdAt,
  );
}

AiOutput _output({
  required String id,
  required String aiJobId,
  required DateTime createdAt,
  required String content,
}) {
  return AiOutput(
    id: id,
    aiJobId: aiJobId,
    outputType: DefaultHomeDailyBriefService.outputType,
    content: content,
    createdAt: createdAt,
  );
}

class _FakeAiService implements AiService {
  bool available = true;
  int executeCallCount = 0;
  AiRequest? lastRequest;
  AiResult? nextResult;
  Exception? executeError;
  final Map<String, List<AiJob>> jobHistoryByTarget = {};
  final Map<String, List<AiOutput>> outputsByJobId = {};

  @override
  bool get isAvailable => available;

  @override
  Future<AiResult> execute(AiRequest request) async {
    executeCallCount += 1;
    lastRequest = request;
    if (executeError != null) {
      throw executeError!;
    }
    return nextResult!;
  }

  @override
  Future<List<AiJob>> getJobHistory(String targetType, String targetId) async {
    return jobHistoryByTarget['$targetType|$targetId'] ?? const [];
  }

  @override
  Future<List<AiOutput>> getJobOutputs(String aiJobId) async {
    return outputsByJobId[aiJobId] ?? const [];
  }
}