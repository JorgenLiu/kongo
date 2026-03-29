import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'package:kongo/models/contact.dart';
import 'package:kongo/models/contact_draft.dart';
import 'package:kongo/models/contact_milestone.dart';
import 'package:kongo/models/contact_milestone_draft.dart';
import 'package:kongo/models/event_draft.dart';
import 'package:kongo/models/tag.dart';
import 'package:kongo/models/tag_draft.dart';
import 'package:kongo/models/todo_group_draft.dart';
import 'package:kongo/models/todo_item_draft.dart';
import 'package:kongo/services/app_dependencies.dart';
import 'package:kongo/services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dependencies = await AppDependencies.bootstrap(preloadContacts: false);

  try {
    final result = await seedDemoData(dependencies);
    final databasePath = path.join(
      await getDatabasesPath(),
      DatabaseService.defaultDatabaseFileName,
    );

    debugPrint('Demo data seeding completed.');
    debugPrint('Database: $databasePath');
    debugPrint('Inserted contacts: ${result.insertedContacts}');
    debugPrint('Inserted events: ${result.insertedEvents}');
    debugPrint('Inserted milestones: ${result.insertedMilestones}');
    debugPrint('Inserted todos: ${result.insertedTodos}');
    debugPrint('Inserted tags: ${result.insertedTags}');
    debugPrint('Tag assignments across seeded tags: ${result.totalTagAssignments}');
    debugPrint('Seeded contact pool: ${result.totalSeededContacts}');
    debugPrint('Seeded tag pool: ${result.totalSeededTags}');
  } finally {
    await dependencies.dispose();
  }

  exit(0);
}

Future<SeedDemoDataResult> seedDemoData(AppDependencies dependencies) async {
  final existingContacts = await dependencies.contactService.getContacts();
  final existingContactNames = existingContacts.map((contact) => contact.name).toSet();
  final contactNames = [..._englishContactNames, ..._chineseContactNames];

  var insertedContacts = 0;
  for (var index = 0; index < contactNames.length; index++) {
    final name = contactNames[index];
    if (existingContactNames.contains(name)) {
      continue;
    }

    final isEnglish = index < _englishContactNames.length;
    await dependencies.contactService.createContact(
      ContactDraft(
        name: name,
        phone: '1887000${(index + 1).toString().padLeft(4, '0')}',
        email: isEnglish
            ? 'demo.en.${(index + 1).toString().padLeft(3, '0')}@example.test'
            : 'demo.zh.${(index + 1).toString().padLeft(3, '0')}@example.test',
        address: isEnglish ? 'Test Avenue ${(index % 12) + 1}' : '测试路${(index % 12) + 1}号',
        notes: isEnglish ? 'English-only demo contact.' : '纯中文测试联系人。',
      ),
    );
    insertedContacts++;
  }

  final allContacts = await dependencies.contactService.getContacts();
  final seededContacts = allContacts.where((contact) => contactNames.contains(contact.name)).toList()
    ..sort((left, right) => left.name.compareTo(right.name));

  final eventTypes = await dependencies.eventService.getEventTypes();
  final existingEvents = await dependencies.eventService.getEvents();
  final existingEventTitles = existingEvents.map((event) => event.title).toSet();
  final eventSeeds = _buildEventSeeds();

  var insertedEvents = 0;
  for (var index = 0; index < eventSeeds.length; index++) {
    final seed = eventSeeds[index];
    if (existingEventTitles.contains(seed.title)) {
      continue;
    }

    final participants = _pickParticipants(seededContacts, index);
    final timeWindow = _buildTimeWindow(index);

    await dependencies.eventService.createEvent(
      EventDraft(
        title: seed.title,
        eventTypeId: eventTypes[index % eventTypes.length].id,
        startAt: timeWindow.startAt,
        endAt: timeWindow.endAt,
        location: seed.location,
        description: seed.description,
        createdByContactId: participants.first.id,
        participantIds: participants.map((contact) => contact.id).toList(),
      ),
    );
    insertedEvents++;
  }

  // 今天的专属事件（确保 AI 简报有「今天」的上下文）
  final now = DateTime.now();
  final todayEventSeeds = [
    (
      '季度业务对齐会议',
      '与核心团队确认 Q2 目标与资源分配。',
      '总部会议室A',
      DateTime(now.year, now.month, now.day, 10, 0),
    ),
    (
      '关键客户战略沟通',
      '讨论年度合作框架与下半年计划。',
      '客户办公室',
      DateTime(now.year, now.month, now.day, 14, 30),
    ),
    (
      '新合作方初次见面',
      '了解对方背景，探讨潜在合作空间。',
      '咖啡厅·静安',
      DateTime(now.year, now.month, now.day, 16, 0),
    ),
  ];

  for (final (title, desc, loc, startAt) in todayEventSeeds) {
    if (existingEventTitles.contains(title)) continue;
    final participants = _pickParticipants(seededContacts, insertedEvents);
    await dependencies.eventService.createEvent(
      EventDraft(
        title: title,
        eventTypeId: eventTypes[insertedEvents % eventTypes.length].id,
        startAt: startAt,
        endAt: startAt.add(const Duration(hours: 1, minutes: 30)),
        location: loc,
        description: desc,
        createdByContactId: participants.first.id,
        participantIds: participants.map((c) => c.id).toList(),
      ),
    );
    insertedEvents++;
  }

  final tagResult = await _seedTagsAndAssignments(
    dependencies: dependencies,
    contacts: allContacts,
  );

  final insertedMilestones = await _seedMilestones(
    dependencies: dependencies,
    contacts: seededContacts,
  );

  final insertedTodos = await _seedTodos(
    dependencies: dependencies,
    contacts: seededContacts,
    events: (await dependencies.eventService.getEvents()),
  );

  return SeedDemoDataResult(
    insertedContacts: insertedContacts,
    insertedEvents: insertedEvents,
    insertedMilestones: insertedMilestones,
    insertedTodos: insertedTodos,
    totalSeededContacts: seededContacts.length,
    insertedTags: tagResult.insertedTags,
    totalSeededTags: tagResult.totalSeededTags,
    totalTagAssignments: tagResult.totalTagAssignments,
  );
}

