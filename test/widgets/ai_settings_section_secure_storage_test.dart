import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:kongo/config/ai_config_store.dart';
import 'package:kongo/models/calendar_time_node_settings.dart';
import 'package:kongo/models/reminder_settings.dart';
import 'package:kongo/services/ai_secret_store.dart';
import 'package:kongo/services/settings_preferences_store.dart';
import 'package:kongo/widgets/settings/ai_settings_section.dart';

void main() {
  testWidgets('saved API key is not echoed and can be cleared', (WidgetTester tester) async {
    final configStore = _FakeAiConfigStore(
      initialSnapshot: const AiSettingsSnapshot(
        presetProvider: AiPresetProvider.deepseek,
        apiKey: 'sk-existing',
      ),
    );
    final secretStore = _FakeAiSecretStore(apiKey: 'sk-existing', supported: true);

    await _pumpSection(
      tester,
      configStore: configStore,
      secretStore: secretStore,
    );

    expect(_textFieldValue(tester, 'aiSettingsApiKeyField'), '');
    expect(find.text('已保存 API key（不会回显完整内容）'), findsOneWidget);

    await tester.tap(find.byKey(const Key('aiSettingsClearApiKeyButton')));
    await tester.pumpAndSettle();

    expect(secretStore.apiKey, isNull);
    expect(find.text('未保存 API key'), findsOneWidget);
  });

  testWidgets('unsupported platform shows hint and disables key actions', (
    WidgetTester tester,
  ) async {
    final configStore = _FakeAiConfigStore(
      initialSnapshot: const AiSettingsSnapshot(
        presetProvider: AiPresetProvider.siliconflow,
        apiKey: '',
      ),
    );
    final secretStore = _FakeAiSecretStore(supported: false);

    await _pumpSection(
      tester,
      configStore: configStore,
      secretStore: secretStore,
    );

    expect(find.byKey(const Key('aiSettingsApiKeyUnsupportedHint')), findsOneWidget);

    final apiField = tester.widget<TextField>(find.byKey(const Key('aiSettingsApiKeyField')));
    expect(apiField.enabled, isFalse);

    final clearButton = tester.widget<OutlinedButton>(
      find.byKey(const Key('aiSettingsClearApiKeyButton')),
    );
    expect(clearButton.onPressed, isNull);
  });

  testWidgets('save uses cached key when user keeps key input empty', (
    WidgetTester tester,
  ) async {
    final configStore = _FakeAiConfigStore(
      initialSnapshot: const AiSettingsSnapshot(
        presetProvider: AiPresetProvider.deepseek,
        apiKey: 'sk-existing',
      ),
    );
    final secretStore = _FakeAiSecretStore(apiKey: 'sk-existing', supported: true);

    await _pumpSection(
      tester,
      configStore: configStore,
      secretStore: secretStore,
    );

    await tester.enterText(find.byKey(const Key('aiSettingsModelField')), 'deepseek-reasoner');
    await tester.pump();

    await tester.tap(find.byKey(const Key('aiSettingsSaveButton')));
    await tester.pumpAndSettle();

    expect(configStore.savedSnapshots, hasLength(1));
    expect(configStore.savedSnapshots.single.apiKey, 'sk-existing');
  });
}

Future<void> _pumpSection(
  WidgetTester tester, {
  required _FakeAiConfigStore configStore,
  required _FakeAiSecretStore secretStore,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<AiConfigStore>.value(value: configStore),
        Provider<AiSecretStore>.value(value: secretStore),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: AiSettingsSection(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _textFieldValue(WidgetTester tester, String keyValue) {
  final field = tester.widget<TextField>(find.byKey(Key(keyValue)));
  return field.controller!.text;
}

class _FakeAiConfigStore extends AiConfigStore {
  AiSettingsSnapshot currentSnapshot;
  final List<AiSettingsSnapshot> savedSnapshots = [];

  _FakeAiConfigStore({
    required AiSettingsSnapshot initialSnapshot,
  }) : currentSnapshot = initialSnapshot,
       super(_NoopSettingsPreferencesStore());

  @override
  Future<AiSettingsSnapshot> load() async {
    return currentSnapshot;
  }

  @override
  Future<void> save(AiSettingsSnapshot settings) async {
    savedSnapshots.add(settings);
    currentSnapshot = settings;
  }
}

class _FakeAiSecretStore implements AiSecretStore {
  String? apiKey;
  bool supported;

  _FakeAiSecretStore({
    this.apiKey,
    required this.supported,
  });

  @override
  Future<void> clearApiKey() async {
    apiKey = null;
  }

  @override
  Future<bool> isSupported() async {
    return supported;
  }

  @override
  Future<String?> loadApiKey() async {
    return apiKey;
  }

  @override
  Future<void> saveApiKey(String value) async {
    apiKey = value;
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
