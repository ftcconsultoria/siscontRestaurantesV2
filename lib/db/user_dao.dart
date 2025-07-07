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

  /// Returns a user matching the provided credentials or null if none match.
  Future<Map<String, dynamic>?> getByCredentials(
      String username, String password) async {
    final db = await _db;
    final result = await db.query(
      'CADE_USUARIO',
      where: 'CUSU_USUARIO = ? AND CUSU_SENHA = ?',
      whereArgs: [username, password],
      limit: 1,
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  /// Returns a user by its primary key or null if not found.
  Future<Map<String, dynamic>?> getByPk(int pk) async {
    final db = await _db;
    final result = await db.query(
      'CADE_USUARIO',
      where: 'CUSU_PK = ?',
      whereArgs: [pk],
      limit: 1,
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }
}
