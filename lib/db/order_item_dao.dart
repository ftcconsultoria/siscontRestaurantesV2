import 'package:sqflite/sqflite.dart';
import 'local_database.dart';
import 'package:uuid/uuid.dart';

class OrderItemDao {
  Future<Database> get _db async => await LocalDatabase.instance;

  Future<List<Map<String, dynamic>>> getByOrder(int orderPk) async {
    final db = await _db;
    return await db.rawQuery('''
SELECT i.PITEN_PK, i.PDOC_UUID, i.PDOC_PK, i.EPRO_PK, i.PITEN_QTD,
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

    // restore stock from current items
    final existing = await db.query('PEDI_ITENS',
        where: 'PDOC_PK = ?', whereArgs: [orderPk]);
    for (final item in existing) {
      final pk = item['EPRO_PK'] as int?;
      final qty = (item['PITEN_QTD'] as num?)?.toDouble() ?? 0;
      if (pk != null) {
        batch.rawUpdate(
          'UPDATE ESTQ_PRODUTO SET EPRO_ESTQ_ATUAL = (EPRO_ESTQ_ATUAL + ?) WHERE EPRO_PK = ?',
          [qty, pk],
        );
      }
    }

    batch.delete('PEDI_ITENS', where: 'PDOC_PK = ?', whereArgs: [orderPk]);

    for (final item in items) {
      final data = <String, dynamic>{
        'EPRO_PK': item['EPRO_PK'],
        'PITEN_QTD': item['PITEN_QTD'],
        'PITEN_VLR_UNITARIO': item['PITEN_VLR_UNITARIO'],
        'PITEN_VLR_TOTAL': item['PITEN_VLR_TOTAL'],
        'PDOC_PK': orderPk,
        'PDOC_UUID': item['PDOC_UUID'] ?? const Uuid().v4(),
      };
      batch.insert('PEDI_ITENS', data);

      final pk = data['EPRO_PK'] as int?;
      final qty = (data['PITEN_QTD'] as num?)?.toDouble() ?? 0;
      if (pk != null) {
        batch.rawUpdate(
          'UPDATE ESTQ_PRODUTO SET EPRO_ESTQ_ATUAL = (EPRO_ESTQ_ATUAL - ?) WHERE EPRO_PK = ?',
          [qty, pk],
        );
      }
    }

    await batch.commit(noResult: true);
  }

  Future<void> deleteByOrder(int orderPk) async {
    final db = await _db;
    final items = await db.query('PEDI_ITENS',
        where: 'PDOC_PK = ?', whereArgs: [orderPk]);
    final batch = db.batch();
    for (final item in items) {
      final pk = item['EPRO_PK'] as int?;
      final qty = (item['PITEN_QTD'] as num?)?.toDouble() ?? 0;
      if (pk != null) {
        batch.rawUpdate(
          'UPDATE ESTQ_PRODUTO SET EPRO_ESTQ_ATUAL = (EPRO_ESTQ_ATUAL + ?) WHERE EPRO_PK = ?',
          [qty, pk],
        );
      }
    }
    batch.delete('PEDI_ITENS', where: 'PDOC_PK = ?', whereArgs: [orderPk]);
    await batch.commit(noResult: true);
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