Future<_SeedTagResult> _seedTagsAndAssignments({
  required AppDependencies dependencies,
  required List<Contact> contacts,
}) async {
  final existingTags = await dependencies.tagService.getTags();
  final tagsByName = <String, Tag>{
    for (final tag in existingTags) tag.name: tag,
  };

  var insertedTags = 0;
  final seededTags = <Tag>[];

  for (final seed in _tagSeeds) {
    final existingTag = tagsByName[seed.name];
    if (existingTag != null) {
      seededTags.add(existingTag);
      continue;
    }

    final createdTag = await dependencies.tagService.createTag(
      TagDraft(
        name: seed.name,
        color: seed.color,
      ),
    );
    tagsByName[createdTag.name] = createdTag;
    seededTags.add(createdTag);
    insertedTags++;
  }

  final sortedContacts = [...contacts]..sort((left, right) => left.name.compareTo(right.name));
  for (var index = 0; index < seededTags.length; index++) {
    final tag = seededTags[index];
    final selectedContacts = _pickContactsForTag(sortedContacts, index);
    for (final contact in selectedContacts) {
      await dependencies.tagService.addTagToContact(contact.id, tag.id);
    }
  }

  var totalTagAssignments = 0;
  for (final tag in seededTags) {
    totalTagAssignments += await dependencies.tagService.getContactCountByTag(tag.id);
  }

  return _SeedTagResult(
    insertedTags: insertedTags,
    totalSeededTags: seededTags.length,
    totalTagAssignments: totalTagAssignments,
  );
}

