import 'package:sqflite/sqflite.dart';
import 'local_database.dart';

class UserDao {
  /// Shortcut to obtain the opened database instance.
  Future<Database> get _db async => await LocalDatabase.instance;

  /// Returns all users sorted by username.
  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _db;
    return await db.query('CADE_USUARIO', orderBy: 'CUSU_USUARIO');
  }

  /// Inserts or updates a user record.
  Future<void> insertOrUpdate(Map<String, dynamic> data) async {
    final db = await _db;
    await db.insert(
      'CADE_USUARIO',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Replaces all existing users with the provided list.
  Future<void> replaceAll(List<Map<String, dynamic>> users) async {
    final db = await _db;
    final batch = db.batch();
    batch.delete('CADE_USUARIO');
    for (final u in users) {
      batch.insert('CADE_USUARIO', u,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}
