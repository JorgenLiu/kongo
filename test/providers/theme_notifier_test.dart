import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/providers/theme_notifier.dart';

import '../test_helpers/test_app_harness.dart';

void main() {
  late TestAppHarness harness;

  setUp(() async {
    harness = await createTestAppHarness();
  });

  tearDown(() async {
    await harness.dispose();
  });

  test('ThemeNotifier persists selected theme mode to JSON settings', () async {
    final firstNotifier = ThemeNotifier(harness.dependencies.settingsPreferencesStore);
    await firstNotifier.ready;

    await firstNotifier.setMode(ThemeMode.dark);
    expect(firstNotifier.mode, ThemeMode.dark);

    final secondNotifier = ThemeNotifier(harness.dependencies.settingsPreferencesStore);
    await secondNotifier.ready;

    expect(secondNotifier.mode, ThemeMode.dark);

    firstNotifier.dispose();
    secondNotifier.dispose();
  });
}