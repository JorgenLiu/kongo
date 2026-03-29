import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/services/database_service.dart';
import 'package:kongo/services/quick_capture_service.dart';

import '../test_helpers/test_app_harness.dart';

void main() {
  late TestAppHarness harness;
  late QuickCaptureService service;

  setUp(() async {
    harness = await createTestAppHarness();
    service = harness.dependencies.quickCaptureService;
  });

  tearDown(() async {
    await harness.dispose();
  });

  // ──────────────────── saveRawNote ────────────────────

  test('saveRawNote is queryable after writing to database', () async {
    await service.saveRawNote('今天见了张伟，聊了Q2预算');

    final db = await harness.dependencies.databaseService.database;
    final rows = await db.query(
      DatabaseService.quickNotesTable,
      where: 'deletedAt IS NULL',
    );

    expect(rows, hasLength(1));
    expect(rows.first['content'], '今天见了张伟，聊了Q2预算');
    expect(rows.first['noteType'], 'knowledge');
    expect(rows.first['captureDate'], isNotEmpty);
    expect(rows.first['createdAt'], isNotEmpty);
    expect(rows.first['linkedContactId'], isNull);
  });

  test('saveRawNote does not write empty string', () async {
    await service.saveRawNote('');
    await service.saveRawNote('   ');

    final db = await harness.dependencies.databaseService.database;
    final rows = await db.query(
      DatabaseService.quickNotesTable,
      where: 'deletedAt IS NULL',
    );

    expect(rows, isEmpty);
  });

  test('saveRawNote trims content before saving', () async {
    await service.saveRawNote('  CloudKit 单条记录上限 10MB  ');

    final db = await harness.dependencies.databaseService.database;
    final rows = await db.query(DatabaseService.quickNotesTable);

    expect(rows.first['content'], 'CloudKit 单条记录上限 10MB');
  });

  test('multiple saveRawNote calls create independent records with unique ids', () async {
    await service.saveRawNote('笔记一');
    await service.saveRawNote('笔记二');

    final db = await harness.dependencies.databaseService.database;
    final rows = await db.query(DatabaseService.quickNotesTable);

    expect(rows, hasLength(2));
    final ids = rows.map((r) => r['id']).toSet();
    expect(ids, hasLength(2));
  });

  // ──────────────────── saveNote ────────────────────

  test('saveNote writes structured note with linkedContactId', () async {
    await service.saveNote(
      '张三更换了供应商',
      linkedContactId: 'contact-123',
      noteType: 'structured',
    );

    final db = await harness.dependencies.databaseService.database;
    final rows = await db.query(DatabaseService.quickNotesTable);

    expect(rows, hasLength(1));
    expect(rows.first['linkedContactId'], 'contact-123');
    expect(rows.first['noteType'], 'structured');
  });

  test('saveNote defaults noteType to knowledge', () async {
    await service.saveNote('纯知识笔记');

    final db = await harness.dependencies.databaseService.database;
    final rows = await db.query(DatabaseService.quickNotesTable);

    expect(rows.first['noteType'], 'knowledge');
  });

  test('saveNote does not write empty string', () async {
    await service.saveNote('');
    await service.saveNote('  ', linkedContactId: 'c-1');

    final db = await harness.dependencies.databaseService.database;
    final rows = await db.query(DatabaseService.quickNotesTable);

    expect(rows, isEmpty);
  });

  // ──────────────────── 会话分组 ────────────────────

  test('consecutively written notes share the same sessionGroup', () async {
    await service.saveRawNote('笔记一');
    await service.saveRawNote('笔记二');

    final db = await harness.dependencies.databaseService.database;
    final rows = await db.query(
      DatabaseService.quickNotesTable,
      orderBy: 'createdAt ASC',
    );

    expect(rows, hasLength(2));
    expect(rows.first['sessionGroup'], isNotNull);
    expect(rows.first['sessionGroup'], rows.last['sessionGroup']);
  });
}

