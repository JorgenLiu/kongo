import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kongo/services/app_dependencies.dart';
import 'package:kongo/services/database_service.dart';

import 'test_fixture_data.dart';

class TestAppHarness {
  final AppDependencies dependencies;

  TestAppHarness(this.dependencies);

  Future<void> dispose() async {
    await dependencies.dispose(deleteDatabase: true);
  }
}

bool _sqfliteFfiInitialized = false;

Future<TestAppHarness> createTestAppHarness() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (!_sqfliteFfiInitialized) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _sqfliteFfiInitialized = true;
  }

  final databaseService = DatabaseService(
    databaseFileName: 'kongo_test_${DateTime.now().microsecondsSinceEpoch}.db',
  );

  final dependencies = await AppDependencies.bootstrap(
    databaseService: databaseService,
    preloadContacts: false,
  );

  await seedTestFixtureData(dependencies);

  return TestAppHarness(dependencies);
}