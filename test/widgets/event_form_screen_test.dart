import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:kongo/models/reminder_default_offset.dart';
import 'package:kongo/models/reminder_settings.dart';
import 'package:kongo/providers/event_provider.dart';
import 'package:kongo/providers/tag_provider.dart';
import 'package:kongo/screens/events/event_form_screen.dart';
import 'package:kongo/services/settings_preferences_store.dart';
import 'package:kongo/models/calendar_time_node_settings.dart';

import '../test_helpers/test_app_harness.dart';

class InMemorySettingsPreferencesStore implements SettingsPreferencesStore {
  ReminderSettings _reminderSettings = const ReminderSettings();
  ThemeMode _themeMode = ThemeMode.system;
  CalendarTimeNodeSettings _calendarSettings = const CalendarTimeNodeSettings();
  final Map<String, String> _values = <String, String>{};

  @override
  Future<CalendarTimeNodeSettings> getCalendarTimeNodeSettings() async => _calendarSettings;

  @override
  Future<ReminderSettings> getReminderSettings() async => _reminderSettings;

  @override
  Future<String?> getString(String key) async => _values[key];

  @override
  Future<ThemeMode> getThemeMode() async => _themeMode;

  @override
  Future<void> removeKey(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> setCalendarTimeNodeSettings(CalendarTimeNodeSettings settings) async {
    _calendarSettings = settings;
  }

  @override
  Future<void> setReminderSettings(ReminderSettings settings) async {
    _reminderSettings = settings;
  }

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
  }
}

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxAttempts = 60,
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  fail('Timed out waiting for expected widget');
}

Widget buildEventFormScreen(
  TestAppHarness harness, {
  DateTime? initialStartAt,
  required SettingsPreferencesStore settingsPreferencesStore,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<EventProvider>.value(value: harness.dependencies.eventProvider),
      ChangeNotifierProvider<TagProvider>.value(value: harness.dependencies.tagProvider),
      Provider<SettingsPreferencesStore>.value(value: settingsPreferencesStore),
    ],
    child: MaterialApp(
      home: EventFormScreen(initialStartAt: initialStartAt),
      debugShowCheckedModeBanner: false,
    ),
  );
}

void main() {
  late TestAppHarness harness;
  late InMemorySettingsPreferencesStore settingsPreferencesStore;

  setUp(() async {
    harness = await createTestAppHarness();
    settingsPreferencesStore = InMemorySettingsPreferencesStore();
    await harness.dependencies.eventProvider.loadFormOptions();
    await harness.dependencies.tagProvider.loadTags();
  });

  tearDown(() async {
    await harness.dispose();
  });

  testWidgets('Event form participants use search results instead of rendering the full contact list', (
    WidgetTester tester,
  ) async {
    late String zhangSanId;
    await tester.runAsync(() async {
      final contacts = await harness.dependencies.contactService.getContacts();
      zhangSanId = contacts.firstWhere((contact) => contact.name == '张三').id;
    });

    await tester.pumpWidget(
      buildEventFormScreen(
        harness,
        settingsPreferencesStore: settingsPreferencesStore,
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('eventForm_participantSearchField')));

    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.text('输入关键词或选择分组后，再从结果里添加联系人。'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('eventForm_participantSearchField')),
      '张三',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(Key('eventForm_addParticipant_$zhangSanId')), findsOneWidget);
  });

  testWidgets('Event form can add a participant from search results', (
    WidgetTester tester,
  ) async {
    late String zhangSanId;
    await tester.runAsync(() async {
      final contacts = await harness.dependencies.contactService.getContacts();
      zhangSanId = contacts.firstWhere((contact) => contact.name == '张三').id;
    });

    await tester.pumpWidget(
      buildEventFormScreen(
        harness,
        settingsPreferencesStore: settingsPreferencesStore,
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('eventForm_participantSearchField')));

    await tester.enterText(
      find.byKey(const Key('eventForm_participantSearchField')),
      '138 0000 0001',
    );
    await tester.pumpAndSettle();

    final candidateButton = find.byKey(Key('eventForm_addParticipant_$zhangSanId'));
    expect(candidateButton, findsOneWidget);
    await tester.ensureVisible(candidateButton);
    await tester.pumpAndSettle();
    await tester.tap(candidateButton);
    await tester.pumpAndSettle();

    expect(find.byKey(Key('eventForm_removeParticipant_$zhangSanId')), findsOneWidget);
    expect(find.byKey(Key('eventForm_selectedParticipant_$zhangSanId')), findsOneWidget);
  });

  testWidgets('Event form uses provided initial start time', (
    WidgetTester tester,
  ) async {
    final initialStartAt = DateTime(2026, 3, 26, 14, 0);

    await tester.pumpWidget(
      buildEventFormScreen(
        harness,
        initialStartAt: initialStartAt,
        settingsPreferencesStore: settingsPreferencesStore,
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('eventForm_startDateField')));

    expect(
      find.descendant(
        of: find.byKey(const Key('eventForm_startDateField')),
        matching: find.text('2026-03-26'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('eventForm_startTimeField')),
        matching: find.text('14:00'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Event form applies configured default reminder offset when creating', (
    WidgetTester tester,
  ) async {
    await settingsPreferencesStore.setReminderSettings(
      const ReminderSettings(eventDefaultOffset: ReminderDefaultOffset.hour1),
    );

    final initialStartAt = DateTime(2026, 3, 26, 14, 0);
    await tester.pumpWidget(
      buildEventFormScreen(
        harness,
        initialStartAt: initialStartAt,
        settingsPreferencesStore: settingsPreferencesStore,
      ),
    );

    await pumpUntilFound(tester, find.byKey(const Key('eventForm_startDateField')));
    await pumpUntilFound(tester, find.text('13:00'));

    final switchTile = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, '启用事件提醒'),
    );
    expect(switchTile.value, isTrue);
    expect(find.text('13:00'), findsOneWidget);
  });
}