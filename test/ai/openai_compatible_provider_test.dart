import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:kongo/ai/ai_provider.dart';
import 'package:kongo/ai/openai_compatible_provider.dart';
import 'package:kongo/exceptions/app_exception.dart';

void main() {
  test('complete parses string content and usage from successful response', () async {
    late Uri requestedUri;
    late Map<String, String> requestedHeaders;
    late Map<String, dynamic> requestedBody;

    final provider = OpenAiCompatibleProvider(
      providerId: 'deepseek',
      config: const AiProviderConfig(
        apiKey: 'sk-test',
        baseUrl: 'https://api.example.com/v1/',
        defaultModel: 'deepseek-chat',
      ),
      httpClient: MockClient((request) async {
        requestedUri = request.url;
        requestedHeaders = request.headers;
        requestedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': 'OK'},
              },
            ],
            'usage': {
              'prompt_tokens': 11,
              'completion_tokens': 7,
            },
          }),
          200,
        );
      }),
    );

    final completion = await provider.complete(
      messages: const [AiMessage.system('system'), AiMessage.user('user')],
    );

    expect(requestedUri.toString(), 'https://api.example.com/v1/chat/completions');
    expect(requestedHeaders['Authorization'], 'Bearer sk-test');
    expect(requestedBody['model'], 'deepseek-chat');
    expect(requestedBody['messages'], [
      {'role': 'system', 'content': 'system'},
      {'role': 'user', 'content': 'user'},
    ]);
    expect(completion.content, 'OK');
    expect(completion.promptTokens, 11);
    expect(completion.completionTokens, 7);

    provider.dispose();
  });

  test('complete joins segmented text content with new lines', () async {
    final provider = OpenAiCompatibleProvider(
      providerId: 'custom',
      config: const AiProviderConfig(
        apiKey: 'sk-test',
        baseUrl: 'https://api.example.com/v1',
        defaultModel: 'custom-model',
      ),
      httpClient: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': [
                    {'text': 'part one'},
                    {'text': 'part two'},
                  ],
                },
              },
            ],
          }),
          200,
        );
      }),
    );

    final completion = await provider.complete(messages: const [AiMessage.user('hi')]);

  expect(completion.content, 'part one\npart two');
    expect(completion.promptTokens, isNull);
    expect(completion.completionTokens, isNull);

    provider.dispose();
  });

  test('complete throws invalid config error when base url or model is missing', () async {
    final providerWithoutBaseUrl = OpenAiCompatibleProvider(
      providerId: 'custom',
      config: const AiProviderConfig(
        apiKey: 'sk-test',
        baseUrl: '',
        defaultModel: 'custom-model',
      ),
    );

    await expectLater(
      () => providerWithoutBaseUrl.complete(messages: const [AiMessage.user('hi')]),
      throwsA(
        isA<AiException>().having((error) => error.code, 'code', 'ai_provider_invalid_config'),
      ),
    );

    final providerWithoutModel = OpenAiCompatibleProvider(
      providerId: 'custom',
      config: const AiProviderConfig(
        apiKey: 'sk-test',
        baseUrl: 'https://api.example.com/v1',
        defaultModel: '',
      ),
    );

    await expectLater(
      () => providerWithoutModel.complete(messages: const [AiMessage.user('hi')]),
      throwsA(
        isA<AiException>().having((error) => error.code, 'code', 'ai_provider_invalid_config'),
      ),
    );

    providerWithoutBaseUrl.dispose();
    providerWithoutModel.dispose();
  });

  test('complete surfaces non-2xx responses as ai_http_error', () async {
    final provider = OpenAiCompatibleProvider(
      providerId: 'deepseek',
      config: const AiProviderConfig(
        apiKey: 'sk-test',
        baseUrl: 'https://api.example.com/v1',
        defaultModel: 'deepseek-chat',
      ),
      httpClient: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'error': {'message': 'invalid api key'},
          }),
          401,
        );
      }),
    );

    await expectLater(
      () => provider.complete(messages: const [AiMessage.user('hi')]),
      throwsA(
        isA<AiException>()
            .having((error) => error.code, 'code', 'ai_http_error')
            .having((error) => error.message, 'message', contains('invalid api key')),
      ),
    );

    provider.dispose();
  });

  test('complete throws ai_invalid_json for malformed payloads', () async {
    final provider = OpenAiCompatibleProvider(
      providerId: 'deepseek',
      config: const AiProviderConfig(
        apiKey: 'sk-test',
        baseUrl: 'https://api.example.com/v1',
        defaultModel: 'deepseek-chat',
      ),
      httpClient: MockClient((_) async => http.Response('not-json', 200)),
    );

    await expectLater(
      () => provider.complete(messages: const [AiMessage.user('hi')]),
      throwsA(
        isA<AiException>().having((error) => error.code, 'code', 'ai_invalid_json'),
      ),
    );

    provider.dispose();
  });

  test('complete throws ai_invalid_response when expected fields are missing', () async {
    final provider = OpenAiCompatibleProvider(
      providerId: 'deepseek',
      config: const AiProviderConfig(
        apiKey: 'sk-test',
        baseUrl: 'https://api.example.com/v1',
        defaultModel: 'deepseek-chat',
      ),
      httpClient: MockClient((_) async => http.Response(jsonEncode({'choices': []}), 200)),
    );

    await expectLater(
      () => provider.complete(messages: const [AiMessage.user('hi')]),
      throwsA(
        isA<AiException>().having((error) => error.code, 'code', 'ai_invalid_response'),
      ),
    );

    provider.dispose();
  });

  test('complete throws ai_empty_response when content is blank', () async {
    final provider = OpenAiCompatibleProvider(
      providerId: 'deepseek',
      config: const AiProviderConfig(
        apiKey: 'sk-test',
        baseUrl: 'https://api.example.com/v1',
        defaultModel: 'deepseek-chat',
      ),
      httpClient: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': '   '},
              },
            ],
          }),
          200,
        );
      }),
    );

    await expectLater(
      () => provider.complete(messages: const [AiMessage.user('hi')]),
      throwsA(
        isA<AiException>().having((error) => error.code, 'code', 'ai_empty_response'),
      ),
    );

    provider.dispose();
  });

  test('complete converts request exceptions and timeouts into ai_request_failed', () async {
    final throwingProvider = OpenAiCompatibleProvider(
      providerId: 'deepseek',
      config: const AiProviderConfig(
        apiKey: 'sk-test',
        baseUrl: 'https://api.example.com/v1',
        defaultModel: 'deepseek-chat',
      ),
      httpClient: MockClient((_) async => throw Exception('socket closed')),
    );

    await expectLater(
      () => throwingProvider.complete(messages: const [AiMessage.user('hi')]),
      throwsA(
        isA<AiException>().having((error) => error.code, 'code', 'ai_request_failed'),
      ),
    );
    throwingProvider.dispose();

    final timeoutProvider = OpenAiCompatibleProvider(
      providerId: 'deepseek',
      config: const AiProviderConfig(
        apiKey: 'sk-test',
        baseUrl: 'https://api.example.com/v1',
        defaultModel: 'deepseek-chat',
        timeout: Duration(milliseconds: 1),
      ),
      httpClient: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': 'late'},
              },
            ],
          }),
          200,
        );
      }),
    );

    await expectLater(
      () => timeoutProvider.complete(messages: const [AiMessage.user('hi')]),
      throwsA(
        isA<AiException>().having((error) => error.code, 'code', 'ai_request_failed'),
      ),
    );

    timeoutProvider.dispose();
  });
}