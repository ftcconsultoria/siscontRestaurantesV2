import 'package:sqflite/sqflite.dart';
import 'local_database.dart';

class CompanyDao {
  /// Shortcut to obtain the opened database instance.
  Future<Database> get _db async => await LocalDatabase.instance;

  /// Returns all companies sorted by their trade name.
  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _db;
    return await db.query('CADE_EMPRESA', orderBy: 'CEMP_NOME_FANTASIA');
  }

  /// Inserts or updates a company record.
  Future<void> insertOrUpdate(Map<String, dynamic> data) async {
    final db = await _db;
    await db.insert(
      'CADE_EMPRESA',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Replaces any existing company with the provided one.
  Future<void> setCompany(Map<String, dynamic> data) async {
    final db = await _db;
    final batch = db.batch();
    batch.delete('CADE_EMPRESA');
    batch.insert('CADE_EMPRESA', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
    await batch.commit(noResult: true);
  }

  /// Deletes a company by its primary key.
  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('CADE_EMPRESA', where: 'CEMP_PK = ?', whereArgs: [id]);
  }

  /// Returns the first company record or null if none exist.
  Future<Map<String, dynamic>?> getFirst() async {
    final db = await _db;
    final result = await db.query('CADE_EMPRESA', limit: 1);
    if (result.isNotEmpty) return result.first;
    return null;
  }
}
