import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../ai/ai_provider.dart';
import '../../ai/openai_compatible_provider.dart';
import '../../config/ai_config_store.dart';
import '../../config/app_constants.dart';
import '../../services/ai_secret_store.dart';

/// 为“测试连接”动作构建一次性 provider。
///
/// 默认使用真实的 `OpenAiCompatibleProvider`，测试中可注入 fake，
/// 以避免 widget 测试依赖真实网络请求。
typedef AiConnectionProviderFactory = AiProvider Function({
  required String providerId,
  required AiProviderConfig config,
});

class AiSettingsSection extends StatefulWidget {
  const AiSettingsSection({
    super.key,
    AiConnectionProviderFactory? connectionProviderFactory,
  }) : connectionProviderFactory =
           connectionProviderFactory ?? _buildDefaultConnectionProvider;

  final AiConnectionProviderFactory connectionProviderFactory;

  @override
  State<AiSettingsSection> createState() => _AiSettingsSectionState();
}

AiProvider _buildDefaultConnectionProvider({
  required String providerId,
  required AiProviderConfig config,
}) {
  return OpenAiCompatibleProvider(
    providerId: providerId,
    config: config,
  );
}

class _AiSettingsSectionState extends State<AiSettingsSection> {
  late final TextEditingController _apiKeyController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _modelController;

