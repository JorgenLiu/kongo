import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../exceptions/app_exception.dart';
import '../models/contact_milestone.dart';
import '../services/database_service.dart';

abstract class ContactMilestoneRepository {
  Future<List<ContactMilestone>> getAll();
  Future<List<ContactMilestone>> getByContactId(String contactId);
  Future<ContactMilestone> getById(String id);
  Future<ContactMilestone> insert(ContactMilestone milestone);
  Future<ContactMilestone> update(ContactMilestone milestone);
  Future<void> delete(String id);
  Future<void> deleteByContactId(String contactId);
  Future<List<ContactMilestone>> getUpcoming({int days = 30});
}

class SqliteContactMilestoneRepository implements ContactMilestoneRepository {
  final DatabaseService _databaseService;

  SqliteContactMilestoneRepository(this._databaseService);

  @override
  Future<List<ContactMilestone>> getAll() async {
    return _run<List<ContactMilestone>>('获取重要日期列表失败', (db) async {
      final rows = await db.query(
        DatabaseService.contactMilestonesTable,
        orderBy: 'milestoneDate ASC',
      );
      return rows.map(ContactMilestone.fromMap).toList(growable: false);
    });
  }

  @override
  Future<List<ContactMilestone>> getByContactId(String contactId) async {
    return _run<List<ContactMilestone>>('获取联系人重要日期失败', (db) async {
        final rows = await db.query(
        DatabaseService.contactMilestonesTable,
        where: 'contactId = ?',
        whereArgs: [contactId],
        orderBy: 'milestoneDate ASC',
      );
      return rows.map(ContactMilestone.fromMap).toList();
    });
  }

  @override
  Future<ContactMilestone> getById(String id) async {
    return _run<ContactMilestone>('获取重要日期失败', (db) async {
      final rows = await db.query(
        DatabaseService.contactMilestonesTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (rows.isEmpty) {
          throw const DatabaseException(
            message: '重要日期不存在',
          code: 'milestone_not_found',
        );
      }

      return ContactMilestone.fromMap(rows.first);
    });
  }

  @override
  Future<ContactMilestone> insert(ContactMilestone milestone) async {
    return _run<ContactMilestone>('创建重要日期失败', (db) async {
        await db.insert(
        DatabaseService.contactMilestonesTable,
        milestone.toMap(),
      );
      return getById(milestone.id);
    });
  }

  @override
  Future<ContactMilestone> update(ContactMilestone milestone) async {
    return _run<ContactMilestone>('更新重要日期失败', (db) async {
      final count = await db.update(
        DatabaseService.contactMilestonesTable,
        milestone.toMap(),
        where: 'id = ?',
        whereArgs: [milestone.id],
      );

      if (count == 0) {
          throw const DatabaseException(
            message: '重要日期不存在，无法更新',
          code: 'milestone_not_found',
        );
      }

      return getById(milestone.id);
    });
  }

  @override
  Future<void> delete(String id) async {
    await _run<void>('删除重要日期失败', (db) async {
      final count = await db.delete(
        DatabaseService.contactMilestonesTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
          throw const DatabaseException(
            message: '重要日期不存在，无法删除',
          code: 'milestone_not_found',
        );
      }
    });
  }

  @override
  Future<void> deleteByContactId(String contactId) async {
    await _run<void>('删除联系人重要日期失败', (db) async {
        await db.delete(
        DatabaseService.contactMilestonesTable,
        where: 'contactId = ?',
        whereArgs: [contactId],
      );
    });
  }

  @override
  Future<List<ContactMilestone>> getUpcoming({int days = 30}) async {
    return _run<List<ContactMilestone>>('获取即将到来的重要日期失败', (db) async {
      final rows = await db.query(
        DatabaseService.contactMilestonesTable,
        orderBy: 'milestoneDate ASC',
      );

      final today = _normalizeDate(DateTime.now());
      final cutoff = today.add(Duration(days: days));
      final matches = <({ContactMilestone milestone, DateTime nextOccurrence})>[];

      for (final row in rows) {
        final milestone = ContactMilestone.fromMap(row);
        final nextOccurrence = _getNextOccurrence(milestone, today);
        if (nextOccurrence != null && !nextOccurrence.isAfter(cutoff)) {
          matches.add((milestone: milestone, nextOccurrence: nextOccurrence));
        }
      }

      matches.sort((a, b) {
        final occurrenceComparison = a.nextOccurrence.compareTo(b.nextOccurrence);
        if (occurrenceComparison != 0) {
          return occurrenceComparison;
        }
        return a.milestone.displayName.compareTo(b.milestone.displayName);
      });

      return matches.map((entry) => entry.milestone).toList(growable: false);
    });
  }

  DateTime? _getNextOccurrence(ContactMilestone milestone, DateTime today) {
    final milestoneDate = milestone.milestoneDate;

    if (!milestone.isRecurring) {
      final oneTimeDate = _normalizeDate(milestoneDate);
      if (oneTimeDate.isBefore(today)) {
        return null;
      }
      return oneTimeDate;
    }

    final thisYear = DateTime(
      today.year,
      milestoneDate.month,
      milestoneDate.day,
    );

    if (!thisYear.isBefore(today)) {
      return thisYear;
    }

    return DateTime(
      today.year + 1,
      milestoneDate.month,
      milestoneDate.day,
    );
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  Future<T> _run<T>(
    String errorMessage,
    Future<T> Function(Database db) action,
  ) async {
    try {
      final db = await _databaseService.database;
      return await action(db);
    } on AppException {
      rethrow;
    } catch (e) {
      throw DatabaseException(
        message: errorMessage,
        code: 'database_error',
        originalException: e is Exception ? e : null,
      );
    }
  }
}
