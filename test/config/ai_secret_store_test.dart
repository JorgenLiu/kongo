import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/exceptions/app_exception.dart';
import 'package:kongo/services/ai_secret_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(MethodChannelAiSecretStore.channelName);

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('unsupported store reports unsupported and no-ops', () async {
    final store = UnsupportedAiSecretStore();

    expect(await store.isSupported(), isFalse);
    expect(await store.loadApiKey(), isNull);
    await store.saveApiKey('sk-test');
    await store.clearApiKey();
  });

  test('method channel store delegates load/save/clear/isSupported', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'loadApiKey') {
        return 'sk-from-keychain';
      }
      if (call.method == 'isSupported') {
        return true;
      }
      return null;
    });

    final store = MethodChannelAiSecretStore();
    final apiKey = await store.loadApiKey();
    await store.saveApiKey('  sk-saved  ');
    await store.clearApiKey();
    final supported = await store.isSupported();

    expect(apiKey, 'sk-from-keychain');
    expect(supported, isTrue);
    expect(calls.map((call) => call.method), [
      'loadApiKey',
      'saveApiKey',
      'clearApiKey',
      'isSupported',
    ]);
    expect(calls[1].arguments, {'value': 'sk-saved'});
  });

  test('saveApiKey with empty value maps to clear call', () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return null;
    });

    final store = MethodChannelAiSecretStore();
    await store.saveApiKey('   ');

    expect(calls, ['clearApiKey']);
  });

  test('method channel platform exceptions map to AiException', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'read_failed', message: 'keychain unavailable');
    });

    final store = MethodChannelAiSecretStore();

    await expectLater(
      store.loadApiKey(),
      throwsA(
        isA<AiException>()
            .having((error) => error.code, 'code', 'read_failed')
            .having((error) => error.message, 'message', 'keychain unavailable'),
      ),
    );
  });
}
