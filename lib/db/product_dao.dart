import 'package:sqflite/sqflite.dart';
import 'local_database.dart';

class ProductDao {
  /// Shortcut to obtain the opened database instance.
  Future<Database> get _db async => await LocalDatabase.instance;

  /// Returns all products sorted by description.
  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _db;
    return await db.query('ESTQ_PRODUTO', orderBy: 'EPRO_DESCRICAO');
  }

  /// Inserts or updates a product record.
  Future<void> insertOrUpdate(Map<String, dynamic> data) async {
    final db = await _db;
    await db.insert(
      'ESTQ_PRODUTO',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deletes a product by its primary key.
  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('ESTQ_PRODUTO', where: 'EPRO_PK = ?', whereArgs: [id]);
  }

  /// Replaces all existing products with the provided list.
  Future<void> replaceAll(List<Map<String, dynamic>> products) async {
    final db = await _db;
    final batch = db.batch();
    batch.delete('ESTQ_PRODUTO');
    for (final p in products) {
      batch.insert('ESTQ_PRODUTO', p,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}
