import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kongo/services/migrations/database_migrations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('migrateToVersion9 should skip deletedAt when column already exists', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('CREATE TABLE contacts (id TEXT PRIMARY KEY, deletedAt INTEGER)');
        await db.execute('CREATE TABLE tags (id TEXT PRIMARY KEY)');
        await db.execute('CREATE TABLE events (id TEXT PRIMARY KEY)');
        await db.execute('CREATE TABLE daily_summaries (id TEXT PRIMARY KEY)');
        await db.execute('CREATE TABLE attachments (id TEXT PRIMARY KEY)');
        await db.execute('CREATE TABLE contact_milestones (id TEXT PRIMARY KEY)');
        await db.execute('CREATE TABLE todo_groups (id TEXT PRIMARY KEY)');
        await db.execute('CREATE TABLE todo_items (id TEXT PRIMARY KEY)');
      },
    );

    addTearDown(() async {
      await db.close();
    });

    await migrateToVersion9(db);

    final checks = <String, Future<bool>>{
      'contacts': _hasDeletedAt(db, 'contacts'),
      'tags': _hasDeletedAt(db, 'tags'),
      'events': _hasDeletedAt(db, 'events'),
      'daily_summaries': _hasDeletedAt(db, 'daily_summaries'),
      'attachments': _hasDeletedAt(db, 'attachments'),
      'contact_milestones': _hasDeletedAt(db, 'contact_milestones'),
      'todo_groups': _hasDeletedAt(db, 'todo_groups'),
      'todo_items': _hasDeletedAt(db, 'todo_items'),
    };

    for (final entry in checks.entries) {
      expect(await entry.value, isTrue, reason: '${entry.key} should contain deletedAt');
    }
  });
}

Future<bool> _hasDeletedAt(Database db, String table) async {
  final columns = await db.rawQuery('PRAGMA table_info($table)');
  return columns.any((column) => column['name'] == 'deletedAt');
}