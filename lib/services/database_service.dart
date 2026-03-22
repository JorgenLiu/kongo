import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/event_type.dart';

/// SQLite 数据库服务，负责建表、迁移与预置数据初始化。
class DatabaseService {
  DatabaseService._internal({
    String databaseFileName = defaultDatabaseFileName,
  }) : _databaseFileName = databaseFileName;

  static final DatabaseService instance = DatabaseService._internal();
  Database? _database;

  static const String defaultDatabaseFileName = 'kongo.db';
  static const int databaseVersion = 3;
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
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    for (final statement in _createSchemaStatements) {
      batch.execute(statement);
    }

    await batch.commit(noResult: true);
    await _seedDefaultEventTypes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _migrateFromVersion1(db);
    }
    if (oldVersion < 3) {
      await _migrateToVersion3(db);
    }
  }

  Future<void> _migrateFromVersion1(Database db) async {
    final batch = db.batch();

    for (final statement in _migrationToVersion2Statements) {
      batch.execute(statement);
    }

    await batch.commit(noResult: true);
    await _seedDefaultEventTypes(db);

    final hasLegacyEventsTable = await _tableExists(db, 'contact_events');
    if (!hasLegacyEventsTable) {
      return;
    }

    final legacyEvents = await db.query('contact_events');

    for (final record in legacyEvents) {
      final eventId = record['id'] as String;
      final contactId = record['contactId'] as String;
      final eventDate = _parseLegacyDate(record['date'] as String?);
      final reminderEnabled = ((record['reminderEnabled'] as num?)?.toInt() ?? 0) == 1;
      final reminderDays = (record['reminderDays'] as num?)?.toInt() ?? 0;
      final reminderAt =
          reminderEnabled && eventDate != null ? eventDate.subtract(Duration(days: reminderDays)) : null;
      final createdAt = (record['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;
      final updatedAt = (record['updatedAt'] as num?)?.toInt() ?? createdAt;

      await db.insert(
        eventsTable,
        {
          'id': eventId,
          'title': '已迁移事件',
          'eventTypeId': record['eventTypeId'],
          'status': 'planned',
          'startAt': eventDate?.millisecondsSinceEpoch,
          'endAt': null,
          'location': null,
          'description': record['notes'],
          'reminderEnabled': reminderEnabled ? 1 : 0,
          'reminderAt': reminderAt?.millisecondsSinceEpoch,
          'createdByContactId': contactId,
          'createdAt': createdAt,
          'updatedAt': updatedAt,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      await db.insert(
        eventParticipantsTable,
        {
          'id': '${eventId}_$contactId',
          'eventId': eventId,
          'contactId': contactId,
          'role': 'participant',
          'addedAt': createdAt,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    await db.execute('DROP TABLE contact_events');
  }

  Future<void> _seedDefaultEventTypes(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final defaults = <EventType>[
      EventType(
        id: 'evt-birthday',
        name: '生日',
        icon: '🎂',
        color: '#FF6B6B',
        createdAt: DateTime.fromMillisecondsSinceEpoch(now),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      ),
      EventType(
        id: 'evt-meeting',
        name: '会面',
        icon: '📅',
        color: '#42A5F5',
        createdAt: DateTime.fromMillisecondsSinceEpoch(now),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      ),
      EventType(
        id: 'evt-call',
        name: '通话',
        icon: '📞',
        color: '#66BB6A',
        createdAt: DateTime.fromMillisecondsSinceEpoch(now),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      ),
      EventType(
        id: 'evt-followup',
        name: '跟进',
        icon: '📝',
        color: '#FFA726',
        createdAt: DateTime.fromMillisecondsSinceEpoch(now),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      ),
    ];

    for (final eventType in defaults) {
      await db.insert(
        eventTypesTable,
        eventType.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<bool> _tableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT COUNT(*) AS count FROM sqlite_master WHERE type = 'table' AND name = ?",
      [tableName],
    );

    return (result.first['count'] as int?) == 1;
  }

  DateTime? _parseLegacyDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  List<String> get _createSchemaStatements => const [
        _createContactsTable,
        _createTagsTable,
        _createContactTagsTable,
        _createEventTypesTable,
        _createEventsTable,
        _createEventParticipantsTable,
        _createDailySummariesTable,
        _createAttachmentsTable,
        _createAttachmentLinksTable,
        _createAiJobsTable,
        _createAiOutputsTable,
        _createContactsNameIndex,
        _createContactsPhoneIndex,
        _createContactsEmailIndex,
        _createContactsCreatedAtIndex,
        _createTagsNameIndex,
        _createContactTagsContactIdIndex,
        _createContactTagsTagIdIndex,
        _createEventTypesNameIndex,
        _createEventsEventTypeIdIndex,
        _createEventsStatusIndex,
        _createEventsStartAtIndex,
        _createEventsCreatedByContactIdIndex,
        _createEventParticipantsEventIdIndex,
        _createEventParticipantsContactIdIndex,
        _createDailySummariesDateIndex,
        _createDailySummariesSourceIndex,
        _createDailySummariesCreatedAtIndex,
        _createAttachmentsFileNameIndex,
        _createAttachmentsMimeTypeIndex,
        _createAttachmentsChecksumIndex,
        _createAttachmentLinksAttachmentIdIndex,
        _createAttachmentLinksOwnerIndex,
        _createAiJobsTargetIndex,
        _createAiJobsStatusIndex,
        _createAiOutputsAiJobIdIndex,
      ];

  List<String> get _migrationToVersion2Statements => const [
        _createEventsTable,
        _createEventParticipantsTable,
        _createEventSummariesTable,
        _createAttachmentsTable,
        _createAttachmentLinksTable,
        _createAiJobsTable,
        _createAiOutputsTable,
        _createEventsEventTypeIdIndex,
        _createEventsStatusIndex,
        _createEventsStartAtIndex,
        _createEventsCreatedByContactIdIndex,
        _createEventParticipantsEventIdIndex,
        _createEventParticipantsContactIdIndex,
        _createEventSummariesEventIdIndex,
        _createEventSummariesSourceIndex,
        _createEventSummariesCreatedAtIndex,
        _createAttachmentsFileNameIndex,
        _createAttachmentsMimeTypeIndex,
        _createAttachmentsChecksumIndex,
        _createAttachmentLinksAttachmentIdIndex,
        _createAttachmentLinksOwnerIndex,
        _createAiJobsTargetIndex,
        _createAiJobsStatusIndex,
        _createAiOutputsAiJobIdIndex,
      ];

  Future<void> _migrateToVersion3(Database db) async {
    final batch = db.batch();
    batch.execute(_createDailySummariesTable);
    batch.execute(_createDailySummariesDateIndex);
    batch.execute(_createDailySummariesSourceIndex);
    batch.execute(_createDailySummariesCreatedAtIndex);
    await batch.commit(noResult: true);

    final hasLegacySummaryTable = await _tableExists(db, eventSummariesTable);
    if (!hasLegacySummaryTable) {
      return;
    }

    final legacyRows = await db.query(
      eventSummariesTable,
      orderBy: 'createdAt ASC, updatedAt ASC',
    );
    if (legacyRows.isEmpty) {
      return;
    }

    final groupedRows = <String, List<Map<String, Object?>>>{};
    for (final row in legacyRows) {
      final createdAt = DateTime.fromMillisecondsSinceEpoch((row['createdAt'] as num).toInt());
      final summaryDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
      final key = summaryDate.millisecondsSinceEpoch.toString();
      groupedRows.putIfAbsent(key, () => <Map<String, Object?>>[]).add(row);
    }

    for (final entry in groupedRows.entries) {
      final rows = entry.value;
      final retained = rows.last;
      final mergedTodaySummary = rows
          .map((row) {
            final title = (row['title'] as String?)?.trim();
            final content = (row['content'] as String?)?.trim() ?? '';
            if (title == null || title.isEmpty) {
              return content;
            }
            return '$title\n$content';
          })
          .where((value) => value.trim().isNotEmpty)
          .join('\n\n');

      final summaryDate = DateTime.fromMillisecondsSinceEpoch(int.parse(entry.key));
      await db.insert(
        summariesTable,
        {
          'id': retained['id'],
          'summaryDate': summaryDate.millisecondsSinceEpoch,
          'todaySummary': mergedTodaySummary,
          'tomorrowPlan': '',
          'source': retained['source'] as String? ?? 'manual',
          'createdByContactId': retained['createdByContactId'],
          'aiJobId': retained['aiJobId'],
          'createdAt': retained['createdAt'],
          'updatedAt': retained['updatedAt'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final oldIds = rows
          .map((row) => row['id'] as String)
          .where((id) => id != retained['id'] as String)
          .toList();

      if (oldIds.isNotEmpty) {
        final placeholders = List.filled(oldIds.length, '?').join(', ');
        await db.rawUpdate(
          'UPDATE $attachmentLinksTable SET ownerId = ? WHERE ownerType = ? AND ownerId IN ($placeholders)',
          [retained['id'], 'summary', ...oldIds],
        );
      }
    }
  }

  static const String _createContactsTable = '''
CREATE TABLE contacts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  address TEXT,
  notes TEXT,
  avatarPath TEXT,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL
)
''';

  static const String _createTagsTable = '''
CREATE TABLE tags (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  color TEXT,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL
)
''';

  static const String _createContactTagsTable = '''
CREATE TABLE contact_tags (
  id TEXT PRIMARY KEY,
  contactId TEXT NOT NULL,
  tagId TEXT NOT NULL,
  addedAt INTEGER NOT NULL,
  FOREIGN KEY (contactId) REFERENCES contacts(id) ON DELETE CASCADE,
  FOREIGN KEY (tagId) REFERENCES tags(id) ON DELETE CASCADE,
  UNIQUE(contactId, tagId)
)
''';

  static const String _createEventTypesTable = '''
CREATE TABLE event_types (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  icon TEXT,
  color TEXT,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL
)
''';

  static const String _createEventsTable = '''
CREATE TABLE events (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  eventTypeId TEXT,
  status TEXT NOT NULL DEFAULT 'planned',
  startAt INTEGER,
  endAt INTEGER,
  location TEXT,
  description TEXT,
  reminderEnabled INTEGER NOT NULL DEFAULT 0,
  reminderAt INTEGER,
  createdByContactId TEXT,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL,
  FOREIGN KEY (eventTypeId) REFERENCES event_types(id),
  FOREIGN KEY (createdByContactId) REFERENCES contacts(id)
)
''';

  static const String _createEventParticipantsTable = '''
CREATE TABLE event_participants (
  id TEXT PRIMARY KEY,
  eventId TEXT NOT NULL,
  contactId TEXT NOT NULL,
  role TEXT,
  addedAt INTEGER NOT NULL,
  FOREIGN KEY (eventId) REFERENCES events(id) ON DELETE CASCADE,
  FOREIGN KEY (contactId) REFERENCES contacts(id) ON DELETE CASCADE,
  UNIQUE(eventId, contactId)
)
''';

  static const String _createEventSummariesTable = '''
CREATE TABLE event_summaries (
  id TEXT PRIMARY KEY,
  eventId TEXT NOT NULL,
  title TEXT,
  content TEXT NOT NULL,
  summaryType TEXT NOT NULL DEFAULT 'manual',
  version INTEGER NOT NULL DEFAULT 1,
  source TEXT NOT NULL DEFAULT 'manual',
  createdByContactId TEXT,
  aiJobId TEXT,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL,
  FOREIGN KEY (eventId) REFERENCES events(id) ON DELETE CASCADE,
  FOREIGN KEY (createdByContactId) REFERENCES contacts(id)
)
''';

  static const String _createDailySummariesTable = '''
CREATE TABLE daily_summaries (
  id TEXT PRIMARY KEY,
  summaryDate INTEGER NOT NULL UNIQUE,
  todaySummary TEXT NOT NULL DEFAULT '',
  tomorrowPlan TEXT NOT NULL DEFAULT '',
  source TEXT NOT NULL DEFAULT 'manual',
  createdByContactId TEXT,
  aiJobId TEXT,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL,
  FOREIGN KEY (createdByContactId) REFERENCES contacts(id)
)
''';

  static const String _createAttachmentsTable = '''
CREATE TABLE attachments (
  id TEXT PRIMARY KEY,
  fileName TEXT NOT NULL,
  originalFileName TEXT,
  storagePath TEXT NOT NULL,
  mimeType TEXT,
  extension TEXT,
  sizeBytes INTEGER NOT NULL,
  checksum TEXT,
  previewText TEXT,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL
)
''';

  static const String _createAttachmentLinksTable = '''
CREATE TABLE attachment_links (
  id TEXT PRIMARY KEY,
  attachmentId TEXT NOT NULL,
  ownerType TEXT NOT NULL,
  ownerId TEXT NOT NULL,
  label TEXT,
  addedAt INTEGER NOT NULL,
  FOREIGN KEY (attachmentId) REFERENCES attachments(id) ON DELETE CASCADE,
  UNIQUE(attachmentId, ownerType, ownerId)
)
''';

  static const String _createAiJobsTable = '''
CREATE TABLE ai_jobs (
  id TEXT PRIMARY KEY,
  feature TEXT NOT NULL,
  provider TEXT NOT NULL,
  model TEXT,
  targetType TEXT NOT NULL,
  targetId TEXT NOT NULL,
  status TEXT NOT NULL,
  promptDigest TEXT,
  errorMessage TEXT,
  createdAt INTEGER NOT NULL,
  completedAt INTEGER
)
''';

  static const String _createAiOutputsTable = '''
CREATE TABLE ai_outputs (
  id TEXT PRIMARY KEY,
  aiJobId TEXT NOT NULL,
  outputType TEXT NOT NULL,
  content TEXT NOT NULL,
  createdAt INTEGER NOT NULL,
  FOREIGN KEY (aiJobId) REFERENCES ai_jobs(id) ON DELETE CASCADE
)
''';

    static const String _createContactsNameIndex =
      'CREATE INDEX idx_contacts_name ON contacts(name)';

    static const String _createContactsPhoneIndex =
      'CREATE INDEX idx_contacts_phone ON contacts(phone)';

    static const String _createContactsEmailIndex =
      'CREATE INDEX idx_contacts_email ON contacts(email)';

    static const String _createContactsCreatedAtIndex =
      'CREATE INDEX idx_contacts_createdAt ON contacts(createdAt)';

    static const String _createTagsNameIndex =
      'CREATE INDEX idx_tags_name ON tags(name)';

    static const String _createContactTagsContactIdIndex =
      'CREATE INDEX idx_contact_tags_contactId ON contact_tags(contactId)';

    static const String _createContactTagsTagIdIndex =
      'CREATE INDEX idx_contact_tags_tagId ON contact_tags(tagId)';

    static const String _createEventTypesNameIndex =
      'CREATE INDEX idx_event_types_name ON event_types(name)';

    static const String _createEventsEventTypeIdIndex =
      'CREATE INDEX idx_events_eventTypeId ON events(eventTypeId)';

    static const String _createEventsStatusIndex =
      'CREATE INDEX idx_events_status ON events(status)';

    static const String _createEventsStartAtIndex =
      'CREATE INDEX idx_events_startAt ON events(startAt)';

    static const String _createEventsCreatedByContactIdIndex =
      'CREATE INDEX idx_events_createdByContactId ON events(createdByContactId)';

    static const String _createEventParticipantsEventIdIndex =
      'CREATE INDEX idx_event_participants_eventId ON event_participants(eventId)';

    static const String _createEventParticipantsContactIdIndex =
      'CREATE INDEX idx_event_participants_contactId ON event_participants(contactId)';

    static const String _createEventSummariesEventIdIndex =
      'CREATE INDEX idx_event_summaries_eventId ON event_summaries(eventId)';

    static const String _createEventSummariesSourceIndex =
      'CREATE INDEX idx_event_summaries_source ON event_summaries(source)';

    static const String _createEventSummariesCreatedAtIndex =
      'CREATE INDEX idx_event_summaries_createdAt ON event_summaries(createdAt)';

    static const String _createDailySummariesDateIndex =
      'CREATE INDEX idx_daily_summaries_summaryDate ON daily_summaries(summaryDate)';

    static const String _createDailySummariesSourceIndex =
      'CREATE INDEX idx_daily_summaries_source ON daily_summaries(source)';

    static const String _createDailySummariesCreatedAtIndex =
      'CREATE INDEX idx_daily_summaries_createdAt ON daily_summaries(createdAt)';

    static const String _createAttachmentsFileNameIndex =
      'CREATE INDEX idx_attachments_fileName ON attachments(fileName)';

    static const String _createAttachmentsMimeTypeIndex =
      'CREATE INDEX idx_attachments_mimeType ON attachments(mimeType)';

    static const String _createAttachmentsChecksumIndex =
      'CREATE INDEX idx_attachments_checksum ON attachments(checksum)';

    static const String _createAttachmentLinksAttachmentIdIndex =
      'CREATE INDEX idx_attachment_links_attachmentId ON attachment_links(attachmentId)';

    static const String _createAttachmentLinksOwnerIndex =
      'CREATE INDEX idx_attachment_links_owner ON attachment_links(ownerType, ownerId)';

    static const String _createAiJobsTargetIndex =
      'CREATE INDEX idx_ai_jobs_target ON ai_jobs(targetType, targetId)';

    static const String _createAiJobsStatusIndex =
      'CREATE INDEX idx_ai_jobs_status ON ai_jobs(status)';

    static const String _createAiOutputsAiJobIdIndex =
      'CREATE INDEX idx_ai_outputs_aiJobId ON ai_outputs(aiJobId)';
}