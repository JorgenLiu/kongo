import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../exceptions/app_exception.dart';
import '../models/contact.dart';
import '../models/event.dart';
import '../models/event_participant.dart';
import '../models/event_type.dart';
import '../services/database_service.dart';

abstract class EventRepository {
  Future<List<EventType>> getEventTypes();
  Future<EventType> getEventTypeById(String id);
  Future<EventType> insertEventType(EventType eventType);
  Future<List<Event>> getAll();
  Future<Event> getById(String id);
  Future<bool> exists(String id);
  Future<Event> insert(Event event);
  Future<Event> update(Event event);
  Future<void> delete(String id);
  Future<List<Event>> search({
    String? keyword,
    String? eventTypeId,
  });
  Future<List<Event>> getUpcomingEvents({int days = 30});
  Future<List<Event>> getEventsByDate(DateTime date);
  Future<List<Event>> getByContactId(String contactId);
  Future<List<Contact>> getParticipants(String eventId);
  Future<Map<String, List<Contact>>> getParticipantsByEventIds(List<String> eventIds);
  Future<List<EventParticipant>> getParticipantLinks(String eventId);
  Future<void> replaceParticipants(String eventId, List<EventParticipant> participants);
  Future<void> addParticipant(EventParticipant participant);
  Future<void> removeParticipant(String eventId, String contactId);
}

class SqliteEventRepository implements EventRepository {
  final DatabaseService _databaseService;

  SqliteEventRepository(this._databaseService);

  @override
  Future<List<EventType>> getEventTypes() async {
    return _run<List<EventType>>('获取事件类型失败', (db) async {
      final rows = await db.query(
        DatabaseService.eventTypesTable,
        orderBy: 'name COLLATE NOCASE ASC',
      );
      return rows.map(_toEventType).toList();
    });
  }

  @override
  Future<EventType> getEventTypeById(String id) async {
    return _run<EventType>('获取事件类型失败', (db) async {
      final rows = await db.query(
        DatabaseService.eventTypesTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw const DatabaseException(message: '事件类型不存在', code: 'event_type_not_found');
      }
      return _toEventType(rows.first);
    });
  }

  @override
  Future<EventType> insertEventType(EventType eventType) async {
    return _run<EventType>('创建事件类型失败', (db) async {
      await db.insert(DatabaseService.eventTypesTable, eventType.toMap());
      return getEventTypeById(eventType.id);
    });
  }

  @override
  Future<List<Event>> getAll() async {
    return _run<List<Event>>('获取事件列表失败', (db) async {
      final rows = await db.query(
        DatabaseService.eventsTable,
        orderBy: 'COALESCE(startAt, createdAt) DESC',
      );
      return rows.map(_toEvent).toList();
    });
  }

  @override
  Future<Event> getById(String id) async {
    return _run<Event>('获取事件失败', (db) async {
      final rows = await db.query(
        DatabaseService.eventsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw const DatabaseException(message: '事件不存在', code: 'event_not_found');
      }
      return _toEvent(rows.first);
    });
  }

