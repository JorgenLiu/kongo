# AI Infrastructure Implementation Plan

**Goal:** 接入真实 OpenAI 兼容 HTTP provider，支持 API key 持久化，并在设置页暴露 AI 能力配置入口。

**Architecture:** 在现有 `lib/ai/` 骨架（Phase 0 已完整）基础上补充三块：
1. `OpenAiCompatibleProvider` — 实现 `AiProvider` 接口，HTTP POST 到任意 OpenAI 兼容端点
2. `AiConfigStore` — 对 `SettingsPreferencesStore` 的薄包装，读写 AI 配置（providerId、apiKey、baseUrl、model）
3. 设置页 AI 区块 — provider 选择器 + API key 输入框 + 测试连接按钮

API key 以 JSON 形式存储在 `SettingsPreferencesStore`（与其他设置一致，存于用户 app 数据目录）。不引入新的 native 依赖；Keychain 迁移留待后续安全加固任务。

**Tech Stack:** Dart `http`（已在 pubspec.yaml），`SettingsPreferencesStore`（已有），Flutter Material 3

---

## File Map

**Create:**
- `lib/ai/openai_compatible_provider.dart`
- `lib/config/ai_config_store.dart`
- `lib/widgets/settings/ai_settings_section.dart`

**Modify:**
- `lib/services/app_dependencies.dart`
- `lib/screens/settings/settings_overview_screen.dart`

**No new pubspec dependencies** — `http: ^1.3.0` 已存在。

---

## Out of Scope

- 实际调用 AI 能力的功能（秘书简报、关系洞察等）——属于后续功能任务
- Keychain/Credential Store 安全存储——属于后续安全加固任务
- 流式响应（streaming）——`AiProvider` 接口目前为 request/response，保持不变

---

## Tasks

### Task 1: 实现 OpenAiCompatibleProvider

**Files:**
- Create: `lib/ai/openai_compatible_provider.dart`

- [ ] 创建文件，实现 `AiProvider` 接口：

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';

class OpenAiCompatibleProvider implements AiProvider {
  OpenAiCompatibleProvider({
    required AiProviderConfig config,
    http.Client? httpClient,
  })  : _config = config,
        _client = httpClient ?? http.Client();

  final AiProviderConfig _config;
  final http.Client _client;

  @override
  String get name => _config.baseUrl;

  @override
  Future<AiCompletion> complete(List<AiMessage> messages) async {
    final uri = Uri.parse('${_config.baseUrl}/chat/completions');
    final body = jsonEncode({
      'model': _config.defaultModel,
      'messages': messages.map((m) => {'role': m.role, 'content': m.content}).toList(),
    });

    final response = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${_config.apiKey}',
          },
          body: body,
        )
        .timeout(_config.timeout ?? const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw AiProviderException(
        'HTTP ${response.statusCode}: ${response.reasonPhrase}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final content = (json['choices'] as List).first['message']['content'] as String;
    return AiCompletion(content: content);
  }
}
```

> **注意：** `AiProviderException`、`AiCompletion`、`AiMessage` 的实际类名以 `lib/ai/ai_provider.dart` 中的定义为准。读取该文件确认后再写代码。

- [ ] 运行：`source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter analyze lib/ai/`
  - 期望：无错误

---

### Task 2: 实现 AiConfigStore

**Files:**
- Create: `lib/config/ai_config_store.dart`

- [ ] 创建文件：

```dart
import '../services/settings_preferences_store.dart';

/// 预置 Provider 的标识符
enum AiPresetProvider {
  siliconflow,
  deepseek,
  qwen,
  custom,
}

class AiPreset {
  const AiPreset({required this.label, required this.baseUrl, required this.defaultModel});
  final String label;
  final String baseUrl;
  final String defaultModel;
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

class AiConfigStore {
  AiConfigStore(this._store);

  final SettingsPreferencesStore _store;

  static const _keyProviderId = 'ai_provider_id';
  static const _keyApiKey = 'ai_api_key';
  static const _keyBaseUrl = 'ai_base_url';
  static const _keyModel = 'ai_model';

  Future<AiPresetProvider> getPresetProvider() async {
    final raw = await _store.getString(_keyProviderId);
    return AiPresetProvider.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => AiPresetProvider.siliconflow,
    );
  }

  Future<String> getApiKey() async => await _store.getString(_keyApiKey) ?? '';

  Future<String?> getBaseUrlOverride() => _store.getString(_keyBaseUrl);

  Future<String?> getModelOverride() => _store.getString(_keyModel);

