import 'package:uuid/uuid.dart';

import '../exceptions/app_exception.dart';
import '../models/ai_job.dart';
import '../models/ai_output.dart';
import '../repositories/ai_job_repository.dart';
import 'ai_provider.dart';

/// AI 请求描述，由业务层构造后交给 [AiService] 执行。
class AiRequest {
  /// 功能标识，如 'summary_generation'、'action_item_extraction'。
  final String feature;

  /// 目标实体类型，如 'daily_summary'、'contact'。
  final String targetType;

  /// 目标实体 ID。
  final String targetId;

  /// AI 输出类型标识，如 'summary_draft'、'action_items'。
  final String outputType;

  /// 提示词消息列表。
  final List<AiMessage> messages;

  /// 可选的模型覆盖。
  final String? model;

  const AiRequest({
    required this.feature,
    required this.targetType,
    required this.targetId,
    required this.outputType,
    required this.messages,
    this.model,
  });
}

/// AI 执行结果，包含作业记录和输出内容。
class AiResult {
  final AiJob job;
  final AiOutput output;

  const AiResult({required this.job, required this.output});
}

/// AI 服务编排层。
///
/// 职责：
/// 1. 接收业务层构造的 [AiRequest]
/// 2. 创建 [AiJob] 记录（状态追踪）
/// 3. 调用 [AiProvider] 获取补全
/// 4. 将结果写入 [AiOutput]
/// 5. 更新 [AiJob] 状态
abstract class AiService {
  /// 执行 AI 请求并返回结果。
  ///
  /// 如果 AI 提供商未配置，抛出 [AiException]。
  Future<AiResult> execute(AiRequest request);

  /// 查询某个目标实体的 AI 作业历史。
  Future<List<AiJob>> getJobHistory(String targetType, String targetId);

  /// 查询某个作业的输出内容。
  Future<List<AiOutput>> getJobOutputs(String aiJobId);

  /// 当前是否已配置可用的 AI 提供商。
  bool get isAvailable;
}

class DefaultAiService implements AiService {
  final AiProvider? _provider;
  final AiJobRepository _aiJobRepository;
  final Uuid _uuid;

  DefaultAiService({
    AiProvider? provider,
    required AiJobRepository aiJobRepository,
    Uuid? uuid,
  })  : _provider = provider,
        _aiJobRepository = aiJobRepository,
        _uuid = uuid ?? const Uuid();

  @override
  bool get isAvailable => _provider != null;

  @override
  Future<AiResult> execute(AiRequest request) async {
    final provider = _provider;
    if (provider == null) {
      throw const AiException(
        message: 'AI 提供商未配置',
        code: 'ai_provider_not_configured',
      );
    }

    final now = DateTime.now();
    var job = AiJob(
      id: _uuid.v4(),
      feature: request.feature,
      provider: provider.providerId,
      model: request.model,
      targetType: request.targetType,
      targetId: request.targetId,
      status: AiJobStatus.running,
      createdAt: now,
    );
    job = await _aiJobRepository.insert(job);

    try {
      final completion = await provider.complete(
        messages: request.messages,
        model: request.model,
      );

      final output = await _aiJobRepository.insertOutput(
        AiOutput(
          id: _uuid.v4(),
          aiJobId: job.id,
          outputType: request.outputType,
          content: completion.content,
          createdAt: DateTime.now(),
        ),
      );

      job = await _aiJobRepository.update(
        job.copyWith(
          status: AiJobStatus.completed,
          completedAt: DateTime.now(),
        ),
      );

      return AiResult(job: job, output: output);
    } on AiException {
      await _aiJobRepository.update(
        job.copyWith(
          status: AiJobStatus.failed,
          errorMessage: 'AI 调用失败',
          completedAt: DateTime.now(),
        ),
      );
      rethrow;
    } on Exception catch (error) {
      await _aiJobRepository.update(
        job.copyWith(
          status: AiJobStatus.failed,
          errorMessage: error.toString(),
          completedAt: DateTime.now(),
        ),
      );
      throw AiException(
        message: 'AI 调用失败：${error.toString()}',
        code: 'ai_call_failed',
        originalException: error,
      );
    }
  }

  @override
  Future<List<AiJob>> getJobHistory(String targetType, String targetId) {
    return _aiJobRepository.getByTarget(targetType, targetId);
  }

  @override
  Future<List<AiOutput>> getJobOutputs(String aiJobId) {
    return _aiJobRepository.getOutputs(aiJobId);
  }
}