  @override
  Future<bool> exists(String id) async {
    return _run<bool>('检查事件失败', (db) async {
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM ${DatabaseService.eventsTable} WHERE id = ?',
        [id],
      );
      return ((rows.first['count'] as num?)?.toInt() ?? 0) > 0;
    });
  }

  @override
  Future<Event> insert(Event event) async {
    return _run<Event>('创建事件失败', (db) async {
      await db.insert(DatabaseService.eventsTable, event.toMap());
      return getById(event.id);
    });
  }

  @override
  Future<Event> update(Event event) async {
    return _run<Event>('更新事件失败', (db) async {
      final count = await db.update(
        DatabaseService.eventsTable,
        event.toMap(),
        where: 'id = ?',
        whereArgs: [event.id],
      );
      if (count == 0) {
        throw const DatabaseException(message: '事件不存在，无法更新', code: 'event_not_found');
      }
      return getById(event.id);
    });
  }

  @override
  Future<void> delete(String id) async {
    await _run<void>('删除事件失败', (db) async {
      final count = await db.delete(
        DatabaseService.eventsTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count == 0) {
        throw const DatabaseException(message: '事件不存在，无法删除', code: 'event_not_found');
      }
    });
  }

  @override
  Future<List<Event>> search({
    String? keyword,
    String? eventTypeId,
  }) async {
    return _run<List<Event>>('搜索事件失败', (db) async {
      final whereClauses = <String>[];
      final whereArgs = <Object?>[];

      if (keyword != null && keyword.trim().isNotEmpty) {
        whereClauses.add('(title LIKE ? OR location LIKE ? OR description LIKE ?)');
        final likeKeyword = '%${keyword.trim()}%';
        whereArgs.addAll([likeKeyword, likeKeyword, likeKeyword]);
      }

      if (eventTypeId != null && eventTypeId.isNotEmpty) {
        whereClauses.add('eventTypeId = ?');
        whereArgs.add(eventTypeId);
      }

      final rows = await db.query(
        DatabaseService.eventsTable,
        where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'COALESCE(startAt, createdAt) DESC',
      );

      return rows.map(_toEvent).toList();
    });
  }

  @override
  Future<List<Event>> getUpcomingEvents({int days = 30}) async {
    return _run<List<Event>>('获取近期事件失败', (db) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final end = DateTime.now().add(Duration(days: days)).millisecondsSinceEpoch;
      final rows = await db.query(
        DatabaseService.eventsTable,
        where: 'startAt IS NOT NULL AND startAt BETWEEN ? AND ?',
        whereArgs: [now, end],
        orderBy: 'startAt ASC',
      );
      return rows.map(_toEvent).toList();
    });
  }

  @override
  @override
  Future<List<Event>> getEventsByDate(DateTime date) async {
    return _run<List<Event>>('获取指定日期事件失败', (db) async {
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final rows = await db.query(
        DatabaseService.eventsTable,
        where: 'startAt IS NOT NULL AND startAt >= ? AND startAt < ?',
        whereArgs: [
          dayStart.millisecondsSinceEpoch,
          dayEnd.millisecondsSinceEpoch,
        ],
        orderBy: 'startAt ASC',
      );
      return rows.map(_toEvent).toList();
    });
  }

  @override
  Future<List<Event>> getByContactId(String contactId) async {
    return _run<List<Event>>('获取联系人相关事件失败', (db) async {
      final rows = await db.rawQuery(
        '''
SELECT e.*
FROM ${DatabaseService.eventsTable} e
JOIN ${DatabaseService.eventParticipantsTable} ep ON ep.eventId = e.id
WHERE ep.contactId = ?
ORDER BY COALESCE(e.startAt, e.createdAt) DESC
''',
        [contactId],
      );
      return rows.map(_toEvent).toList();
    });
  }

  @override
  Future<List<Contact>> getParticipants(String eventId) async {
    return _run<List<Contact>>('获取事件参与人失败', (db) async {
      final rows = await db.rawQuery(
        '''
SELECT c.*
FROM ${DatabaseService.contactsTable} c
JOIN ${DatabaseService.eventParticipantsTable} ep ON ep.contactId = c.id
WHERE ep.eventId = ?
ORDER BY ep.addedAt ASC
''',
        [eventId],
      );
      return _hydrateContacts(db, rows);
    });
  }

  @override
  Future<Map<String, List<Contact>>> getParticipantsByEventIds(List<String> eventIds) async {
    return _run<Map<String, List<Contact>>>('批量获取事件参与人失败', (db) async {
      if (eventIds.isEmpty) {
        return const {};
      }

      final placeholders = List.filled(eventIds.length, '?').join(', ');
      final rows = await db.rawQuery(
        '''
SELECT ep.eventId AS _eventId, c.*
FROM ${DatabaseService.contactsTable} c
JOIN ${DatabaseService.eventParticipantsTable} ep ON ep.contactId = c.id
WHERE ep.eventId IN ($placeholders)
ORDER BY ep.eventId ASC, ep.addedAt ASC
''',
        eventIds,
      );

      final tagsByContactId = await _loadTagsByContactIds(
        db,
        rows.map((row) => row['id'] as String).toList(),
      );

      final participantsByEventId = {
        for (final eventId in eventIds) eventId: <Contact>[],
      };

      for (final row in rows) {
        final eventId = row['_eventId'] as String;
        final contactId = row['id'] as String;
        participantsByEventId.putIfAbsent(eventId, () => <Contact>[]).add(
          Contact.fromMap(
            Map<String, dynamic>.from(row),
            tags: tagsByContactId[contactId] ?? const [],
          ),
        );
      }

      return participantsByEventId;
    });
  }

  @override
  Future<List<EventParticipant>> getParticipantLinks(String eventId) async {
    return _run<List<EventParticipant>>('获取事件参与关系失败', (db) async {
      final rows = await db.query(
        DatabaseService.eventParticipantsTable,
        where: 'eventId = ?',
        whereArgs: [eventId],
        orderBy: 'addedAt ASC',
      );
      return rows.map(EventParticipant.fromMap).toList();
    });
  }

  @override
  Future<void> replaceParticipants(String eventId, List<EventParticipant> participants) async {
    await _run<void>('更新事件参与人失败', (db) async {
      await db.transaction((txn) async {
        await txn.delete(
          DatabaseService.eventParticipantsTable,
          where: 'eventId = ?',
          whereArgs: [eventId],
        );

        final batch = txn.batch();
        for (final participant in participants) {
          batch.insert(
            DatabaseService.eventParticipantsTable,
            participant.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    });
  }

  @override
  Future<void> addParticipant(EventParticipant participant) async {
    await _run<void>('添加事件参与人失败', (db) async {
      await db.insert(
        DatabaseService.eventParticipantsTable,
        participant.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  @override
  Future<void> removeParticipant(String eventId, String contactId) async {
    await _run<void>('移除事件参与人失败', (db) async {
      await db.delete(
        DatabaseService.eventParticipantsTable,
        where: 'eventId = ? AND contactId = ?',
        whereArgs: [eventId, contactId],
      );
    });
  }

  Future<List<Contact>> _hydrateContacts(
    Database db,
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) {
      return const [];
    }

    final ids = rows.map((row) => row['id'] as String).toList();
    final tagsByContactId = await _loadTagsByContactIds(db, ids);

    return rows
        .map(
          (row) => Contact.fromMap(
            row,
            tags: tagsByContactId[row['id'] as String] ?? const [],
          ),
        )
        .toList();
  }

  Future<Map<String, List<String>>> _loadTagsByContactIds(
    Database db,
    List<String> contactIds,
  ) async {
    if (contactIds.isEmpty) {
      return const {};
    }

    final placeholders = List.filled(contactIds.length, '?').join(', ');
    final rows = await db.rawQuery(
      '''
SELECT ct.contactId, t.name
FROM ${DatabaseService.contactTagsTable} ct
JOIN ${DatabaseService.tagsTable} t ON t.id = ct.tagId
WHERE ct.contactId IN ($placeholders)
ORDER BY t.name COLLATE NOCASE ASC
''',
      contactIds,
    );

    final result = <String, List<String>>{};
    for (final row in rows) {
      final contactId = row['contactId'] as String;
      final tagName = row['name'] as String;
      result.putIfAbsent(contactId, () => <String>[]).add(tagName);
    }
    return result;
  }

  Event _toEvent(Map<String, Object?> row) {
    return Event.fromMap(Map<String, dynamic>.from(row));
  }

  EventType _toEventType(Map<String, Object?> row) {
    return EventType.fromMap(Map<String, dynamic>.from(row));
  }

  Future<T> _run<T>(
    String message,
    Future<T> Function(Database db) action,
  ) async {
    try {
      final db = await _databaseService.database;
      return await action(db);
    } on AppException {
      rethrow;
    } on Exception catch (error) {
      throw DatabaseException(message: message, originalException: error);
    }
  }
}