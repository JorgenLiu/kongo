import 'package:kongo/models/contact_draft.dart';
import 'package:kongo/models/event_draft.dart';
import 'package:kongo/models/event_summary.dart';
import 'package:kongo/models/event_summary_draft.dart';
import 'package:kongo/services/app_dependencies.dart';

Future<void> seedTestFixtureData(AppDependencies dependencies) async {
  final existingContacts = await dependencies.contactService.getContacts();
  if (existingContacts.isNotEmpty) {
    return;
  }

  final contacts = <String, String>{};
  for (final seed in _contactSeeds) {
    final contact = await dependencies.contactService.createContact(
      ContactDraft(
        name: seed.name,
        phone: seed.phone,
        email: seed.email,
      ),
    );
    contacts[seed.key] = contact.id;
  }

  await dependencies.eventService.createEvent(
    EventDraft(
      title: '年度合作复盘',
      eventTypeId: 'evt-meeting',
      startAt: DateTime.now().subtract(const Duration(days: 3, hours: 2)),
      endAt: DateTime.now().subtract(const Duration(days: 3)),
      location: '静安办公室',
      description: '与核心联系人确认下阶段合作目标与报价节奏。',
      createdByContactId: contacts['zhangsan'],
      participantIds: [
        contacts['zhangsan']!,
        contacts['lisi']!,
      ],
      participantRoles: {
        contacts['zhangsan']!: 'initiator',
        contacts['lisi']!: 'investor',
      },
    ),
  );

  await dependencies.summaryService.createSummary(
    DailySummaryDraft(
      summaryDate: DateTime.now().subtract(const Duration(days: 1)),
      todaySummary: '确认 Q2 合作目标，并完成了关键联系人同步。',
      tomorrowPlan: 'TODO: 下周整理报价方案。',
      source: SummarySource.manual,
      createdByContactId: contacts['zhangsan'],
    ),
  );

  await dependencies.eventService.createEvent(
    EventDraft(
      title: '产品演示预约',
      eventTypeId: 'evt-followup',
      startAt: DateTime.now().add(const Duration(days: 5, hours: 3)),
      endAt: DateTime.now().add(const Duration(days: 5, hours: 4)),
      location: '线上会议',
      description: '安排新功能演示和后续商务节奏确认。',
      createdByContactId: contacts['zhangsan'],
      participantIds: [
        contacts['zhangsan']!,
        contacts['wangwu']!,
      ],
      participantRoles: {
        contacts['zhangsan']!: 'initiator',
        contacts['wangwu']!: 'supporter',
      },
    ),
  );

  await dependencies.contactProvider.loadContacts();
}

class _ContactSeed {
  final String key;
  final String name;
  final String phone;
  final String email;

  const _ContactSeed({
    required this.key,
    required this.name,
    required this.phone,
    required this.email,
  });
}

const List<_ContactSeed> _contactSeeds = [
  _ContactSeed(
    key: 'zhangsan',
    name: '张三',
    phone: '138 0000 0001',
    email: 'zhangsan@example.com',
  ),
  _ContactSeed(
    key: 'lisi',
    name: '李四',
    phone: '138 0000 0002',
    email: 'lisi@example.com',
  ),
  _ContactSeed(
    key: 'wangwu',
    name: '王五',
    phone: '138 0000 0003',
    email: 'wangwu@example.com',
  ),
  _ContactSeed(
    key: 'zhaoliu',
    name: '赵六',
    phone: '138 0000 0004',
    email: 'zhaoliu@example.com',
  ),
  _ContactSeed(
    key: 'sunqi',
    name: '孙七',
    phone: '138 0000 0005',
    email: 'sunqi@example.com',
  ),
  _ContactSeed(
    key: 'zhouba',
    name: '周八',
    phone: '138 0000 0006',
    email: 'zhoubo@example.com',
  ),
  _ContactSeed(
    key: 'wujiu',
    name: '吴九',
    phone: '138 0000 0007',
    email: 'wujiu@example.com',
  ),
];