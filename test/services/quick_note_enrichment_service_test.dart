import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:kongo/ai/ai_service.dart';
import 'package:kongo/models/ai_job.dart';
import 'package:kongo/models/ai_output.dart';
import 'package:kongo/models/quick_note.dart';
import 'package:kongo/repositories/quick_note_repository.dart';
import 'package:kongo/services/quick_capture_parser.dart';
import 'package:kongo/services/quick_note_enrichment_service.dart';

import '../test_helpers/test_app_harness.dart';

void main() {
  late TestAppHarness harness;
  late QuickNoteRepository repository;
  late _FakeAiService aiService;
  late DefaultQuickNoteEnrichmentService enrichmentService;
  const uuid = Uuid();

  setUp(() async {
    harness = await createTestAppHarness();
    repository = SqliteQuickNoteRepository(harness.dependencies.databaseService);
    aiService = _FakeAiService();
    enrichmentService = DefaultQuickNoteEnrichmentService(aiService, repository);
  });

  tearDown(() async {
    await harness.dispose();
  });

  // ──────────────────── enrichNote ────────────────────

  test('enrichNote writes aiMetadata and updates enrichedAt when AI is available', () async {
    final note = await repository.insert(_makeNote(uuid.v4()));
    aiService.nextResult = _makeResult(
      noteId: note.id,
      content: jsonEncode({
        'topics': ['医疗会议', '药品审批'],
        'entities': [
          {'type': 'person', 'name': '王教授'},
        ],
        'sessionLabel': '医院拜访',
        'resurfaceAt': null,
      }),
    );

    await enrichmentService.enrichNote(note.id);

    final updated = await repository.findById(note.id);
    expect(updated, isNotNull);
    expect(updated!.enrichedAt, isNotNull);
    expect(updated.aiMetadata, isNotNull);
    expect(updated.aiMetadata!['topics'], ['医疗会议', '药品审批']);
    expect(updated.aiMetadata!['sessionLabel'], '医院拜访');
    expect(aiService.executeCallCount, 1);
    expect(aiService.lastRequest!.feature, 'quick_note_enrichment');
    expect(aiService.lastRequest!.targetId, note.id);
  });

  test('enrichNote silently skips and leaves note unchanged when AI is unavailable', () async {
    final note = await repository.insert(_makeNote(uuid.v4()));
    aiService.available = false;

    await enrichmentService.enrichNote(note.id);

    final unchanged = await repository.findById(note.id);
    expect(unchanged!.enrichedAt, isNull);
    expect(unchanged.aiMetadata, isNull);
    expect(aiService.executeCallCount, 0);
  });

  test('enrichNote silently catches exception and leaves note unchanged when AI throws', () async {
    final note = await repository.insert(_makeNote(uuid.v4()));
    aiService.executeError = Exception('AI 服务超时');

    await enrichmentService.enrichNote(note.id);

    final unchanged = await repository.findById(note.id);
    expect(unchanged!.enrichedAt, isNull);
    expect(unchanged.aiMetadata, isNull);
  });

  test('already enriched note is not enriched again', () async {
    final enrichedAt = DateTime(2026, 1, 1);
    final note = await repository.insert(_makeNote(uuid.v4()));
    await repository.updateEnrichment(
      note.id,
      aiMetadata: {'topics': ['已有主题']},
      enrichedAt: enrichedAt,
    );

    await enrichmentService.enrichNote(note.id);

    expect(aiService.executeCallCount, 0);
    final result = await repository.findById(note.id);
    expect(result!.aiMetadata!['topics'], ['已有主题']);
  });

  test('enrichNote silently skips when AI returns malformed JSON', () async {
    final note = await repository.insert(_makeNote(uuid.v4()));
    aiService.nextResult = _makeResult(
      noteId: note.id,
      content: '很抱歉，无法处理该请求。',
    );

    await enrichmentService.enrichNote(note.id);

    final unchanged = await repository.findById(note.id);
    expect(unchanged!.enrichedAt, isNull);
  });

  // ──────────────────── enrichPending ────────────────────

  test('enrichPending processes all unenriched notes in batch', () async {
    final id1 = uuid.v4();
    final id2 = uuid.v4();
    await repository.insert(_makeNote(id1));
    await repository.insert(_makeNote(id2));

    aiService.nextResultFactory = (request) => _makeResult(
          noteId: request.targetId,
          content: jsonEncode({
            'topics': ['主题'],
            'entities': [],
            'sessionLabel': null,
            'resurfaceAt': null,
          }),
        );

    await enrichmentService.enrichPending();

    final note1 = await repository.findById(id1);
    final note2 = await repository.findById(id2);
    expect(note1!.enrichedAt, isNotNull);
    expect(note2!.enrichedAt, isNotNull);
    expect(aiService.executeCallCount, 2);
  });

  test('enrichPending does not process any notes when AI is unavailable', () async {
    await repository.insert(_makeNote(uuid.v4()));
    aiService.available = false;

    await enrichmentService.enrichPending();

    expect(aiService.executeCallCount, 0);
  });
}

// ──────────────────── 工具函数 ────────────────────

QuickNote _makeNote(String id) {
  final now = DateTime.now();
  return QuickNote(
    id: id,
    content: '今天拜访了王教授，讨论了药品适应征申请流程',
    noteType: QuickNoteType.knowledge,
    captureDate: DateTime(now.year, now.month, now.day),
    createdAt: now,
    updatedAt: now,
  );
}

AiResult _makeResult({required String noteId, required String content}) {
  final now = DateTime.now();
  final job = AiJob(
    id: 'job-$noteId',
    feature: 'quick_note_enrichment',
    provider: 'mock',
    targetType: 'quick_note',
    targetId: noteId,
    status: AiJobStatus.completed,
    createdAt: now,
    completedAt: now,
  );
  final output = AiOutput(
    id: 'output-$noteId',
    aiJobId: 'job-$noteId',
    outputType: 'enrichment_metadata',
    content: content,
    createdAt: now,
  );
  return AiResult(job: job, output: output);
}

// ──────────────────── 测试替身 ────────────────────

class _FakeAiService implements AiService {
  bool available = true;
  int executeCallCount = 0;
  AiRequest? lastRequest;
  AiResult? nextResult;
  AiResult Function(AiRequest)? nextResultFactory;
  Exception? executeError;

  @override
  bool get isAvailable => available;

  @override
  Future<AiResult> execute(AiRequest request) async {
    executeCallCount++;
    lastRequest = request;
    if (executeError != null) throw executeError!;
    if (nextResultFactory != null) return nextResultFactory!(request);
    return nextResult!;
  }

  @override
  Future<List<AiJob>> getJobHistory(String targetType, String targetId) async =>
      const [];

  @override
  Future<List<AiOutput>> getJobOutputs(String aiJobId) async => const [];
}
