import 'package:sqflite/sqflite.dart';
import 'local_database.dart';
import 'company_dao.dart';

class ContactDao {
  /// Shortcut to obtain the opened database instance.
  Future<Database> get _db async => await LocalDatabase.instance;

  final CompanyDao _companyDao = CompanyDao();

  Future<int?> _getCompanyPk() async {
    final company = await _companyDao.getFirst();
    return company?['CEMP_PK'] as int?;
  }

  /// Returns all contacts sorted by name.
  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _db;
    final companyPk = await _getCompanyPk();
    if (companyPk != null) {
      return await db.query('CADE_CONTATO',
          where: 'CEMP_PK = ?',
          whereArgs: [companyPk],
          orderBy: 'CCOT_NOME');
    }
    return await db.query('CADE_CONTATO', orderBy: 'CCOT_NOME');
  }

  /// Inserts or updates a contact record.
  Future<void> insertOrUpdate(Map<String, dynamic> data) async {
    final db = await _db;
    final companyPk = data['CEMP_PK'] ?? await _getCompanyPk();
    if (companyPk != null) {
      data['CEMP_PK'] = companyPk;
    }
    await db.insert('CADE_CONTATO', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Deletes a contact by its primary key.
  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('CADE_CONTATO', where: 'CCOT_PK = ?', whereArgs: [id]);
  }

  /// Replaces all existing contacts with the provided list.
  Future<void> replaceAll(List<Map<String, dynamic>> contacts) async {
    final db = await _db;
    final batch = db.batch();
    batch.delete('CADE_CONTATO');
    for (final c in contacts) {
      batch.insert('CADE_CONTATO', c,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Returns a contact by its primary key or null if not found.
  Future<Map<String, dynamic>?> getByPk(int pk) async {
    final db = await _db;
    final companyPk = await _getCompanyPk();
    final result = await db.query(
      'CADE_CONTATO',
      where: companyPk != null ? 'CCOT_PK = ? AND CEMP_PK = ?' : 'CCOT_PK = ?',
      whereArgs: companyPk != null ? [pk, companyPk] : [pk],
      limit: 1,
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }
}