List<_EventSeed> _buildEventSeeds() {
  final chinesePrefixes = ['客户回访', '项目复盘', '商务拜访', '方案评审', '合作沟通'];
  final chineseSuffixes = ['会议', '跟进', '讨论', '总结'];
  final englishPrefixes = ['Client', 'Project', 'Sales', 'Roadmap', 'Partnership'];
  final englishSuffixes = ['Review', 'Sync', 'Planning'];
  final mixedPrefixes = ['客户', '项目', '合作', '商务', '方案'];
  final mixedSuffixes = ['Review', 'Sync', 'Follow-up'];

  final seeds = <_EventSeed>[];

  for (final prefix in chinesePrefixes) {
    for (final suffix in chineseSuffixes) {
      seeds.add(
        _EventSeed(
          title: '$prefix$suffix',
          description: '这是用于界面联调的纯中文测试事件，重点观察中文搜索与列表排版。',
          location: '上海静安会议室',
        ),
      );
    }
  }

  for (final prefix in englishPrefixes) {
    for (final suffix in englishSuffixes) {
      seeds.add(
        _EventSeed(
          title: '$prefix $suffix',
          description: 'English-only demo event for layout, search, and list rendering checks.',
          location: 'Demo Room ${(seeds.length % 8) + 1}',
        ),
      );
    }
  }

  for (final prefix in mixedPrefixes) {
    for (final suffix in mixedSuffixes) {
      seeds.add(
        _EventSeed(
          title: '$prefix $suffix 讨论',
          description: '用于验证中英混合事件标题、搜索结果和详情页显示效果。',
          location: 'Hybrid Hub ${(seeds.length % 6) + 1}',
        ),
      );
    }
  }

  return seeds;
}

List<_PickedContact> _pickParticipants(List<Contact> contacts, int index) {
  final first = contacts[index % contacts.length];
  final second = contacts[(index + 17) % contacts.length];
  final third = contacts[(index + 39) % contacts.length];

  return [
    _PickedContact(id: first.id),
    _PickedContact(id: second.id),
    if (index.isEven) _PickedContact(id: third.id),
  ];
}

List<Contact> _pickContactsForTag(List<Contact> contacts, int index) {
  if (contacts.isEmpty) {
    return const [];
  }

  final shuffledContacts = [...contacts]..shuffle(Random(20260321 + index));
  final targetCount = min(contacts.length, 10 + (index % 6));
  return shuffledContacts.take(targetCount).toList();
}

_EventTimeWindow _buildTimeWindow(int index) {
  final now = DateTime.now();
  switch (index % 3) {
    case 0:
      final startAt = now.subtract(Duration(days: index + 2, hours: (index % 5) + 1));
      return _EventTimeWindow(startAt: startAt, endAt: startAt.add(const Duration(hours: 2)));
    case 1:
      final startAt = now.subtract(Duration(hours: (index % 3) + 1));
      return _EventTimeWindow(startAt: startAt, endAt: now.add(Duration(hours: (index % 4) + 1)));
    default:
      final startAt = now.add(Duration(days: index + 1, hours: (index % 6) + 1));
      return _EventTimeWindow(startAt: startAt, endAt: startAt.add(const Duration(hours: 1, minutes: 30)));
  }
}

class SeedDemoDataResult {
  final int insertedContacts;
  final int insertedEvents;
  final int insertedMilestones;
  final int insertedTodos;
  final int totalSeededContacts;
  final int insertedTags;
  final int totalSeededTags;
  final int totalTagAssignments;

  const SeedDemoDataResult({
    required this.insertedContacts,
    required this.insertedEvents,
    required this.insertedMilestones,
    required this.insertedTodos,
    required this.totalSeededContacts,
    required this.insertedTags,
    required this.totalSeededTags,
    required this.totalTagAssignments,
  });
}

class _SeedTagResult {
  final int insertedTags;
  final int totalSeededTags;
  final int totalTagAssignments;

  const _SeedTagResult({
    required this.insertedTags,
    required this.totalSeededTags,
    required this.totalTagAssignments,
  });
}

class _EventSeed {
  final String title;
  final String description;
  final String location;

  const _EventSeed({
    required this.title,
    required this.description,
    required this.location,
  });
}

class _EventTimeWindow {
  final DateTime startAt;
  final DateTime endAt;

