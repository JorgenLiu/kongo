import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:kongo/models/quick_note.dart';
import 'package:kongo/repositories/quick_note_repository.dart';
import 'package:kongo/repositories/summary_repository.dart';
import 'package:kongo/services/read/notes_read_service.dart';

import '../test_helpers/test_app_harness.dart';

void main() {
  late TestAppHarness harness;
  late QuickNoteRepository noteRepository;
  late NotesReadService readService;
  const uuid = Uuid();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  setUp(() async {
    harness = await createTestAppHarness();
    noteRepository = SqliteQuickNoteRepository(
      harness.dependencies.databaseService,
    );
    final summaryRepository =
        SqliteSummaryRepository(harness.dependencies.databaseService);
    readService = DefaultNotesReadService(noteRepository, summaryRepository);
  });

  tearDown(() async {
    await harness.dispose();
  });

  QuickNote _makeNote({
    String? contactId,
    required DateTime createdAt,
    String? content,
  }) {
    return QuickNote(
      id: uuid.v4(),
      content: content ?? '测试笔记',
      noteType: QuickNoteType.knowledge,
      captureDate: today,
      createdAt: createdAt,
      updatedAt: createdAt,
      linkedContactId: contactId,
    );
  }

  group('loadPage 无 filter', () {
    test('返回全部未软删笔记（按 createdAt 倒序）', () async {
      final t1 = today.add(const Duration(hours: 1));
      final t2 = today.add(const Duration(hours: 2));
      await noteRepository.insert(_makeNote(createdAt: t1, content: '第一条'));
      await noteRepository.insert(_makeNote(createdAt: t2, content: '第二条'));

      final result =
          await readService.loadPage(0, const NotesFilter.empty());

      expect(result, hasLength(2));
      expect(result.first.content, '第二条'); // 倒序
    });

    test('offset 分页正确', () async {
      for (var i = 0; i < 5; i++) {
        await noteRepository.insert(
          _makeNote(createdAt: today.add(Duration(hours: i)), content: 'note $i'),
        );
      }

      final page0 =
          await readService.loadPage(0, const NotesFilter.empty());
      expect(page0, hasLength(5));

      // 创建一个 pageSize=2 的测试（通过直接访问 repo 验证 offset）
      final offsetResult = await noteRepository.findPage(offset: 2, limit: 2);
      expect(offsetResult, hasLength(2));
    });
  });

  group('loadPage 按联系人 filter', () {
    test('只返回匹配 contactId 的笔记', () async {
      const targetId = 'contact-abc';
      const otherId = 'contact-xyz';

      await noteRepository.insert(
          _makeNote(contactId: targetId, createdAt: today, content: '目标联系人笔记1'));
      await noteRepository.insert(
          _makeNote(contactId: targetId, createdAt: today, content: '目标联系人笔记2'));
      await noteRepository.insert(
          _makeNote(contactId: otherId, createdAt: today, content: '其他联系人笔记'));
      await noteRepository.insert(
          _makeNote(createdAt: today, content: '无联系人笔记'));

      final result = await readService.loadPage(
        0,
        const NotesFilter(contactId: targetId, contactName: '张三'),
      );

      expect(result, hasLength(2));
      expect(result.every((n) => n.linkedContactId == targetId), isTrue);
    });

    test('联系人无笔记时返回空列表', () async {
      final result = await readService.loadPage(
        0,
        const NotesFilter(contactId: 'non-existent-id'),
      );

      expect(result, isEmpty);
    });

    test('分页 offset 在联系人过滤下正确', () async {
      const targetId = 'contact-page-test';
      for (var i = 0; i < 5; i++) {
        await noteRepository.insert(
          _makeNote(
            contactId: targetId,
            createdAt: today.add(Duration(hours: i)),
          ),
        );
      }

      final page0 = await noteRepository.findPage(
        offset: 0,
        limit: 3,
        contactId: targetId,
      );
      final page1 = await noteRepository.findPage(
        offset: 3,
        limit: 3,
        contactId: targetId,
      );

      expect(page0, hasLength(3));
      expect(page1, hasLength(2));
      // 页之间无重复
      final ids0 = page0.map((n) => n.id).toSet();
      final ids1 = page1.map((n) => n.id).toSet();
      expect(ids0.intersection(ids1), isEmpty);
    });
  });

  group('NotesFilter', () {
    test('isActive 在有 contactId 时为 true', () {
      const filter = NotesFilter(contactId: 'c-1', contactName: '张三');
      expect(filter.isActive, isTrue);
    });

    test('isActive 在 empty 时为 false', () {
      expect(const NotesFilter.empty().isActive, isFalse);
    });

    test('cleared 返回非激活 filter', () {
      const filter = NotesFilter(contactId: 'c-1');
      expect(filter.cleared.isActive, isFalse);
    });
  });
}
