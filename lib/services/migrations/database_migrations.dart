import 'package:sqflite/sqflite.dart';

import '../../models/event_type.dart';
import '../database_service.dart';
import 'database_schema.dart';

/// 数据库迁移方法：onCreate、onUpgrade 以及按版本拆分的增量迁移。

Future<void> onCreateDatabase(Database db, int version) async {
  final batch = db.batch();

  for (final statement in createSchemaStatements) {
    batch.execute(statement);
  }

  await batch.commit(noResult: true);
  await seedDefaultEventTypes(db);
}

Future<void> onUpgradeDatabase(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await migrateFromVersion1(db);
  }
  if (oldVersion < 3) {
    await migrateToVersion3(db);
  }
  if (oldVersion < 4) {
    await migrateToVersion4(db);
  }
  if (oldVersion < 5) {
    await migrateToVersion5(db);
  }
  if (oldVersion < 6) {
    await migrateToVersion6(db);
  }
  if (oldVersion < 7) {
    await migrateToVersion7(db);
  }
  if (oldVersion < 8) {
    await migrateToVersion8(db);
  }
  if (oldVersion < 9) {
    await migrateToVersion9(db);
  }
  if (oldVersion < 10) {
    await migrateToVersion10(db);
  }
  if (oldVersion < 11) {
    await migrateToVersion11(db);
  }
}

// ──────────────────── v1 → v2 ────────────────────

Future<void> migrateFromVersion1(Database db) async {
  final batch = db.batch();

  for (final statement in migrationToVersion2Statements) {
    batch.execute(statement);
  }

  await batch.commit(noResult: true);
  await seedDefaultEventTypes(db);

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
      DatabaseService.eventsTable,
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
      DatabaseService.eventParticipantsTable,
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

// ──────────────────── v2 → v3 ────────────────────

Future<void> migrateToVersion3(Database db) async {
  final batch = db.batch();
  batch.execute(createDailySummariesTable);
  batch.execute(createDailySummariesDateIndex);
  batch.execute(createDailySummariesSourceIndex);
  batch.execute(createDailySummariesCreatedAtIndex);
  await batch.commit(noResult: true);

  final hasLegacySummaryTable = await _tableExists(db, DatabaseService.eventSummariesTable);
  if (!hasLegacySummaryTable) {
    return;
  }

  final legacyRows = await db.query(
    DatabaseService.eventSummariesTable,
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
      DatabaseService.summariesTable,
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
        'UPDATE ${DatabaseService.attachmentLinksTable} SET ownerId = ? WHERE ownerType = ? AND ownerId IN ($placeholders)',
        [retained['id'], 'summary', ...oldIds],
      );
    }
  }
}

// ──────────────────── v3 → v4 ────────────────────

Future<void> migrateToVersion4(Database db) async {
  final batch = db.batch();
  batch.execute(createContactMilestonesTable);
  batch.execute(createContactMilestonesContactIdIndex);
  batch.execute(createContactMilestonesTypeIndex);
  batch.execute(createContactMilestonesMilestoneDateIndex);
  await batch.commit(noResult: true);
}

// ──────────────────── v4 → v5 ────────────────────

Future<void> migrateToVersion5(Database db) async {
  final batch = db.batch();
  batch.execute(
    'ALTER TABLE ${DatabaseService.attachmentsTable} ADD COLUMN storageMode TEXT NOT NULL DEFAULT \'managed\'',
  );
  batch.execute(
    'ALTER TABLE ${DatabaseService.attachmentsTable} ADD COLUMN sourcePath TEXT',
  );
  batch.execute(
    'ALTER TABLE ${DatabaseService.attachmentsTable} ADD COLUMN managedPath TEXT',
  );
  batch.execute(
    'ALTER TABLE ${DatabaseService.attachmentsTable} ADD COLUMN snapshotPath TEXT',
  );
  batch.execute(
    'ALTER TABLE ${DatabaseService.attachmentsTable} ADD COLUMN originalSizeBytes INTEGER',
  );
  batch.execute(
    'ALTER TABLE ${DatabaseService.attachmentsTable} ADD COLUMN managedSizeBytes INTEGER',
  );
  batch.execute(
    'ALTER TABLE ${DatabaseService.attachmentsTable} ADD COLUMN sourceStatus TEXT NOT NULL DEFAULT \'available\'',
  );
  batch.execute(
    'ALTER TABLE ${DatabaseService.attachmentsTable} ADD COLUMN sourceLastVerifiedAt INTEGER',
  );
  batch.execute(
    'ALTER TABLE ${DatabaseService.attachmentsTable} ADD COLUMN importPolicy TEXT',
  );
  batch.execute(
    "UPDATE ${DatabaseService.attachmentsTable} SET managedPath = storagePath WHERE managedPath IS NULL OR managedPath = ''",
  );
  batch.execute(
    'UPDATE ${DatabaseService.attachmentsTable} SET originalSizeBytes = sizeBytes WHERE originalSizeBytes IS NULL',
  );
  batch.execute(
    'UPDATE ${DatabaseService.attachmentsTable} SET managedSizeBytes = sizeBytes WHERE managedSizeBytes IS NULL',
  );
  batch.execute(createAttachmentsStorageModeIndex);
  batch.execute(createAttachmentsSourceStatusIndex);
  await batch.commit(noResult: true);
}

