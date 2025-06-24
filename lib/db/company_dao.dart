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

  /// Deletes a company by its primary key.
  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('CADE_EMPRESA', where: 'CEMP_PK = ?', whereArgs: [id]);
  }
}
