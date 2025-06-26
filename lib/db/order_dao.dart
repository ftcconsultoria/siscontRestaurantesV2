import 'package:sqflite/sqflite.dart';
import 'local_database.dart';
import 'company_dao.dart';

import 'order_item_dao.dart';

class OrderDao {
  Future<Database> get _db async => await LocalDatabase.instance;

  final CompanyDao _companyDao = CompanyDao();

  Future<int?> _getCompanyPk() async {
    final company = await _companyDao.getFirst();
    return company?['CEMP_PK'] as int?;
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _db;
    final companyPk = await _getCompanyPk();
    final rows = await db.rawQuery('''
SELECT d.PDOC_PK, d.PDOC_DT_EMISSAO, d.PDOC_VLR_TOTAL,
       d.CCOT_PK, c.CCOT_NOME
FROM PEDI_DOCUMENTOS d
LEFT JOIN CADE_CONTATO c ON d.CCOT_PK = c.CCOT_PK
${companyPk != null ? 'WHERE d.CEMP_PK = ?' : ''}
ORDER BY d.PDOC_PK DESC
''', companyPk != null ? [companyPk] : null);
    return rows;
  }

  final OrderItemDao _itemDao = OrderItemDao();

  Future<int> insertOrUpdate(Map<String, dynamic> data) async {
    final db = await _db;
    final companyPk = data['CEMP_PK'] ?? await _getCompanyPk();
    if (companyPk != null) {
      data['CEMP_PK'] = companyPk;
    }

    if (data.containsKey('PDOC_PK')) {
      await db.update(
        'PEDI_DOCUMENTOS',
        data,
        where: 'PDOC_PK = ?',
        whereArgs: [data['PDOC_PK']],
      );
      return data['PDOC_PK'] as int;
    }

    final id = await db.insert(
      'PEDI_DOCUMENTOS',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await _itemDao.deleteByOrder(id);
    await db.delete('PEDI_DOCUMENTOS', where: 'PDOC_PK = ?', whereArgs: [id]);
  }

  Future<void> replaceAll(List<Map<String, dynamic>> orders) async {
    final db = await _db;
    final batch = db.batch();
    batch.delete('PEDI_DOCUMENTOS');
    for (final o in orders) {
      batch.insert('PEDI_DOCUMENTOS', o,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}
