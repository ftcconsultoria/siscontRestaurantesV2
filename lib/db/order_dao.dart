import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'local_database.dart';
import 'company_dao.dart';
import 'user_dao.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'order_item_dao.dart';

class OrderDao {
  Future<Database> get _db async => await LocalDatabase.instance;

  final CompanyDao _companyDao = CompanyDao();
  final UserDao _userDao = UserDao();

  Future<int?> _getCompanyPk() async {
    final company = await _companyDao.getFirst();
    return company?['CEMP_PK'] as int?;
  }

  Future<int?> _getVendorPk() async {
    final prefs = await SharedPreferences.getInstance();
    final userPk = prefs.getInt('logged_user_pk');
    if (userPk == null) return null;
    final user = await _userDao.getByPk(userPk);
    return user?['CCOT_VEND_PK'] as int?;
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _db;
    final companyPk = await _getCompanyPk();
    final rows = await db.rawQuery('''
SELECT d.PDOC_PK, d.PDOC_DT_EMISSAO, d.PDOC_VLR_TOTAL,
       d.CCOT_CNPJ, c.CCOT_NOME, d.CCOT_VEND_PK, d.PDOC_ESTADO_PEDIDO
FROM PEDI_DOCUMENTOS d
LEFT JOIN CADE_CONTATO c ON d.CCOT_CNPJ = c.CCOT_CNPJ
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
    if (!data.containsKey('PDOC_PK')) {
      data['CCOT_VEND_PK'] = data['CCOT_VEND_PK'] ?? await _getVendorPk();
      data['PDOC_ESTADO_PEDIDO'] = 'CRIADO_MOBILE';
      data['PDOC_UUID'] = const Uuid().v4();
    } else if (!data.containsKey('PDOC_UUID')) {
      data['PDOC_UUID'] = const Uuid().v4();
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

  Future<List<Map<String, dynamic>>> getPending() async {
    final db = await _db;
    final companyPk = await _getCompanyPk();
    final where = StringBuffer('(PDOC_ESTADO_PEDIDO = ? OR PDOC_ESTADO_PEDIDO IS NULL)');
    final args = <dynamic>['CRIADO_MOBILE'];
    if (companyPk != null) {
      where.write(' AND CEMP_PK = ?');
      args.add(companyPk);
    }
    return await db.query('PEDI_DOCUMENTOS', where: where.toString(), whereArgs: args);
  }

  Future<void> updateStatus(int orderPk, String status) async {
    final db = await _db;
    await db.update('PEDI_DOCUMENTOS', {'PDOC_ESTADO_PEDIDO': status},
        where: 'PDOC_PK = ?', whereArgs: [orderPk]);
  }

  Future<double> getTotalInRange(DateTime start, DateTime end) async {
    final db = await _db;
    final companyPk = await _getCompanyPk();
    final startStr = DateFormat('yyyy-MM-dd').format(start);
    final endStr = DateFormat('yyyy-MM-dd').format(end);
    final args = [startStr, endStr];
    var where = 'PDOC_DT_EMISSAO >= ? AND PDOC_DT_EMISSAO <= ?';
    if (companyPk != null) {
      where += ' AND CEMP_PK = ?';
      args.add(companyPk.toString());
    }
    final result = await db.rawQuery(
        'SELECT SUM(PDOC_VLR_TOTAL) as total FROM PEDI_DOCUMENTOS WHERE ' +
            where,
        args);
    final total = result.first['total'] as num?;
    return total?.toDouble() ?? 0.0;
  }
}
