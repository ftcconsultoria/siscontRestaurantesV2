import 'package:sqflite/sqflite.dart';
import 'local_database.dart';

class OrderItemDao {
  Future<Database> get _db async => await LocalDatabase.instance;

  Future<List<Map<String, dynamic>>> getByOrder(int orderPk) async {
    final db = await _db;
    return await db.rawQuery('''
SELECT i.PITEN_PK, i.PDOC_PK, i.EPRO_PK, i.PITEN_QTD,
       i.PITEN_VLR_UNITARIO, i.PITEN_VLR_TOTAL, p.EPRO_DESCRICAO
FROM PEDI_ITENS i
JOIN ESTQ_PRODUTO p ON i.EPRO_PK = p.EPRO_PK
WHERE i.PDOC_PK = ?
''', [orderPk]);
  }

  Future<void> replaceItems(int orderPk, List<Map<String, dynamic>> items) async {
    final db = await _db;
    final batch = db.batch();
    batch.delete('PEDI_ITENS', where: 'PDOC_PK = ?', whereArgs: [orderPk]);
    for (final item in items) {
      final data = Map<String, dynamic>.from(item)
        ..['PDOC_PK'] = orderPk;
      batch.insert('PEDI_ITENS', data);
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteByOrder(int orderPk) async {
    final db = await _db;
    await db.delete('PEDI_ITENS', where: 'PDOC_PK = ?', whereArgs: [orderPk]);
  }
}
