import 'package:sqflite/sqflite.dart';

import '../services/database_service.dart';

abstract class AppPreferenceRepository {
  Future<String?> getString(String key);
  Future<Map<String, String>> getStrings(List<String> keys);
  Future<void> setString(String key, String value);
}

class SqliteAppPreferenceRepository implements AppPreferenceRepository {
  final DatabaseService _databaseService;

  SqliteAppPreferenceRepository(this._databaseService);

  @override
  Future<String?> getString(String key) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      DatabaseService.appPreferencesTable,
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }

    return rows.first['value'] as String?;
  }

  @override
  Future<Map<String, String>> getStrings(List<String> keys) async {
    if (keys.isEmpty) {
      return const {};
    }

    final db = await _databaseService.database;
    final placeholders = List.filled(keys.length, '?').join(', ');
    final rows = await db.rawQuery(
      'SELECT key, value FROM ${DatabaseService.appPreferencesTable} WHERE key IN ($placeholders)',
      keys,
    );

    return {
      for (final row in rows)
        row['key'] as String: row['value'] as String,
    };
  }

  @override
  Future<void> setString(String key, String value) async {
    final db = await _databaseService.database;
    await db.insert(
      DatabaseService.appPreferencesTable,
      {
        'key': key,
        'value': value,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}