  Future<void> save({
    required AiPresetProvider presetProvider,
    required String apiKey,
    String? baseUrlOverride,
    String? modelOverride,
  }) async {
    await _store.setString(_keyProviderId, presetProvider.name);
    await _store.setString(_keyApiKey, apiKey);
    if (baseUrlOverride != null && baseUrlOverride.isNotEmpty) {
      await _store.setString(_keyBaseUrl, baseUrlOverride);
    } else {
      await _store.removeKey(_keyBaseUrl);
    }
    if (modelOverride != null && modelOverride.isNotEmpty) {
      await _store.setString(_keyModel, modelOverride);
    } else {
      await _store.removeKey(_keyModel);
    }
  }
}
```

> **注意：** `SettingsPreferencesStore` 的实际 API（`getString`、`setString`、`removeKey`）以 `lib/services/settings_preferences_store.dart` 中的定义为准。读取该文件确认方法签名后再写代码，必要时按实际 API 调整。

- [ ] 运行：`source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter analyze lib/config/`
  - 期望：无错误

---

### Task 3: 更新 AppDependencies

**Files:**
- Modify: `lib/services/app_dependencies.dart`

- [ ] 在 `bootstrap()` 中 `final aiService = ...` 行之前，添加 AI provider 构建逻辑：

```dart
// 从设置中读取 AI 配置，若已配置则初始化 provider
final aiConfigStore = AiConfigStore(settingsPreferencesStore);
final savedApiKey = await aiConfigStore.getApiKey();
final resolvedAiProvider = aiProvider ?? (savedApiKey.isNotEmpty
    ? await _buildAiProvider(aiConfigStore)
    : null);

final aiService = DefaultAiService(provider: resolvedAiProvider, aiJobRepository: aiJobRepository);
```

- [ ] 在文件底部（类外）添加辅助函数：

```dart
Future<AiProvider?> _buildAiProvider(AiConfigStore store) async {
  final preset = await store.getPresetProvider();
  final apiKey = await store.getApiKey();
  if (apiKey.isEmpty) return null;

  final presetData = kAiPresets[preset]!;
  final baseUrlOverride = await store.getBaseUrlOverride();
  final modelOverride = await store.getModelOverride();

  return OpenAiCompatibleProvider(
    config: AiProviderConfig(
      apiKey: apiKey,
      baseUrl: (preset == AiPresetProvider.custom && baseUrlOverride != null)
          ? baseUrlOverride
          : presetData.baseUrl,
      defaultModel: modelOverride ?? presetData.defaultModel,
    ),
  );
}
```

- [ ] 添加必要的 import：`ai_config_store.dart`、`openai_compatible_provider.dart`
- [ ] 保留原有 `AiProvider? aiProvider` 参数不变（测试注入路径不变）
- [ ] 运行：`source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter analyze lib/services/`

---

### Task 4: 创建 AI 设置 Widget

**Files:**
- Create: `lib/widgets/settings/ai_settings_section.dart`

- [ ] 创建 StatefulWidget `AiSettingsSection`，包含：
  - **Provider 下拉选择**：`DropdownMenu<AiPresetProvider>`，选项来自 `kAiPresets`
  - **API Key 输入**：`TextField`，`obscureText: true`，标签"API Key"
  - **自定义 URL（条件显示）**：仅在选择"自定义"时显示，标签"API Base URL"
  - **模型覆盖**：`TextField`，标签"模型（可选，留空使用默认）"
  - **保存按钮**：调用 `AiConfigStore.save()`，成功后显示 SnackBar "已保存"
  - **测试连接按钮**：构造临时 `OpenAiCompatibleProvider`，发送简单 ping（`[AiMessage(role: 'user', content: 'hi')]`），成功显示 "连接成功"，失败显示错误信息

- [ ] Widget 通过 `Provider.of<AiService>` 获取 `AiService`（已在 Provider tree），`AiConfigStore` 通过构造函数注入或 `Provider.of<AppDependencies>`（以实际接入方式为准）

- [ ] 运行：`source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter analyze lib/widgets/settings/`

---

### Task 5: 在设置页插入 AI 区块

**Files:**
- Modify: `lib/screens/settings/settings_overview_screen.dart`

- [ ] 在 `偏好设置` 区块之后、`数据管理` 区块之前，插入：

```dart
const SizedBox(height: AppSpacing.xl),
// ── AI 能力 ──
_SectionHeader(icon: Icons.psychology_outlined, label: 'AI 能力'),
const SizedBox(height: AppSpacing.sm),
const AiSettingsSection(),
```

- [ ] 添加 import：`'../../widgets/settings/ai_settings_section.dart'`

---

### Task 6: 全量验证

- [ ] 运行：`source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter analyze`
  - 期望：无错误或警告
- [ ] 运行：`source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter test`
  - 期望：全部通过（无新增破坏性变更）
- [ ] 手动验证（可选）：打开设置页，确认 AI 能力区块正常渲染，输入 API key 后可保存，重启 app 后配置持久化