  AiPresetProvider _selectedPreset = AiPresetProvider.siliconflow;
  bool _loading = true;
  bool _saving = false;
  bool _testing = false;
  bool _clearingKey = false;
  bool _apiKeySaved = false;
  bool _secretSupported = true;
  String _cachedApiKey = '';

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    _baseUrlController = TextEditingController();
    _modelController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final preset = kAiPresets[_selectedPreset]!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_outlined, size: 20, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'AI 能力',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '配置 OpenAI 兼容接口，用于后续秘书简报、关系洞察和文档增强能力。',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<AiPresetProvider>(
              key: const Key('aiSettingsProviderField'),
              isExpanded: true,
              initialValue: _selectedPreset,
              decoration: const InputDecoration(
                labelText: '服务提供商',
                border: OutlineInputBorder(),
              ),
              items: AiPresetProvider.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(kAiPresets[value]!.label),
                    ),
                  )
                  .toList(),
              onChanged: _loading ? null : _handlePresetChanged,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('aiSettingsApiKeyField'),
              controller: _apiKeyController,
              enabled: !_loading && _secretSupported,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: _apiKeySaved ? '输入新 key 将覆盖已保存密钥' : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _apiKeySaved ? '已保存 API key（不会回显完整内容）' : '未保存 API key',
              key: const Key('aiSettingsApiKeyStatusLabel'),
              style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
            if (!_secretSupported) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '当前平台暂不支持安全存储，API key 保存能力已禁用。',
                key: const Key('aiSettingsApiKeyUnsupportedHint'),
                style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('aiSettingsBaseUrlField'),
              controller: _baseUrlController,
              enabled: !_loading && _selectedPreset == AiPresetProvider.custom,
              decoration: InputDecoration(
                labelText: 'Base URL',
                hintText: _selectedPreset == AiPresetProvider.custom ? 'https://example.com/v1' : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('aiSettingsModelField'),
              controller: _modelController,
              enabled: !_loading,
              decoration: InputDecoration(
                labelText: '模型',
                hintText: preset.defaultModel.isEmpty ? '请输入模型名' : preset.defaultModel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _selectedPreset == AiPresetProvider.custom
                  ? '自定义模式需要手动填写 Base URL 和模型名。'
                  : '当前预设默认地址：${preset.baseUrl}',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                FilledButton.tonalIcon(
                  key: const Key('aiSettingsTestConnectionButton'),
                  onPressed: _testing || _saving || _clearingKey || _loading
                    ? null
                    : _handleTestConnection,
                  icon: _testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering_outlined),
                  label: Text(_testing ? '测试中...' : '测试连接'),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton.icon(
                  key: const Key('aiSettingsSaveButton'),
                  onPressed: _saving || _testing || _clearingKey || _loading
                    ? null
                    : _handleSave,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? '保存中...' : '保存配置'),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton.icon(
                  key: const Key('aiSettingsClearApiKeyButton'),
                  onPressed: _clearingKey || _saving || _testing || _loading || !_apiKeySaved || !_secretSupported
                      ? null
                      : _handleClearSavedApiKey,
                  icon: _clearingKey
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.key_off_outlined),
                  label: const Text('清除已保存密钥'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '配置保存后将在下次启动时自动接入 AI 服务；连接测试立即生效。',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSettings() async {
    final store = context.read<AiConfigStore>();
    final secretStore = context.read<AiSecretStore>();
    final settings = await store.load();
    bool secretSupported;
    try {
      secretSupported = await secretStore.isSupported();
    } catch (_) {
      secretSupported = false;
    }

    final savedApiKey = settings.apiKey.trim();
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedPreset = settings.presetProvider;
      _secretSupported = secretSupported;
      _cachedApiKey = savedApiKey;
      _apiKeySaved = savedApiKey.isNotEmpty;
      _apiKeyController.clear();
      _baseUrlController.text = settings.resolvedBaseUrl;
      _modelController.text = settings.resolvedModel;
      _loading = false;
    });
  }

  void _handlePresetChanged(AiPresetProvider? nextPreset) {
    if (nextPreset == null) {
      return;
    }

    final previousPreset = kAiPresets[_selectedPreset]!;
    final nextPresetData = kAiPresets[nextPreset]!;
    final currentBaseUrl = _baseUrlController.text.trim();
    final currentModel = _modelController.text.trim();

    setState(() {
      _selectedPreset = nextPreset;

      if (nextPreset == AiPresetProvider.custom) {
        if (currentBaseUrl == previousPreset.baseUrl) {
          _baseUrlController.clear();
        }
        if (currentModel == previousPreset.defaultModel) {
          _modelController.clear();
        }
      } else {
        _baseUrlController.text = nextPresetData.baseUrl;
        if (currentModel.isEmpty || currentModel == previousPreset.defaultModel) {
          _modelController.text = nextPresetData.defaultModel;
        }
      }
    });
  }

  Future<void> _handleTestConnection() async {
    final resolvedApiKey = _resolveApiKeyForRuntime();
    final tempSettings = _buildSnapshotFromForm(apiKey: resolvedApiKey);
    final providerConfig = tempSettings.toProviderConfig();
    if (providerConfig == null) {
      _showSnackBar('请先填写完整的 AI 配置');
      return;
    }

    setState(() {
      _testing = true;
    });

    final provider = widget.connectionProviderFactory(
      providerId: tempSettings.presetProvider.name,
      config: providerConfig,
    );

    try {
      await provider.complete(
        messages: const [AiMessage.user('请只回复 OK')],
      );
      _showSnackBar('连接测试成功');
    } catch (error) {
      _showSnackBar('连接测试失败：$error');
    } finally {
      provider.dispose();
      if (mounted) {
        setState(() {
          _testing = false;
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_secretSupported && _apiKeyController.text.trim().isNotEmpty) {
      _showSnackBar('当前平台不支持安全存储，无法保存 API key');
      return;
    }

    final resolvedApiKey = _resolveApiKeyForSave();
    final snapshot = _buildSnapshotFromForm(apiKey: resolvedApiKey);
    if (snapshot.toProviderConfig() == null) {
      _showSnackBar('请先填写完整的 AI 配置');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await context.read<AiConfigStore>().save(snapshot);

      final typedApiKey = _apiKeyController.text.trim();
      if (_secretSupported && typedApiKey.isNotEmpty) {
        _cachedApiKey = typedApiKey;
        _apiKeySaved = true;
        _apiKeyController.clear();
      }

      _showSnackBar(
        _secretSupported ? 'AI 配置已保存' : '配置已保存（当前平台不支持 API key 安全保存）',
      );
    } catch (_) {
      _showSnackBar('AI 配置保存失败，请稍后重试');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _handleClearSavedApiKey() async {
    setState(() {
      _clearingKey = true;
    });

    try {
      await context.read<AiSecretStore>().clearApiKey();
      _cachedApiKey = '';
      _apiKeySaved = false;
      _apiKeyController.clear();
      _showSnackBar('已清除保存的 API key');
    } catch (_) {
      _showSnackBar('清除密钥失败，请稍后重试');
    } finally {
      if (mounted) {
        setState(() {
          _clearingKey = false;
        });
      }
    }
  }

  AiSettingsSnapshot _buildSnapshotFromForm({required String apiKey}) {
    final preset = kAiPresets[_selectedPreset]!;
    final trimmedModel = _modelController.text.trim();

    return AiSettingsSnapshot(
      presetProvider: _selectedPreset,
      apiKey: apiKey,
      baseUrlOverride: _selectedPreset == AiPresetProvider.custom
          ? _baseUrlController.text.trim()
          : null,
      modelOverride: trimmedModel.isEmpty || trimmedModel == preset.defaultModel
          ? null
          : trimmedModel,
    );
  }

  String _resolveApiKeyForRuntime() {
    final typedApiKey = _apiKeyController.text.trim();
    if (typedApiKey.isNotEmpty) {
      return typedApiKey;
    }

    return _cachedApiKey;
  }

  String _resolveApiKeyForSave() {
    if (!_secretSupported) {
      return _cachedApiKey;
    }

    return _resolveApiKeyForRuntime();
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}