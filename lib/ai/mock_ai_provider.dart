import 'ai_provider.dart';

/// 测试用的模拟 AI 提供商。
///
/// 每次调用 [complete] 时返回预设的 [nextResponse]。
/// 如果 [shouldFail] 为 true，则抛出异常。
class MockAiProvider implements AiProvider {
  String nextResponse;
  bool shouldFail;
  int callCount = 0;
  List<AiMessage>? lastMessages;

  MockAiProvider({
    this.nextResponse = '',
    this.shouldFail = false,
  });

  @override
  String get providerId => 'mock';

  @override
  Future<AiCompletion> complete({
    required List<AiMessage> messages,
    String? model,
  }) async {
    callCount++;
    lastMessages = messages;

    if (shouldFail) {
      throw Exception('Mock AI provider error');
    }

    return AiCompletion(
      content: nextResponse,
      promptTokens: 10,
      completionTokens: 20,
    );
  }

  @override
  void dispose() {}
}
