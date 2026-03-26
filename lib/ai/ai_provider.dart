/// AI 提供商的聊天消息。
class AiMessage {
  final String role;
  final String content;

  const AiMessage({required this.role, required this.content});

  const AiMessage.system(this.content) : role = 'system';
  const AiMessage.user(this.content) : role = 'user';
}

/// AI 提供商返回的补全结果。
class AiCompletion {
  final String content;
  final int? promptTokens;
  final int? completionTokens;

  const AiCompletion({
    required this.content,
    this.promptTokens,
    this.completionTokens,
  });
}

/// AI 提供商配置。
class AiProviderConfig {
  final String apiKey;
  final String? baseUrl;
  final String? defaultModel;
  final Duration timeout;

  const AiProviderConfig({
    required this.apiKey,
    this.baseUrl,
    this.defaultModel,
    this.timeout = const Duration(seconds: 60),
  });
}

/// AI 提供商抽象接口。
///
/// 不同厂商（OpenAI、Claude、Ollama 等）各自实现此接口，
/// 由 [AiService] 统一调度。
abstract class AiProvider {
  /// 提供商标识符（如 'openai'、'claude'、'ollama'）。
  String get providerId;

  /// 发送消息列表并返回补全结果。
  Future<AiCompletion> complete({
    required List<AiMessage> messages,
    String? model,
  });

  /// 释放底层 HTTP 客户端等资源。
  void dispose();
}