  const _EventTimeWindow({
    required this.startAt,
    required this.endAt,
  });
}

// ── 里程碑种子 ────────────────────────────────────────────────────

/// 给 seededContacts 里的指定联系人添加即将到来的里程碑（幂等）。
/// 只在该联系人还没有任何里程碑时才写入，避免重复。
Future<int> _seedMilestones({
  required AppDependencies dependencies,
  required List<Contact> contacts,
}) async {
  if (contacts.isEmpty) return 0;

  final now = DateTime.now();
  var inserted = 0;

  // 每条记录：(联系人索引偏移, 距今天数, 类型, 可选自定义标签)
  final milestoneSeeds = [
    (0, 2, ContactMilestoneType.birthday, null),
    (1, 5, ContactMilestoneType.weddingAnniversary, null),
    (2, 3, ContactMilestoneType.collaborationStart, '合作开始'),
    (3, 7, ContactMilestoneType.birthday, null),
    (4, 1, ContactMilestoneType.firstMet, '初次见面纪念'),
    (5, 10, ContactMilestoneType.birthday, null),
    (6, 4, ContactMilestoneType.workStart, null),
    (7, 6, ContactMilestoneType.birthday, null),
    (8, 14, ContactMilestoneType.weddingAnniversary, null),
    (9, 2, ContactMilestoneType.collaborationStart, '战略合作启动'),
  ];

  for (final (offset, daysFromNow, type, label) in milestoneSeeds) {
    final contact = contacts[offset % contacts.length];
    final existing = await dependencies.contactMilestoneService.getMilestones(contact.id);
    if (existing.any((m) => m.type == type)) continue;

    // milestoneDate 的年份不重要（recurring=true），只关心月/日
    // 设置为今年的「今天 + daysFromNow」
    final target = now.add(Duration(days: daysFromNow));
    await dependencies.contactMilestoneService.createMilestone(
      contact.id,
      ContactMilestoneDraft(
        type: type,
        label: label,
        milestoneDate: DateTime(now.year - 1, target.month, target.day),
        isRecurring: true,
        reminderEnabled: false,
      ),
    );
    inserted++;
  }

  return inserted;
}

// ── 待办事项种子 ──────────────────────────────────────────────────

/// 创建一个「跟进清单」分组，写入多条未完成的 pending action 并关联联系人/事件。
/// 幂等：如果已有标题完全相同的分组就跳过。
Future<int> _seedTodos({
  required AppDependencies dependencies,
  required List<Contact> contacts,
  required List<dynamic> events,
}) async {
  if (contacts.isEmpty) return 0;

  const groupTitle = '关键跟进清单（Demo）';
  final board = await dependencies.todoReadService.loadBoard();
  if (board.groups.any((g) => g.group.title == groupTitle)) return 0;

  final group = await dependencies.todoService.createGroup(
    const TodoGroupDraft(
      title: groupTitle,
      description: '由 seedDemoData 自动生成的跟进事项，用于测试 AI 简报推荐效果。',
    ),
  );

  // (联系人索引, 事件索引或-1, 待办标题)
  final itemSeeds = [
    (0, 0, '跟进 Q2 合作提案，确认对方决策时间'),
    (1, -1, '发送上次会议纪要并确认签字'),
    (2, 1, '整理产品演示反馈并回复'),
    (3, -1, '确认下季度预算讨论会议时间'),
    (4, 0, '准备复盘会议所需数据报告'),
    (5, -1, '联系已超过90天未互动的重要客户'),
    (6, 2, '跟进合同修订进展'),
    (7, -1, '发送节日问候并约下次面见'),
  ];

  var inserted = 0;
  for (final (contactOffset, eventOffset, title) in itemSeeds) {
    final contact = contacts[contactOffset % contacts.length];
    final contactIds = [contact.id];
    final eventIds = (eventOffset >= 0 && events.isNotEmpty)
        ? [(events[eventOffset % events.length] as dynamic).id as String]
        : <String>[];

    await dependencies.todoService.createItem(
      group.id,
      TodoItemDraft(
        title: title,
        contactIds: contactIds,
        eventIds: eventIds,
      ),
    );
    inserted++;
  }

  return inserted;
}

