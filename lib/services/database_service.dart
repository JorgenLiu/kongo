import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'migrations/database_migrations.dart' as migrations;

/// SQLite 数据库服务，负责建表、迁移与预置数据初始化。
class DatabaseService {
  DatabaseService._internal({
    String databaseFileName = defaultDatabaseFileName,
  }) : _databaseFileName = databaseFileName;

  static final DatabaseService instance = DatabaseService._internal();
  Database? _database;

  static const String defaultDatabaseFileName = 'kongo.db';
  static const int databaseVersion = 10;
  static const String contactMilestonesTable = 'contact_milestones';
  static const String appPreferencesTable = 'app_preferences';
  static const String todoGroupsTable = 'todo_groups';
  static const String todoItemsTable = 'todo_items';
  static const String todoItemContactsTable = 'todo_item_contacts';
  static const String todoItemEventsTable = 'todo_item_events';
  static const String quickNotesTable = 'quick_notes';
  final String _databaseFileName;

  static const String contactsTable = 'contacts';
  static const String tagsTable = 'tags';
  static const String contactTagsTable = 'contact_tags';
  static const String eventTypesTable = 'event_types';
  static const String eventsTable = 'events';
  static const String eventParticipantsTable = 'event_participants';
  static const String eventSummariesTable = 'event_summaries';
  static const String summariesTable = 'daily_summaries';
  static const String attachmentsTable = 'attachments';
  static const String attachmentLinksTable = 'attachment_links';
  static const String aiJobsTable = 'ai_jobs';
  static const String aiOutputsTable = 'ai_outputs';

  factory DatabaseService({
    String databaseFileName = defaultDatabaseFileName,
  }) {
    if (databaseFileName == defaultDatabaseFileName) {
      return instance;
    }

    return DatabaseService._internal(databaseFileName: databaseFileName);
  }

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    return database;
  }

  Future<void> closeDatabase() async {
    if (_database == null) {
      return;
    }

    await _database!.close();
    _database = null;
  }

  Future<void> deleteDatabaseFile() async {
    await closeDatabase();
    final databasePath = path.join(await getDatabasesPath(), _databaseFileName);
    await deleteDatabase(databasePath);
  }

  Future<Database> _openDatabase() async {
    final databasePath = path.join(await getDatabasesPath(), _databaseFileName);

    return openDatabase(
      databasePath,
      version: databaseVersion,
      onConfigure: _onConfigure,
      onCreate: migrations.onCreateDatabase,
      onUpgrade: migrations.onUpgradeDatabase,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }
}