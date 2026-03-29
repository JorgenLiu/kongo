import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:kongo/ai/ai_provider.dart';
import 'package:kongo/config/ai_config_store.dart';
import 'package:kongo/exceptions/app_exception.dart';
import 'package:kongo/models/calendar_time_node_settings.dart';
import 'package:kongo/models/reminder_settings.dart';
import 'package:kongo/services/ai_secret_store.dart';
import 'package:kongo/services/settings_preferences_store.dart';
import 'package:kongo/widgets/settings/ai_settings_section.dart';

void main() {
  testWidgets('loads existing settings into form fields', (WidgetTester tester) async {
    final store = _FakeAiConfigStore(
      initialSnapshot: const AiSettingsSnapshot(
        presetProvider: AiPresetProvider.custom,
        apiKey: 'sk-existing',
        baseUrlOverride: 'https://example.com/v1',
        modelOverride: 'custom-model',
      ),
    );

    await _pumpSection(tester, store: store);

    expect(_textFieldValue(tester, 'aiSettingsApiKeyField'), '');
    expect(_textFieldValue(tester, 'aiSettingsBaseUrlField'), 'https://example.com/v1');
    expect(_textFieldValue(tester, 'aiSettingsModelField'), 'custom-model');
    expect(find.text('已保存 API key（不会回显完整内容）'), findsOneWidget);
    expect(find.text('自定义模式需要手动填写 Base URL 和模型名。'), findsOneWidget);
  });

  testWidgets('switching preset updates helper text and preset values', (WidgetTester tester) async {
    final store = _FakeAiConfigStore();

    await _pumpSection(tester, store: store);

    await tester.tap(find.byKey(const Key('aiSettingsProviderField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DeepSeek 官方').last);
    await tester.pumpAndSettle();

    expect(find.text('当前预设默认地址：https://api.deepseek.com/v1'), findsOneWidget);
    expect(_textFieldValue(tester, 'aiSettingsBaseUrlField'), 'https://api.deepseek.com/v1');
    expect(_textFieldValue(tester, 'aiSettingsModelField'), 'deepseek-chat');
  });

  testWidgets('save shows validation message when configuration is incomplete', (
    WidgetTester tester,
  ) async {
    final store = _FakeAiConfigStore();

    await _pumpSection(tester, store: store);

    await tester.tap(find.byKey(const Key('aiSettingsSaveButton')));
    await tester.pump();

    expect(find.text('请先填写完整的 AI 配置'), findsOneWidget);
    expect(store.savedSnapshots, isEmpty);
  });

  testWidgets('save persists complete configuration and shows success message', (
    WidgetTester tester,
  ) async {
    final store = _FakeAiConfigStore();

    await _pumpSection(tester, store: store);
    await _enterValidPresetConfiguration(tester);

    await tester.tap(find.byKey(const Key('aiSettingsSaveButton')));
    await tester.pumpAndSettle();

    expect(find.text('AI 配置已保存'), findsOneWidget);
    expect(store.savedSnapshots, hasLength(1));
    final saved = store.savedSnapshots.single;
    expect(saved.presetProvider, AiPresetProvider.siliconflow);
    expect(saved.apiKey, 'sk-valid');
    expect(saved.baseUrlOverride, isNull);
    expect(saved.modelOverride, 'custom-siliconflow-model');
  });

  testWidgets('save failure shows error message', (WidgetTester tester) async {
    final store = _FakeAiConfigStore(saveError: Exception('disk full'));

    await _pumpSection(tester, store: store);
    await _enterValidPresetConfiguration(tester);

    await tester.tap(find.byKey(const Key('aiSettingsSaveButton')));
    await tester.pumpAndSettle();

    expect(find.text('AI 配置保存失败，请稍后重试'), findsOneWidget);
  });

  testWidgets('test connection shows validation message when configuration is incomplete', (
    WidgetTester tester,
  ) async {
    final store = _FakeAiConfigStore();

    await _pumpSection(
      tester,
      store: store,
      connectionProviderFactory: ({required providerId, required config}) => _FakeAiProvider(),
    );

    await tester.tap(find.byKey(const Key('aiSettingsTestConnectionButton')));
    await tester.pump();

    expect(find.text('请先填写完整的 AI 配置'), findsOneWidget);
  });

  testWidgets('test connection uses injected provider and shows success message', (
    WidgetTester tester,
  ) async {
    final store = _FakeAiConfigStore();
    _FakeAiProvider? provider;
    String? capturedProviderId;
    AiProviderConfig? capturedConfig;

    await _pumpSection(
      tester,
      store: store,
      connectionProviderFactory: ({required providerId, required config}) {
        provider = _FakeAiProvider();
        capturedProviderId = providerId;
        capturedConfig = config;
        return provider!;
      },
    );
    await _enterValidPresetConfiguration(tester);

    await tester.tap(find.byKey(const Key('aiSettingsTestConnectionButton')));
    await tester.pumpAndSettle();

    expect(find.text('连接测试成功'), findsOneWidget);
    expect(capturedProviderId, 'siliconflow');
    expect(capturedConfig, isNotNull);
    expect(capturedConfig!.apiKey, 'sk-valid');
    expect(capturedConfig!.baseUrl, kAiPresets[AiPresetProvider.siliconflow]!.baseUrl);
    expect(capturedConfig!.defaultModel, 'custom-siliconflow-model');
    expect(provider, isNotNull);
    expect(provider!.lastMessages, hasLength(1));
    expect(provider!.lastMessages!.single.role, 'user');
    expect(provider!.lastMessages!.single.content, '请只回复 OK');
    expect(provider!.disposeCalled, isTrue);
  });

  testWidgets('test connection failure shows provider error message', (WidgetTester tester) async {
    final store = _FakeAiConfigStore();

    await _pumpSection(
      tester,
      store: store,
      connectionProviderFactory: ({required providerId, required config}) =>
          _FakeAiProvider(error: const AiException(message: 'network unreachable')),
    );
    await _enterValidPresetConfiguration(tester);

    await tester.tap(find.byKey(const Key('aiSettingsTestConnectionButton')));
    await tester.pumpAndSettle();

    expect(find.text('连接测试失败：network unreachable'), findsOneWidget);
  });
}

Future<void> _pumpSection(
  WidgetTester tester, {
  required AiConfigStore store,
  AiSecretStore? secretStore,
  AiConnectionProviderFactory? connectionProviderFactory,
}) async {
  final resolvedSecretStore = secretStore ?? _FakeAiSecretStore();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<AiConfigStore>.value(value: store),
        Provider<AiSecretStore>.value(value: resolvedSecretStore),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: AiSettingsSection(
            connectionProviderFactory: connectionProviderFactory,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _enterValidPresetConfiguration(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('aiSettingsApiKeyField')), 'sk-valid');
  await tester.enterText(
    find.byKey(const Key('aiSettingsModelField')),
    'custom-siliconflow-model',
  );
  await tester.pump();
}

String _textFieldValue(WidgetTester tester, String keyValue) {
  final field = tester.widget<TextField>(find.byKey(Key(keyValue)));
  return field.controller!.text;
}

class _FakeAiProvider implements AiProvider {
  final AiException? error;
  List<AiMessage>? lastMessages;
  bool disposeCalled = false;

  _FakeAiProvider({this.error});

  @override
  String get providerId => 'fake-provider';

  @override
  Future<AiCompletion> complete({required List<AiMessage> messages, String? model}) async {
    lastMessages = messages;
    if (error != null) {
      throw error!;
    }
    return const AiCompletion(content: 'OK');
  }

  @override
  void dispose() {
    disposeCalled = true;
  }
}

class _FakeAiConfigStore extends AiConfigStore {
  AiSettingsSnapshot currentSnapshot;
  final Exception? saveError;
  final List<AiSettingsSnapshot> savedSnapshots = [];

  _FakeAiConfigStore({
    AiSettingsSnapshot? initialSnapshot,
    this.saveError,
  }) : currentSnapshot = initialSnapshot ??
            const AiSettingsSnapshot(
              presetProvider: AiPresetProvider.siliconflow,
              apiKey: '',
            ),
       super(_NoopSettingsPreferencesStore());

  @override
  Future<AiSettingsSnapshot> load() async {
    return currentSnapshot;
  }

  @override
  Future<void> save(AiSettingsSnapshot settings) async {
    if (saveError != null) {
      throw saveError!;
    }
    savedSnapshots.add(settings);
    currentSnapshot = settings;
  }
}

class _NoopSettingsPreferencesStore implements SettingsPreferencesStore {
  @override
  Future<CalendarTimeNodeSettings> getCalendarTimeNodeSettings() {
    throw UnimplementedError();
  }

  @override
  Future<String?> getString(String key) async => null;

  @override
  Future<ReminderSettings> getReminderSettings() {
    throw UnimplementedError();
  }

  @override
  Future<ThemeMode> getThemeMode() {
    throw UnimplementedError();
  }

  @override
  Future<void> removeKey(String key) async {}

  @override
  Future<void> setCalendarTimeNodeSettings(CalendarTimeNodeSettings settings) {
    throw UnimplementedError();
  }

  @override
  Future<void> setReminderSettings(ReminderSettings settings) {
    throw UnimplementedError();
  }

  @override
  Future<void> setString(String key, String value) async {}

  @override
  Future<void> setThemeMode(ThemeMode mode) {
    throw UnimplementedError();
  }
}

class _FakeAiSecretStore implements AiSecretStore {
  _FakeAiSecretStore();

  @override
  Future<void> clearApiKey() async {}

  @override
  Future<bool> isSupported() async {
    return true;
  }

  @override
  Future<String?> loadApiKey() async {
    return null;
  }

  @override
  Future<void> saveApiKey(String value) async {}
}