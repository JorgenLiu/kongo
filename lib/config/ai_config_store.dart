import '../ai/ai_provider.dart';
import '../services/ai_secret_store.dart';
import '../services/settings_preferences_store.dart';

enum AiPresetProvider {
  siliconflow,
  deepseek,
  qwen,
  custom,
}

class AiPreset {
  final String label;
  final String baseUrl;
  final String defaultModel;

  const AiPreset({
    required this.label,
    required this.baseUrl,
    required this.defaultModel,
  });
}

const Map<AiPresetProvider, AiPreset> kAiPresets = {
  AiPresetProvider.siliconflow: AiPreset(
    label: '硅基流动',
    baseUrl: 'https://api.siliconflow.cn/v1',
    defaultModel: 'deepseek-ai/DeepSeek-V3',
  ),
  AiPresetProvider.deepseek: AiPreset(
    label: 'DeepSeek 官方',
    baseUrl: 'https://api.deepseek.com/v1',
    defaultModel: 'deepseek-chat',
  ),
  AiPresetProvider.qwen: AiPreset(
    label: '通义千问',
    baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    defaultModel: 'qwen-plus',
  ),
  AiPresetProvider.custom: AiPreset(
    label: '自定义',
    baseUrl: '',
    defaultModel: '',
  ),
};

class AiSettingsSnapshot {
  final AiPresetProvider presetProvider;
  final String apiKey;
  final String? baseUrlOverride;
  final String? modelOverride;

  const AiSettingsSnapshot({
    required this.presetProvider,
    required this.apiKey,
    this.baseUrlOverride,
    this.modelOverride,
  });

  AiPreset get preset => kAiPresets[presetProvider]!;

  String get resolvedBaseUrl {
    if (presetProvider == AiPresetProvider.custom) {
      return (baseUrlOverride ?? '').trim();
    }

    return preset.baseUrl;
  }

  String get resolvedModel {
    final override = modelOverride?.trim();
    if (override != null && override.isNotEmpty) {
      return override;
    }

    return preset.defaultModel;
  }

  AiProviderConfig? toProviderConfig() {
    final apiKeyValue = apiKey.trim();
    final baseUrlValue = resolvedBaseUrl;
    final modelValue = resolvedModel;
    if (apiKeyValue.isEmpty || baseUrlValue.isEmpty || modelValue.isEmpty) {
      return null;
    }

    return AiProviderConfig(
      apiKey: apiKeyValue,
      baseUrl: baseUrlValue,
      defaultModel: modelValue,
    );
  }
}

class AiConfigStore {
  static const _keyProviderId = 'ai_provider_id';
  static const _keyApiKey = 'ai_api_key';
  static const _keyBaseUrl = 'ai_base_url';
  static const _keyModel = 'ai_model';

  final SettingsPreferencesStore _store;
  final AiSecretStore _secretStore;

  AiConfigStore(
    this._store, {
    AiSecretStore? secretStore,
  }) : _secretStore = secretStore ?? UnsupportedAiSecretStore();

  Future<AiSettingsSnapshot> load() async {
    final rawProvider = await _store.getString(_keyProviderId);
    final apiKey = await _loadApiKey();
    final baseUrlOverride = await _store.getString(_keyBaseUrl);
    final modelOverride = await _store.getString(_keyModel);

    final provider = AiPresetProvider.values.firstWhere(
      (value) => value.name == rawProvider,
      orElse: () => AiPresetProvider.siliconflow,
    );

    return AiSettingsSnapshot(
      presetProvider: provider,
      apiKey: apiKey,
      baseUrlOverride: baseUrlOverride,
      modelOverride: modelOverride,
    );
  }

  Future<void> save(AiSettingsSnapshot settings) async {
    await _store.setString(_keyProviderId, settings.presetProvider.name);
    final secretSupported = await _secretStore.isSupported();
    if (secretSupported) {
      final apiKey = settings.apiKey.trim();
      if (apiKey.isEmpty) {
        await _secretStore.clearApiKey();
      } else {
        await _secretStore.saveApiKey(apiKey);
      }

      // Ensure legacy plaintext API key is removed after secure path save attempt.
      await _store.removeKey(_keyApiKey);
    }

    final baseUrlOverride = settings.baseUrlOverride?.trim();
    if (settings.presetProvider == AiPresetProvider.custom &&
        baseUrlOverride != null &&
        baseUrlOverride.isNotEmpty) {
      await _store.setString(_keyBaseUrl, baseUrlOverride);
    } else {
      await _store.removeKey(_keyBaseUrl);
    }

    final trimmedModelOverride = settings.modelOverride?.trim();
    if (trimmedModelOverride != null && trimmedModelOverride.isNotEmpty) {
      await _store.setString(_keyModel, trimmedModelOverride);
    } else {
      await _store.removeKey(_keyModel);
    }
  }

  Future<String> _loadApiKey() async {
    final secretApiKey = (await _secretStore.loadApiKey())?.trim();
    if (secretApiKey != null && secretApiKey.isNotEmpty) {
      await _store.removeKey(_keyApiKey);
      return secretApiKey;
    }

    final legacyApiKey = (await _store.getString(_keyApiKey))?.trim();
    if (legacyApiKey == null || legacyApiKey.isEmpty) {
      return '';
    }

    final supported = await _secretStore.isSupported();
    if (!supported) {
      return legacyApiKey;
    }

    await _secretStore.saveApiKey(legacyApiKey);
    await _store.removeKey(_keyApiKey);
    return legacyApiKey;
  }
}
