import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:kongo/models/quick_note.dart';
import 'package:kongo/providers/notes_provider.dart';
import 'package:kongo/repositories/quick_note_repository.dart';
import 'package:kongo/repositories/summary_repository.dart';
import 'package:kongo/services/quick_capture_parser.dart';
import 'package:kongo/services/read/notes_read_service.dart';

import '../test_helpers/test_app_harness.dart';

void main() {
  late TestAppHarness harness;
  late NotesProvider provider;
  late QuickNoteRepository noteRepository;
  const uuid = Uuid();

  final today = DateTime.now();
  final todayNormalized = DateTime(today.year, today.month, today.day);

  setUp(() async {
    harness = await createTestAppHarness();
    noteRepository = SqliteQuickNoteRepository(harness.dependencies.databaseService);
    final summaryRepository = SqliteSummaryRepository(harness.dependencies.databaseService);
    final readService = DefaultNotesReadService(noteRepository, summaryRepository);
    provider = NotesProvider(readService);
  });

  tearDown(() async {
    provider.dispose();
    await harness.dispose();
  });

  test('initial state is not loaded', () {
    expect(provider.initialized, isFalse);
    expect(provider.loading, isFalse);
    expect(provider.data, isNull);
  });

  test('loadToday loads empty data for today', () async {
    await provider.loadToday();

    expect(provider.initialized, isTrue);
    expect(provider.error, isNull);
    expect(provider.data, isNotNull);
    expect(provider.data!.sessions, isEmpty);
    expect(provider.currentDate, todayNormalized);
  });

  test('loadToday result includes previously written notes', () async {
    await noteRepository.insert(QuickNote(
      id: uuid.v4(),
      content: '今天见了张伟',
      noteType: QuickNoteType.knowledge,
      sessionGroup: 'sg-001',
      captureDate: todayNormalized,
      createdAt: todayNormalized,
      updatedAt: todayNormalized,
    ));

    await provider.loadToday();

    expect(provider.data!.sessions, hasLength(1));
    expect(provider.data!.sessions.first.notes.first.content, '今天见了张伟');
  });

  test('navigateToDate switches to a historical date', () async {
    final yesterday = todayNormalized.subtract(const Duration(days: 1));
    await noteRepository.insert(QuickNote(
      id: uuid.v4(),
      content: '昨天的笔记',
      noteType: QuickNoteType.knowledge,
      captureDate: yesterday,
      createdAt: yesterday,
      updatedAt: yesterday,
    ));

    await provider.navigateToDate(yesterday);

    expect(provider.currentDate, yesterday);
    expect(provider.data!.sessions, hasLength(1));
    expect(provider.data!.sessions.first.notes.first.content, '昨天的笔记');
  });

  test('refresh before initialization is equivalent to loadToday', () async {
    await provider.refresh();

    expect(provider.initialized, isTrue);
    expect(provider.currentDate, todayNormalized);
  });

  test('load failure sets error state', () async {
    // 使用一个总是抛出异常的 mock 服务来触发失败路径
    final failingProvider = NotesProvider(_ThrowingNotesReadService());
    addTearDown(failingProvider.dispose);

    await failingProvider.loadToday();

    expect(failingProvider.error, isNotNull);
    expect(failingProvider.initialized, isFalse);
  });
}

class _ThrowingNotesReadService implements NotesReadService {
  @override
  Future<DayNotesModel> loadDay(DateTime date) =>
      Future.error(Exception('DB 连接失败'));

  @override
  Future<int> countForDate(DateTime date) =>
      Future.error(Exception('DB 连接失败'));

  @override
  Future<List<QuickNote>> findByContactId(String contactId) =>
      Future.error(Exception('DB 连接失败'));

  @override
  Future<List<QuickNote>> findByEventId(String eventId) =>
      Future.error(Exception('DB 连接失败'));
}
