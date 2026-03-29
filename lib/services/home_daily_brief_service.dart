import 'dart:convert';

import '../ai/ai_provider.dart';
import '../ai/ai_service.dart';
import '../exceptions/app_exception.dart';
import '../models/action_item.dart';
import '../models/contact_upcoming_milestone.dart';
import '../models/home_daily_brief.dart';
import '../utils/display_formatters.dart';
import 'read/event_read_service.dart';
import 'read/home_read_service.dart';

abstract class HomeDailyBriefService {
  Future<HomeDailyBrief?> getCachedDailyBrief({DateTime? date});

  Future<HomeDailyBrief> getDailyBrief({
    required HomeReadModel homeData,
    DateTime? now,
    bool forceRefresh = false,
  });
}

class DefaultHomeDailyBriefService implements HomeDailyBriefService {
  static const featureName = 'home_daily_brief';
  static const targetType = 'home_daily_brief';
  static const outputType = 'daily_brief_json';
  final AiService _aiService;

  DefaultHomeDailyBriefService(this._aiService);

  @override
  Future<HomeDailyBrief?> getCachedDailyBrief({DateTime? date}) {
    final resolvedDate = date ?? DateTime.now();
    return _loadCachedBrief(formatIsoDate(resolvedDate));
  }

  @override
  Future<HomeDailyBrief> getDailyBrief({
    required HomeReadModel homeData,
    DateTime? now,
    bool forceRefresh = false,
  }) async {
    final resolvedNow = now ?? DateTime.now();
    final dateKey = formatIsoDate(resolvedNow);

    if (!forceRefresh) {
      final cached = await _loadCachedBrief(dateKey);
      if (cached != null) {
        return cached;
      }
    }

    if (!_aiService.isAvailable) {
      return HomeDailyBrief.unavailable(
        summary: '配置 AI 后可获得今日秘书简报。',
      );
    }

    final input = _HomeDailyBriefInput.fromHomeData(
      homeData: homeData,
      now: resolvedNow,
    );

    try {
      final result = await _aiService.execute(
        AiRequest(
          feature: featureName,
          targetType: targetType,
          targetId: dateKey,
          outputType: outputType,
          messages: _buildMessages(input),
        ),
      );

      final brief = _parseBrief(
        result.output.content,
        generatedAt: result.output.createdAt,
        aiJobId: result.job.id,
        fromCache: false,
      );

      return brief;
    } on AiException catch (error) {
      return HomeDailyBrief.failed('今日简报生成失败：${error.message}');
    } on FormatException catch (error) {
      return HomeDailyBrief.failed('今日简报解析失败：${error.message}');
    } on Exception catch (error) {
      return HomeDailyBrief.failed('今日简报生成失败：$error');
    }
  }

