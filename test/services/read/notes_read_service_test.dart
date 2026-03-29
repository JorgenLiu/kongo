import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:kongo/models/quick_note.dart';
import 'package:kongo/repositories/quick_note_repository.dart';
import 'package:kongo/repositories/summary_repository.dart';
import 'package:kongo/services/read/notes_read_service.dart';
import 'package:kongo/models/event_summary_draft.dart';
import 'package:kongo/models/event_summary.dart';

import 'package:kongo/services/quick_capture_parser.dart';

import '../../test_helpers/test_app_harness.dart';

void main() {
  late TestAppHarness harness;
  late NotesReadService notesReadService;
  late QuickNoteRepository noteRepository;
  const uuid = Uuid();

  final today = DateTime.now();
  final todayNormalized = DateTime(today.year, today.month, today.day);

  setUp(() async {
    harness = await createTestAppHarness();
    noteRepository = SqliteQuickNoteRepository(harness.dependencies.databaseService);
    final summaryRepository = SqliteSummaryRepository(harness.dependencies.databaseService);
    notesReadService = DefaultNotesReadService(noteRepository, summaryRepository);
  });

  tearDown(() async {
    await harness.dispose();
  });

  group('loadDay', () {
    test('sessions are empty and summary is null when no notes or summary for the day', () async {
      final result = await notesReadService.loadDay(todayNormalized);

      expect(result.sessions, isEmpty);
      expect(result.summary, isNull);
      expect(result.isEmpty, isTrue);
    });

    test('three notes in a single session are correctly grouped', () async {
      const sessionId = 'session-abc';
      for (var i = 0; i < 3; i++) {
        await noteRepository.insert(QuickNote(
          id: uuid.v4(),
          content: '笔记第$i条',
          noteType: QuickNoteType.knowledge,
          sessionGroup: sessionId,
          captureDate: todayNormalized,
          createdAt: todayNormalized.add(Duration(minutes: i)),
          updatedAt: todayNormalized,
        ));
      }

      final result = await notesReadService.loadDay(todayNormalized);

      expect(result.sessions, hasLength(1));
      expect(result.sessions.first.notes, hasLength(3));
      expect(result.sessions.first.sessionId, sessionId);
    });

    test('notes in two different sessions are correctly split into two groups', () async {
      for (final sid in ['session-1', 'session-2']) {
        for (var i = 0; i < 2; i++) {
          await noteRepository.insert(QuickNote(
            id: uuid.v4(),
            content: '$sid-笔记$i',
            noteType: QuickNoteType.knowledge,
            sessionGroup: sid,
            captureDate: todayNormalized,
            createdAt: todayNormalized.add(Duration(hours: sid == 'session-1' ? i : i + 5)),
            updatedAt: todayNormalized,
          ));
        }
      }

      final result = await notesReadService.loadDay(todayNormalized);

      expect(result.sessions, hasLength(2));
      expect(result.sessions.every((s) => s.notes.length == 2), isTrue);
    });

    test('each note with null sessionGroup forms its own independent session', () async {
      for (var i = 0; i < 3; i++) {
        await noteRepository.insert(QuickNote(
          id: uuid.v4(),
          content: '独立笔记$i',
          noteType: QuickNoteType.knowledge,
          sessionGroup: null,
          captureDate: todayNormalized,
          createdAt: todayNormalized.add(Duration(minutes: i * 10)),
          updatedAt: todayNormalized,
        ));
      }

      final result = await notesReadService.loadDay(todayNormalized);

      expect(result.sessions, hasLength(3));
      expect(result.sessions.every((s) => s.notes.length == 1), isTrue);
    });

    test('summary is not null when a daily summary exists', () async {
      await harness.dependencies.summaryService.createSummary(
        DailySummaryDraft(
          summaryDate: todayNormalized,
          todaySummary: '今日工作顺利完成',
          tomorrowPlan: '明天继续',
          source: SummarySource.manual,
        ),
      );

      final result = await notesReadService.loadDay(todayNormalized);

      expect(result.summary, isNotNull);
      expect(result.summary!.todaySummary, '今日工作顺利完成');
    });
  });

  group('countForDate', () {
    test('returns 0 when there are no notes', () async {
      final count = await notesReadService.countForDate(todayNormalized);
      expect(count, 0);
    });

    test('returns correct count when notes exist', () async {
      for (var i = 0; i < 4; i++) {
        await noteRepository.insert(QuickNote(
          id: uuid.v4(),
          content: '笔记$i',
          noteType: QuickNoteType.knowledge,
          captureDate: todayNormalized,
          createdAt: todayNormalized.add(Duration(minutes: i)),
          updatedAt: todayNormalized,
        ));
      }

      final count = await notesReadService.countForDate(todayNormalized);
      expect(count, 4);
    });
  });
}
