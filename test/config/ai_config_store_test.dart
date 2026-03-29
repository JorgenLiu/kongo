import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/config/ai_config_store.dart';
import 'package:kongo/services/ai_secret_store.dart';
import 'package:kongo/services/settings_preferences_store.dart';

void main() {
  late Directory settingsDirectory;
  late JsonSettingsPreferencesStore settingsStore;
  late _MemoryAiSecretStore secretStore;
  late AiConfigStore store;

  setUp(() async {
    settingsDirectory = await Directory.systemTemp.createTemp('kongo_ai_config_test_');
    settingsStore = JsonSettingsPreferencesStore(
      settingsDirectoryResolver: () async => settingsDirectory,
    );
    secretStore = _MemoryAiSecretStore();
    store = AiConfigStore(
      settingsStore,
      secretStore: secretStore,
    );
  });

  tearDown(() async {
    if (await settingsDirectory.exists()) {
      await settingsDirectory.delete(recursive: true);
    }
  });

  test('load returns siliconflow preset and empty values by default', () async {
    final snapshot = await store.load();

    expect(snapshot.presetProvider, AiPresetProvider.siliconflow);
    expect(snapshot.apiKey, isEmpty);
    expect(snapshot.baseUrlOverride, isNull);
    expect(snapshot.modelOverride, isNull);
    expect(snapshot.resolvedBaseUrl, kAiPresets[AiPresetProvider.siliconflow]!.baseUrl);
    expect(snapshot.resolvedModel, kAiPresets[AiPresetProvider.siliconflow]!.defaultModel);
  });

  test('save and load persists preset provider settings', () async {
    await store.save(
      const AiSettingsSnapshot(
        presetProvider: AiPresetProvider.deepseek,
        apiKey: 'sk-test',
        modelOverride: 'deepseek-reasoner',
      ),
    );

    final snapshot = await store.load();

    expect(snapshot.presetProvider, AiPresetProvider.deepseek);
    expect(snapshot.apiKey, 'sk-test');
    expect(snapshot.baseUrlOverride, isNull);
    expect(snapshot.modelOverride, 'deepseek-reasoner');
    expect(snapshot.resolvedBaseUrl, kAiPresets[AiPresetProvider.deepseek]!.baseUrl);
    expect(snapshot.resolvedModel, 'deepseek-reasoner');
  });

  test('save and load persists custom provider overrides', () async {
    await store.save(
      const AiSettingsSnapshot(
        presetProvider: AiPresetProvider.custom,
        apiKey: 'sk-custom',
        baseUrlOverride: 'https://example.com/v1',
        modelOverride: 'custom-model',
      ),
    );

    final snapshot = await store.load();

    expect(snapshot.presetProvider, AiPresetProvider.custom);
    expect(snapshot.apiKey, 'sk-custom');
    expect(snapshot.baseUrlOverride, 'https://example.com/v1');
    expect(snapshot.modelOverride, 'custom-model');
    expect(snapshot.resolvedBaseUrl, 'https://example.com/v1');
    expect(snapshot.resolvedModel, 'custom-model');
  });

  test('switching from custom to preset clears stale base url override', () async {
    await store.save(
      const AiSettingsSnapshot(
        presetProvider: AiPresetProvider.custom,
        apiKey: 'sk-custom',
        baseUrlOverride: 'https://example.com/v1',
        modelOverride: 'custom-model',
      ),
    );

    await store.save(
      const AiSettingsSnapshot(
        presetProvider: AiPresetProvider.qwen,
        apiKey: 'sk-qwen',
        modelOverride: 'qwen-turbo',
      ),
    );

    final snapshot = await store.load();

    expect(snapshot.presetProvider, AiPresetProvider.qwen);
    expect(snapshot.apiKey, 'sk-qwen');
    expect(snapshot.baseUrlOverride, isNull);
    expect(snapshot.resolvedBaseUrl, kAiPresets[AiPresetProvider.qwen]!.baseUrl);
    expect(snapshot.resolvedModel, 'qwen-turbo');
  });

  test('empty model override is removed when saving', () async {
    await store.save(
      const AiSettingsSnapshot(
        presetProvider: AiPresetProvider.deepseek,
        apiKey: 'sk-model',
        modelOverride: 'reasoner',
      ),
    );

    await store.save(
      const AiSettingsSnapshot(
        presetProvider: AiPresetProvider.deepseek,
        apiKey: 'sk-model',
        modelOverride: '   ',
      ),
    );

    final snapshot = await store.load();

    expect(snapshot.modelOverride, isNull);
    expect(snapshot.resolvedModel, kAiPresets[AiPresetProvider.deepseek]!.defaultModel);
  });

  test('toProviderConfig returns null when required values are missing', () {
    expect(
      const AiSettingsSnapshot(
        presetProvider: AiPresetProvider.siliconflow,
        apiKey: '',
      ).toProviderConfig(),
      isNull,
    );

    expect(
      const AiSettingsSnapshot(
        presetProvider: AiPresetProvider.custom,
        apiKey: 'sk-test',
        baseUrlOverride: '',
        modelOverride: 'custom-model',
      ).toProviderConfig(),
      isNull,
    );

    expect(
      const AiSettingsSnapshot(
        presetProvider: AiPresetProvider.custom,
        apiKey: 'sk-test',
        baseUrlOverride: 'https://example.com/v1',
        modelOverride: '',
      ).toProviderConfig(),
      isNull,
    );
  });

  test('toProviderConfig resolves preset defaults and trims overrides', () {
    final presetConfig = const AiSettingsSnapshot(
      presetProvider: AiPresetProvider.siliconflow,
      apiKey: '  sk-preset  ',
    ).toProviderConfig();

    expect(presetConfig, isNotNull);
    expect(presetConfig!.apiKey, 'sk-preset');
    expect(presetConfig.baseUrl, kAiPresets[AiPresetProvider.siliconflow]!.baseUrl);
    expect(presetConfig.defaultModel, kAiPresets[AiPresetProvider.siliconflow]!.defaultModel);

    final customConfig = const AiSettingsSnapshot(
      presetProvider: AiPresetProvider.custom,
      apiKey: 'sk-custom',
      baseUrlOverride: '  https://example.com/v1  ',
      modelOverride: '  custom-model  ',
    ).toProviderConfig();

    expect(customConfig, isNotNull);
    expect(customConfig!.baseUrl, 'https://example.com/v1');
    expect(customConfig.defaultModel, 'custom-model');
  });

  test('load migrates legacy plaintext api key into secret store when supported', () async {
    await settingsStore.setString('ai_api_key', 'legacy-key');

    final snapshot = await store.load();

    expect(snapshot.apiKey, 'legacy-key');
    expect(await secretStore.loadApiKey(), 'legacy-key');
    expect(await settingsStore.getString('ai_api_key'), isNull);
  });

  test('load removes legacy plaintext api key when secret already exists', () async {
    await secretStore.saveApiKey('secure-key');
    await settingsStore.setString('ai_api_key', 'legacy-key');

    final snapshot = await store.load();

    expect(snapshot.apiKey, 'secure-key');
    expect(await settingsStore.getString('ai_api_key'), isNull);
  });

  test('load keeps legacy plaintext api key when secret store unsupported', () async {
    final unsupportedStore = AiConfigStore(
      settingsStore,
      secretStore: const _UnsupportedTestSecretStore(),
    );
    await settingsStore.setString('ai_api_key', 'legacy-key');

    final snapshot = await unsupportedStore.load();

    expect(snapshot.apiKey, 'legacy-key');
    expect(await settingsStore.getString('ai_api_key'), 'legacy-key');
  });
}

class _MemoryAiSecretStore implements AiSecretStore {
  String? _apiKey;

  @override
  Future<void> clearApiKey() async {
    _apiKey = null;
  }

  @override
  Future<bool> isSupported() async {
    return true;
  }

  @override
  Future<String?> loadApiKey() async {
    return _apiKey;
  }

  @override
  Future<void> saveApiKey(String value) async {
    _apiKey = value;
  }
}

class _UnsupportedTestSecretStore implements AiSecretStore {
  const _UnsupportedTestSecretStore();

  @override
  Future<void> clearApiKey() async {}

  @override
  Future<bool> isSupported() async {
    return false;
  }

  @override
  Future<String?> loadApiKey() async {
    return null;
  }

  @override
  Future<void> saveApiKey(String value) async {}
}