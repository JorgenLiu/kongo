import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kongo/services/app_dependencies.dart';
import 'package:kongo/services/ai_secret_store.dart';
import 'package:kongo/services/attachment_preview_service.dart';
import 'package:kongo/services/database_service.dart';
import 'package:kongo/services/reminder_interaction_service.dart';
import 'package:kongo/services/reminder_platform_gateway.dart';

import 'test_fixture_data.dart';

class TestAppHarness {
  final AppDependencies dependencies;
  final Directory? settingsDirectory;

  TestAppHarness(this.dependencies, {this.settingsDirectory});

  Future<void> dispose() async {
    if (settingsDirectory != null && await settingsDirectory!.exists()) {
      await settingsDirectory!.delete(recursive: true);
    }
    await dependencies.dispose(deleteDatabase: true);
  }
}

bool _sqfliteFfiInitialized = false;

Future<TestAppHarness> createTestAppHarness() async {
  return createTestAppHarnessWithOptions();
}

Future<TestAppHarness> createTestAppHarnessWithOptions({
  Future<Directory> Function()? attachmentsDirectoryResolver,
  Future<Directory> Function()? attachmentPreviewsDirectoryResolver,
  AttachmentPreviewGenerator? attachmentPreviewGenerator,
  ReminderPlatformGateway? reminderPlatformGateway,
  ReminderInteractionService? reminderInteractionService,
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (!_sqfliteFfiInitialized) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _sqfliteFfiInitialized = true;
  }

  final databaseService = DatabaseService(
    databaseFileName: 'kongo_test_${DateTime.now().microsecondsSinceEpoch}.db',
  );
  final settingsDirectory = await Directory.systemTemp.createTemp(
    'kongo_settings_test_',
  );

  final dependencies = await AppDependencies.bootstrap(
    databaseService: databaseService,
    preloadContacts: false,
    enableFilesPreviewWarmup: false,
    attachmentsDirectoryResolver: attachmentsDirectoryResolver,
    attachmentPreviewsDirectoryResolver: attachmentPreviewsDirectoryResolver,
    settingsDirectoryResolver: () async => settingsDirectory,
    attachmentPreviewGenerator: attachmentPreviewGenerator ??
        ({
          required attachment,
          required sourcePath,
          required previewsDirectory,
        }) async => null,
      aiSecretStore: UnsupportedAiSecretStore(),
    reminderPlatformGateway: reminderPlatformGateway ?? UnsupportedReminderPlatformGateway(),
    reminderInteractionService: reminderInteractionService,
  );

  await seedTestFixtureData(dependencies);

  return TestAppHarness(dependencies, settingsDirectory: settingsDirectory);
}