import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/ai/ai_provider.dart';
import 'package:kongo/ai/ai_service.dart';
import 'package:kongo/exceptions/app_exception.dart';
import 'package:kongo/models/ai_job.dart';
import 'package:kongo/models/ai_output.dart';
import 'package:kongo/repositories/ai_job_repository.dart';

void main() {
  late _FakeAiJobRepository repository;
  late AiRequest request;

  setUp(() {
    repository = _FakeAiJobRepository();
    request = const AiRequest(
      feature: 'daily_brief',
      targetType: 'home',
      targetId: 'today',
      outputType: 'daily_brief_markdown',
      model: 'deepseek-chat',
      messages: [
        AiMessage.system('system'),
        AiMessage.user('user'),
      ],
    );
  });

  test('execute throws ai_provider_not_configured when provider is absent', () async {
    final service = DefaultAiService(
      provider: null,
      aiJobRepository: repository,
    );

    expect(service.isAvailable, isFalse);
    await expectLater(
      () => service.execute(request),
      throwsA(
        isA<AiException>().having((error) => error.code, 'code', 'ai_provider_not_configured'),
      ),
    );
    expect(repository.insertedJobs, isEmpty);
  });

  test('execute inserts running job, output, and completed update on success', () async {
    final provider = _FakeAiProvider(
      completion: const AiCompletion(
        content: 'AI result',
        promptTokens: 10,
        completionTokens: 20,
      ),
    );
    final service = DefaultAiService(
      provider: provider,
      aiJobRepository: repository,
    );

    final result = await service.execute(request);

    expect(service.isAvailable, isTrue);
    expect(provider.lastMessages, request.messages);
    expect(provider.lastModel, 'deepseek-chat');
    expect(repository.insertedJobs, hasLength(1));
    expect(repository.insertedOutputs, hasLength(1));
    expect(repository.updatedJobs, hasLength(1));

    final insertedJob = repository.insertedJobs.single;
    expect(insertedJob.feature, 'daily_brief');
    expect(insertedJob.provider, 'fake-provider');
    expect(insertedJob.model, 'deepseek-chat');
    expect(insertedJob.targetType, 'home');
    expect(insertedJob.targetId, 'today');
    expect(insertedJob.status, AiJobStatus.running);

    final insertedOutput = repository.insertedOutputs.single;
    expect(insertedOutput.aiJobId, insertedJob.id);
    expect(insertedOutput.outputType, 'daily_brief_markdown');
    expect(insertedOutput.content, 'AI result');

    final updatedJob = repository.updatedJobs.single;
    expect(updatedJob.id, insertedJob.id);
    expect(updatedJob.status, AiJobStatus.completed);
    expect(updatedJob.completedAt, isNotNull);

    expect(result.job.status, AiJobStatus.completed);
    expect(result.output.content, 'AI result');
  });

  test('execute marks job failed and rethrows AiException from provider', () async {
    final provider = _ThrowingAiProvider(
      aiException: const AiException(
        message: 'provider failed',
        code: 'ai_http_error',
      ),
    );
    final service = DefaultAiService(
      provider: provider,
      aiJobRepository: repository,
    );

    await expectLater(
      () => service.execute(request),
      throwsA(
        isA<AiException>()
            .having((error) => error.code, 'code', 'ai_http_error')
            .having((error) => error.message, 'message', 'provider failed'),
      ),
    );

    expect(repository.insertedJobs, hasLength(1));
    expect(repository.insertedOutputs, isEmpty);
    expect(repository.updatedJobs, hasLength(1));
    final failedJob = repository.updatedJobs.single;
    expect(failedJob.status, AiJobStatus.failed);
    expect(failedJob.errorMessage, 'AI 调用失败');
    expect(failedJob.completedAt, isNotNull);
  });

  test('execute wraps non-AI exception and marks job failed', () async {
    final provider = _ThrowingAiProvider(error: Exception('boom'));
    final service = DefaultAiService(
      provider: provider,
      aiJobRepository: repository,
    );

    await expectLater(
      () => service.execute(request),
      throwsA(
        isA<AiException>()
            .having((error) => error.code, 'code', 'ai_call_failed')
            .having((error) => error.message, 'message', contains('boom')),
      ),
    );

    expect(repository.insertedJobs, hasLength(1));
    expect(repository.insertedOutputs, isEmpty);
    expect(repository.updatedJobs, hasLength(1));
    final failedJob = repository.updatedJobs.single;
    expect(failedJob.status, AiJobStatus.failed);
    expect(failedJob.errorMessage, contains('boom'));
    expect(failedJob.completedAt, isNotNull);
  });

  test('getJobHistory and getJobOutputs delegate to repository', () async {
    final expectedJob = AiJob(
      id: 'job-1',
      feature: 'daily_brief',
      provider: 'fake-provider',
      targetType: 'home',
      targetId: 'today',
      createdAt: DateTime(2026),
    );
    final expectedOutput = AiOutput(
      id: 'output-1',
      aiJobId: 'job-1',
      outputType: 'daily_brief_markdown',
      content: 'cached',
      createdAt: DateTime(2026),
    );
    repository.jobHistory = [expectedJob];
    repository.outputs = [expectedOutput];

    final service = DefaultAiService(
      provider: _FakeAiProvider(
        completion: const AiCompletion(content: 'unused'),
      ),
      aiJobRepository: repository,
    );

    final history = await service.getJobHistory('home', 'today');
    final outputs = await service.getJobOutputs('job-1');

    expect(history, [expectedJob]);
    expect(outputs, [expectedOutput]);
    expect(repository.lastHistoryTargetType, 'home');
    expect(repository.lastHistoryTargetId, 'today');
    expect(repository.lastOutputsJobId, 'job-1');
  });
}