class _PickedContact {
  final String id;

  const _PickedContact({required this.id});
}

class _TagSeed {
  final String name;
  final String color;

  const _TagSeed({
    required this.name,
    required this.color,
  });
}

const List<String> _englishContactNames = [
  'Alex Carter',
  'Blake Carter',
  'Casey Carter',
  'Drew Carter',
  'Evan Carter',
  'Alex Brooks',
  'Blake Brooks',
  'Casey Brooks',
  'Drew Brooks',
  'Evan Brooks',
  'Alex Turner',
  'Blake Turner',
  'Casey Turner',
  'Drew Turner',
  'Evan Turner',
  'Alex Foster',
  'Blake Foster',
  'Casey Foster',
  'Drew Foster',
  'Evan Foster',
  'Alex Parker',
  'Blake Parker',
  'Casey Parker',
  'Drew Parker',
  'Evan Parker',
  'Jordan Hayes',
  'Logan Hayes',
  'Morgan Hayes',
  'Parker Hayes',
  'Taylor Hayes',
  'Jordan Reed',
  'Logan Reed',
  'Morgan Reed',
  'Parker Reed',
  'Taylor Reed',
  'Jordan Lane',
  'Logan Lane',
  'Morgan Lane',
  'Parker Lane',
  'Taylor Lane',
  'Jordan Cole',
  'Logan Cole',
  'Morgan Cole',
  'Parker Cole',
  'Taylor Cole',
  'Jordan Scott',
  'Logan Scott',
  'Morgan Scott',
  'Parker Scott',
  'Taylor Scott',
];

const List<String> _chineseContactNames = [
  '赵明轩',
  '赵雨桐',
  '赵子涵',
  '赵思远',
  '赵嘉怡',
  '钱明轩',
  '钱雨桐',
  '钱子涵',
  '钱思远',
  '钱嘉怡',
  '孙明轩',
  '孙雨桐',
  '孙子涵',
  '孙思远',
  '孙嘉怡',
  '李明轩',
  '李雨桐',
  '李子涵',
  '李思远',
  '李嘉怡',
  '周明轩',
  '周雨桐',
  '周子涵',
  '周思远',
  '周嘉怡',
  '吴明轩',
  '吴雨桐',
  '吴子涵',
  '吴思远',
  '吴嘉怡',
  '郑明轩',
  '郑雨桐',
  '郑子涵',
  '郑思远',
  '郑嘉怡',
  '王明轩',
  '王雨桐',
  '王子涵',
  '王思远',
  '王嘉怡',
  '冯明轩',
  '冯雨桐',
  '冯子涵',
  '冯思远',
  '冯嘉怡',
  '陈明轩',
  '陈雨桐',
  '陈子涵',
  '陈思远',
  '陈嘉怡',
];

const List<_TagSeed> _tagSeeds = [
  _TagSeed(name: 'VIP 客户', color: '#0F766E'),
  _TagSeed(name: '潜在客户', color: '#2563EB'),
  _TagSeed(name: '高活跃', color: '#DC2626'),
  _TagSeed(name: '待回访', color: '#D97706'),
  _TagSeed(name: '已成交', color: '#15803D'),
  _TagSeed(name: '合作伙伴', color: '#7C3AED'),
  _TagSeed(name: '渠道', color: '#C2410C'),
  _TagSeed(name: '媒体', color: '#BE185D'),
  _TagSeed(name: '设计师', color: '#0891B2'),
  _TagSeed(name: '开发者', color: '#4F46E5'),
  _TagSeed(name: 'Founder', color: '#1D4ED8'),
  _TagSeed(name: 'Enterprise', color: '#0F172A'),
  _TagSeed(name: 'Follow-up', color: '#B45309'),
  _TagSeed(name: '重点城市', color: '#047857'),
  _TagSeed(name: '中英混合', color: '#9333EA'),
];