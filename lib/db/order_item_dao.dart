import 'package:sqflite/sqflite.dart';
import 'local_database.dart';

class OrderItemDao {
  Future<Database> get _db async => await LocalDatabase.instance;

  Future<List<Map<String, dynamic>>> getByOrder(int orderPk) async {
    final db = await _db;
    return await db.rawQuery('''
SELECT i.PITEN_PK, i.PDOC_PK, i.EPRO_PK, i.PITEN_QTD,
       i.PITEN_VLR_UNITARIO, i.PITEN_VLR_TOTAL,
       p.EPRO_DESCRICAO, p.EPRO_COD_EAN, p.EPRO_ESTQ_ATUAL
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
      final data = <String, dynamic>{
        'EPRO_PK': item['EPRO_PK'],
        'PITEN_QTD': item['PITEN_QTD'],
        'PITEN_VLR_UNITARIO': item['PITEN_VLR_UNITARIO'],
        'PITEN_VLR_TOTAL': item['PITEN_VLR_TOTAL'],
        'PDOC_PK': orderPk,
      };
      batch.insert('PEDI_ITENS', data);
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteByOrder(int orderPk) async {
    final db = await _db;
    await db.delete('PEDI_ITENS', where: 'PDOC_PK = ?', whereArgs: [orderPk]);
  }

  Future<void> replaceAll(List<Map<String, dynamic>> items) async {
    final db = await _db;
    final batch = db.batch();
    batch.delete('PEDI_ITENS');
    for (final item in items) {
      batch.insert('PEDI_ITENS', item,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}