  Future<HomeDailyBrief?> _loadCachedBrief(String dateKey) async {
    try {
      final jobs = await _aiService.getJobHistory(targetType, dateKey);
      for (final job in jobs) {
        final outputs = await _aiService.getJobOutputs(job.id);
        for (final output in outputs.reversed) {
          if (output.outputType != outputType) {
            continue;
          }

          try {
            return _parseBrief(
              output.content,
              generatedAt: output.createdAt,
              aiJobId: job.id,
              fromCache: true,
            );
          } on FormatException {
            continue;
          }
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  HomeDailyBrief _parseBrief(
    String rawContent, {
    required DateTime generatedAt,
    required String aiJobId,
    required bool fromCache,
  }) {
    final brief = HomeDailyBrief.fromJsonString(
      rawContent,
      generatedAt: generatedAt,
      aiJobId: aiJobId,
      fromCache: fromCache,
    );

    if (brief.status == HomeDailyBriefStatus.empty) {
      return HomeDailyBrief.empty(
        summary: brief.summary ?? '今天没有明显风险或待跟进项。',
        generatedAt: generatedAt,
        aiJobId: aiJobId,
        fromCache: fromCache,
      );
    }

    return brief;
  }

  List<AiMessage> _buildMessages(_HomeDailyBriefInput input) {
    return [
      const AiMessage.system(
        '你是一个个人关系管理（CRM）产品中的 AI 秘书，专注于帮用户维护人脉关系质量。\n'
        '你的任务不是复述日历内容，而是发现只有结合多维数据才能看到的关系机会。\n\n'
        '## 分析优先级（严格按顺序）\n\n'
        '**优先级 1 — crossReferences（选取最高价值的 1-2 个）**\n'
        '输入数据的 crossReferences 字段由系统预先计算，列出了"今天参会 + 近期里程碑"同时成立的联系人。\n'
        '这是最高价值信号：今天的会议是主动行动的时间窗口，里程碑是背景原因。\n'
        '优先级判断：优先选 contactTags 标有"VIP 客户"、"合作伙伴"、"重点跟进"等重要关系标签的联系人；'
        '里程碑越近（daysUntil 越小）优先级越高。不要对所有 crossReference 都输出推荐，只选最值得行动的 1-2 个。\n'
        '正确做法：把会议作为主体，里程碑作为理由，根据会议 description 提供具体的对话切入点，行动建议避免重复同一句式。\n'
        '错误做法：输出"准备生日祝福"这类孤立的里程碑提醒，或对每个联系人都套用相同模板"今天是好时机，否则只能发消息"。\n\n'
        '**优先级 2 — 今日会议的特殊场景**\n'
        '只在以下情况值得推荐：①初次见面的新联系人（关系建立机会）；\n'
        '②会议参与者有关联的待跟进事项（会前准备价值）。否则不推荐。\n\n'
        '**优先级 3 — 无会议关联的里程碑和待跟进事项**\n'
        '只有在前两级没有足够推荐时才考虑，且必须说明今天不行动的具体损失。\n\n'
        '## 筛选门槛\n'
        '每条推荐必须能回答：今天不做，会错过什么具体的时间窗口或关系机会？答案模糊则不输出。\n\n'
        '## 输出格式（严格遵守字段名，不要输出 markdown 或代码块）\n'
        '{\n'
        '  "summary": "一句话点明今天最重要的关系行动机会（25字内）",\n'
        '  "items": [\n'
        '    {\n'
        '      "type": "schedule_focus",\n'
        '      "title": "具体行动标题（动词开头，15字内，可包含人名/事件名）",\n'
        '      "reason": "完整说明背景和行动理由，要包含具体的人名、事件名、时间，让用户不用点开事件就能理解。例如：\'Alex Brooks 明天生日，今天的战略沟通会议是当面祝贺的最佳时机，错过后只能发消息。\'（50字内）",\n'
        '      "primaryAction": "open_event",\n'
        '      "primaryTargetId": "对应ID，无则省略此字段",\n'
        '      "secondaryAction": "可选，无则省略此字段",\n'
        '      "secondaryTargetId": "可选，无则省略此字段"\n'
        '    }\n'
        '  ]\n'
        '}\n\n'
        '关于 reason 字段：这是用户决定是否行动的唯一依据。\n'
        '必须包含：①具体的人名或事件名 ②时间（今天/明天/X天后）③不行动的后果。\n'
        '禁止使用"错过重要机会"、"维护关系"这类空洞表达。\n\n'
        '允许的 type 值：follow_up、milestone、pending_action、schedule_focus。\n'
        '允许的 action 值：open_contact、open_event、open_todos、open_events_today、open_summaries、create_follow_up_event。\n'
        '最多输出 5 条。如果没有值得推荐的行动点，返回 items 为空数组，summary 说明今天节奏平稳。',
      ),
      AiMessage.user(jsonEncode(input.toJson())),
    ];
  }

}

class _HomeDailyBriefInput {
  final String date;
  final List<_CrossReferenceInsight> crossReferences;
  final List<_HomeDailyBriefEventInput> todayEvents;
  final List<_HomeDailyBriefEventInput> upcomingWeekEvents;
  final List<_HomeDailyBriefPendingActionInput> pendingActions;
  final List<_HomeDailyBriefMilestoneInput> upcomingMilestones;
  final int totalContacts;

  const _HomeDailyBriefInput({
    required this.date,
    required this.crossReferences,
    required this.todayEvents,
    required this.upcomingWeekEvents,
    required this.pendingActions,
    required this.upcomingMilestones,
    required this.totalContacts,
  });

  factory _HomeDailyBriefInput.fromHomeData({
    required HomeReadModel homeData,
    required DateTime now,
  }) {
    final todayKey = formatIsoDate(now);
    final upcomingWeekEvents = homeData.weekEvents.take(5).map(_HomeDailyBriefEventInput.fromWeekEvent).toList(growable: false);

    // 预计算交叉关系：今天参会 × 即将到来的里程碑，由代码保证准确，不依赖 AI 自行发现
    final todayParticipantNames = homeData.todayEvents
        .expand((e) => e.participantNames)
        .toSet();
    final crossReferences = homeData.upcomingMilestones
        .where((m) => todayParticipantNames.contains(m.contact.name))
        .map((m) {
          final relatedEvents = homeData.todayEvents
              .where((e) => e.participantNames.contains(m.contact.name))
              .toList();
          return _CrossReferenceInsight(
            contactId: m.contact.id,
            contactName: m.contact.name,
            contactTags: m.contact.tags,
            milestoneLabel: m.milestone.displayName,
            milestoneDaysUntil: m.daysUntil,
            todayEventIds: relatedEvents.map((e) => e.event.id).toList(),
            todayEventTitles: relatedEvents.map((e) => e.event.title).toList(),
            todayEventDescriptions: relatedEvents.map((e) => e.event.description ?? '').toList(),
          );
        })
        .toList(growable: false);

    return _HomeDailyBriefInput(
      date: todayKey,
      crossReferences: crossReferences,
      todayEvents: homeData.todayEvents
          .map(_HomeDailyBriefEventInput.fromTodayEvent)
          .toList(growable: false),
      upcomingWeekEvents: upcomingWeekEvents,
      pendingActions: homeData.pendingActions
          .where((action) => !action.completed)
          .map(_HomeDailyBriefPendingActionInput.fromActionItem)
          .toList(growable: false),
      upcomingMilestones: homeData.upcomingMilestones
          .take(5)
          .map(_HomeDailyBriefMilestoneInput.fromUpcomingMilestone)
          .toList(growable: false),
      totalContacts: homeData.totalContacts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'totalContacts': totalContacts,
      if (crossReferences.isNotEmpty)
        'crossReferences': crossReferences.map((r) => r.toJson()).toList(growable: false),
      'todayEvents': todayEvents.map((item) => item.toJson()).toList(growable: false),
      'upcomingWeekEvents': upcomingWeekEvents
          .map((item) => item.toJson())
          .toList(growable: false),
      'pendingActions': pendingActions
          .map((item) => item.toJson())
          .toList(growable: false),
      'upcomingMilestones': upcomingMilestones
          .map((item) => item.toJson())
          .toList(growable: false),
    };
  }
}

class _CrossReferenceInsight {
  final String contactId;
  final String contactName;
  final List<String> contactTags;
  final String milestoneLabel;
  final int milestoneDaysUntil;
  final List<String> todayEventIds;
  final List<String> todayEventTitles;
  final List<String> todayEventDescriptions;

  const _CrossReferenceInsight({
    required this.contactId,
    required this.contactName,
    required this.contactTags,
    required this.milestoneLabel,
    required this.milestoneDaysUntil,
    required this.todayEventIds,
    required this.todayEventTitles,
    required this.todayEventDescriptions,
  });

  Map<String, dynamic> toJson() {
    final daysLabel = milestoneDaysUntil == 0 ? '今天' : '$milestoneDaysUntil天后';
    return {
      'contactId': contactId,
      'contactName': contactName,
      if (contactTags.isNotEmpty) 'contactTags': contactTags,
      'milestone': '$daysLabel是$contactName的$milestoneLabel',
      'todayEvents': [
        for (var i = 0; i < todayEventIds.length; i++)
          {
            'eventId': todayEventIds[i],
            'title': todayEventTitles[i],
            if (todayEventDescriptions[i].isNotEmpty)
              'description': todayEventDescriptions[i],
          },
      ],
    };
  }
}

class _HomeDailyBriefEventInput {
  final String eventId;
  final String title;
  final String? description;
  final String? eventTypeName;
  final String? startsAt;
  final List<String> participantNames;

  const _HomeDailyBriefEventInput({
    required this.eventId,
    required this.title,
    required this.description,
    required this.eventTypeName,
    required this.startsAt,
    required this.participantNames,
  });

  factory _HomeDailyBriefEventInput.fromTodayEvent(TodayEventItem item) {
    return _HomeDailyBriefEventInput(
      eventId: item.event.id,
      title: item.event.title,
      description: item.event.description,
      eventTypeName: item.eventTypeName,
      startsAt: item.event.startAt?.toIso8601String(),
      participantNames: item.participantNames,
    );
  }

  factory _HomeDailyBriefEventInput.fromWeekEvent(EventListItemReadModel item) {
    return _HomeDailyBriefEventInput(
      eventId: item.event.id,
      title: item.event.title,
      description: item.event.description,
      eventTypeName: item.eventTypeName,
      startsAt: item.event.startAt?.toIso8601String(),
      participantNames: item.participantNames,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'title': title,
      if (description != null && description!.isNotEmpty) 'description': description,
      'eventTypeName': eventTypeName,
      'startsAt': startsAt,
      'participantNames': participantNames,
    };
  }
}

class _HomeDailyBriefPendingActionInput {
  final String title;
  final String? assigneeContactId;
  final String? dueAt;

  const _HomeDailyBriefPendingActionInput({
    required this.title,
    required this.assigneeContactId,
    required this.dueAt,
  });

  factory _HomeDailyBriefPendingActionInput.fromActionItem(ActionItem item) {
    return _HomeDailyBriefPendingActionInput(
      title: item.title,
      assigneeContactId: item.assigneeContactId,
      dueAt: item.dueAt?.toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'assigneeContactId': assigneeContactId,
      'dueAt': dueAt,
    };
  }
}

class _HomeDailyBriefMilestoneInput {
  final String contactId;
  final String contactName;
  final String milestoneId;
  final String label;
  final int daysUntil;
  final String nextOccurrence;

  const _HomeDailyBriefMilestoneInput({
    required this.contactId,
    required this.contactName,
    required this.milestoneId,
    required this.label,
    required this.daysUntil,
    required this.nextOccurrence,
  });

  factory _HomeDailyBriefMilestoneInput.fromUpcomingMilestone(
    ContactUpcomingMilestone item,
  ) {
    return _HomeDailyBriefMilestoneInput(
      contactId: item.contact.id,
      contactName: item.contact.name,
      milestoneId: item.milestone.id,
      label: item.milestone.displayName,
      daysUntil: item.daysUntil,
      nextOccurrence: item.nextOccurrence.toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contactId': contactId,
      'contactName': contactName,
      'milestoneId': milestoneId,
      'label': label,
      'daysUntil': daysUntil,
      'nextOccurrence': nextOccurrence,
    };
  }
}