// ──────────────────── v5 → v6 ────────────────────

Future<void> migrateToVersion6(Database db) async {
  final batch = db.batch();
  batch.execute(
    'ALTER TABLE ${DatabaseService.attachmentsTable} ADD COLUMN previewStatus TEXT NOT NULL DEFAULT \'none\'',
  );
  batch.execute(
    'ALTER TABLE ${DatabaseService.attachmentsTable} ADD COLUMN previewUpdatedAt INTEGER',
  );
  batch.execute(
    'ALTER TABLE ${DatabaseService.attachmentsTable} ADD COLUMN previewError TEXT',
  );
  batch.execute(
    'UPDATE ${DatabaseService.attachmentsTable} SET previewStatus = \'ready\' WHERE snapshotPath IS NOT NULL AND snapshotPath != \'\'',
  );
  batch.execute(createAttachmentsPreviewStatusIndex);
  await batch.commit(noResult: true);
}

// ──────────────────── v6 → v7 ────────────────────

Future<void> migrateToVersion7(Database db) async {
  final batch = db.batch();
  batch.execute(createAppPreferencesTable);
  await batch.commit(noResult: true);
}

// ──────────────────── v7 → v8 ────────────────────

Future<void> migrateToVersion8(Database db) async {
  final batch = db.batch();
  batch.execute(createTodoGroupsTable);
  batch.execute(createTodoItemsTable);
  batch.execute(createTodoItemContactsTable);
  batch.execute(createTodoItemEventsTable);
  batch.execute(createTodoGroupsSortOrderIndex);
  batch.execute(createTodoItemsGroupIdIndex);
  batch.execute(createTodoItemsParentItemIdIndex);
  batch.execute(createTodoItemsStatusIndex);
  batch.execute(createTodoItemContactsItemIdIndex);
  batch.execute(createTodoItemContactsContactIdIndex);
  batch.execute(createTodoItemEventsItemIdIndex);
  batch.execute(createTodoItemEventsEventIdIndex);
  await batch.commit(noResult: true);
}

// ──────────────────── v8 → v9 ────────────────────

Future<void> migrateToVersion9(Database db) async {
  for (final table in const [
    'contacts',
    'tags',
    'events',
    'daily_summaries',
    'attachments',
    'contact_milestones',
    'todo_groups',
    'todo_items',
  ]) {
    if (await _columnExists(db, table, 'deletedAt')) {
      continue;
    }

    await db.execute('ALTER TABLE $table ADD COLUMN deletedAt INTEGER');
  }
}

// ──────────────────── v9 → v10 ────────────────────

Future<void> migrateToVersion10(Database db) async {
  await db.execute(createQuickNotesTable);
  await db.execute(createQuickNotesCaptureDateIndex);
  await db.execute(createQuickNotesSessionGroupIndex);
  await db.execute(createQuickNotesLinkedContactIdIndex);
}

// ──────────────────── v10 → v11 ────────────────────

Future<void> migrateToVersion11(Database db) async {
  final batch = db.batch();
  batch.execute(createInfoTagsTable);
  batch.execute(createContactInfoTagsTable);
  batch.execute(createContactInfoTagsContactIdIndex);
  await batch.commit(noResult: true);
}

// ──────────────────── 预置数据 ────────────────────

Future<void> seedDefaultEventTypes(Database db) async {
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
      DatabaseService.eventTypesTable,
      eventType.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
}

// ──────────────────── 私有辅助 ────────────────────

Future<bool> _tableExists(Database db, String tableName) async {
  final result = await db.rawQuery(
    "SELECT COUNT(*) AS count FROM sqlite_master WHERE type = 'table' AND name = ?",
    [tableName],
  );

  return (result.first['count'] as int?) == 1;
}

Future<bool> _columnExists(Database db, String tableName, String columnName) async {
  final columns = await db.rawQuery('PRAGMA table_info($tableName)');
  return columns.any((column) => column['name'] == columnName);
}

DateTime? _parseLegacyDate(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  return DateTime.tryParse(value);
}
