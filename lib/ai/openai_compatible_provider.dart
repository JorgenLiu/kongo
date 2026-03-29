import 'dart:convert';

import 'package:http/http.dart' as http;

import '../exceptions/app_exception.dart';
import 'ai_provider.dart';

class OpenAiCompatibleProvider implements AiProvider {
  final String _providerId;
  final AiProviderConfig _config;
  final http.Client _client;

  OpenAiCompatibleProvider({
    required String providerId,
    required AiProviderConfig config,
    http.Client? httpClient,
  })  : _providerId = providerId,
        _config = config,
        _client = httpClient ?? http.Client();

  @override
  String get providerId => _providerId;

  @override
  Future<AiCompletion> complete({
    required List<AiMessage> messages,
    String? model,
  }) async {
    final baseUrl = (_config.baseUrl ?? '').trim();
    final resolvedModel = (model ?? _config.defaultModel ?? '').trim();
    if (baseUrl.isEmpty || resolvedModel.isEmpty) {
      throw const AiException(
        message: 'AI 提供商配置不完整',
        code: 'ai_provider_invalid_config',
      );
    }

    final uri = Uri.parse('${_normalizeBaseUrl(baseUrl)}/chat/completions');
    http.Response response;

    try {
      response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${_config.apiKey}',
            },
            body: jsonEncode({
              'model': resolvedModel,
              'messages': messages
                  .map((message) => {
                        'role': message.role,
                        'content': message.content,
                      })
                  .toList(),
            }),
          )
          .timeout(_config.timeout);
    } on AiException {
      rethrow;
    } on Exception catch (error) {
      throw AiException(
        message: 'AI 请求失败：$error',
        code: 'ai_request_failed',
        originalException: error,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiException(
        message: 'AI 请求失败（${response.statusCode}）：${_extractErrorMessage(response.body)}',
        code: 'ai_http_error',
      );
    }

    final payload = _decodeJsonMap(response.body);
    final choices = payload['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const AiException(
        message: 'AI 返回结果格式不正确',
        code: 'ai_invalid_response',
      );
    }

    final firstChoice = choices.first;
    if (firstChoice is! Map<String, dynamic>) {
      throw const AiException(
        message: 'AI 返回结果格式不正确',
        code: 'ai_invalid_response',
      );
    }

    final message = firstChoice['message'];
    if (message is! Map<String, dynamic>) {
      throw const AiException(
        message: 'AI 返回结果缺少 message',
        code: 'ai_invalid_response',
      );
    }

    final content = _extractContent(message['content']);
    final usage = payload['usage'];

    return AiCompletion(
      content: content,
      promptTokens: usage is Map<String, dynamic> ? usage['prompt_tokens'] as int? : null,
      completionTokens: usage is Map<String, dynamic>
          ? usage['completion_tokens'] as int?
          : null,
    );
  }

  @override
  void dispose() {
    _client.close();
  }

  String _normalizeBaseUrl(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }

    return value;
  }

  Map<String, dynamic> _decodeJsonMap(String rawBody) {
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException {
      throw const AiException(
        message: 'AI 返回了无法解析的响应',
        code: 'ai_invalid_json',
      );
    }

    throw const AiException(
      message: 'AI 返回结果格式不正确',
      code: 'ai_invalid_response',
    );
  }

  String _extractContent(Object? rawContent) {
    if (rawContent is String && rawContent.trim().isNotEmpty) {
      return rawContent.trim();
    }

    if (rawContent is List) {
      final parts = rawContent
          .whereType<Map<String, dynamic>>()
          .map((part) => part['text'])
          .whereType<String>()
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) {
        return parts.join('\n');
      }
    }

    throw const AiException(
      message: 'AI 返回内容为空',
      code: 'ai_empty_response',
    );
  }

  String _extractErrorMessage(String responseBody) {
    try {
      final payload = jsonDecode(responseBody);
      if (payload is Map<String, dynamic>) {
        final error = payload['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'];
          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
        }
      }
    } catch (_) {}

    final compact = responseBody.trim();
    if (compact.isEmpty) {
      return '空响应';
    }

    return compact.length > 160 ? '${compact.substring(0, 160)}...' : compact;
  }
}