class _FakeAiProvider implements AiProvider {
  final AiCompletion completion;
  List<AiMessage>? lastMessages;
  String? lastModel;

  _FakeAiProvider({required this.completion});

  @override
  String get providerId => 'fake-provider';

  @override
  Future<AiCompletion> complete({required List<AiMessage> messages, String? model}) async {
    lastMessages = messages;
    lastModel = model;
    return completion;
  }

  @override
  void dispose() {}
}

class _ThrowingAiProvider implements AiProvider {
  final AiException? aiException;
  final Exception? error;

  _ThrowingAiProvider({this.aiException, this.error});

  @override
  String get providerId => 'throwing-provider';

  @override
  Future<AiCompletion> complete({required List<AiMessage> messages, String? model}) async {
    if (aiException != null) {
      throw aiException!;
    }
    throw error!;
  }

  @override
  void dispose() {}
}

class _FakeAiJobRepository implements AiJobRepository {
  final List<AiJob> insertedJobs = [];
  final List<AiJob> updatedJobs = [];
  final List<AiOutput> insertedOutputs = [];

  List<AiJob> jobHistory = const [];
  List<AiOutput> outputs = const [];
  String? lastHistoryTargetType;
  String? lastHistoryTargetId;
  String? lastOutputsJobId;

  @override
  Future<AiJob> getById(String id) async {
    return insertedJobs.followedBy(updatedJobs).firstWhere((job) => job.id == id);
  }

  @override
  Future<List<AiJob>> getByTarget(String targetType, String targetId) async {
    lastHistoryTargetType = targetType;
    lastHistoryTargetId = targetId;
    return jobHistory;
  }

  @override
  Future<AiJob> insert(AiJob job) async {
    insertedJobs.add(job);
    return job;
  }

  @override
  Future<AiOutput> insertOutput(AiOutput output) async {
    insertedOutputs.add(output);
    return output;
  }

  @override
  Future<AiJob> update(AiJob job) async {
    updatedJobs.add(job);
    return job;
  }

  @override
  Future<List<AiOutput>> getOutputs(String aiJobId) async {
    lastOutputsJobId = aiJobId;
    return outputs;
  }
}