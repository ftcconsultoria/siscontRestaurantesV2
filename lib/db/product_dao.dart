import 'package:sqflite/sqflite.dart';
import 'local_database.dart';
import 'company_dao.dart';

class ProductDao {
  /// Shortcut to obtain the opened database instance.
  Future<Database> get _db async => await LocalDatabase.instance;

  final CompanyDao _companyDao = CompanyDao();

  Future<int?> _getCompanyPk() async {
    final company = await _companyDao.getFirst();
    return company?['CEMP_PK'] as int?;
  }

  /// Returns all products joined with their photos, sorted by description.
  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _db;
    final companyPk = await _getCompanyPk();
    final rows = await db.rawQuery('''
SELECT p.EPRO_PK, p.EPRO_DESCRICAO, p.EPRO_VLR_VAREJO,
       p.EPRO_ESTQ_ATUAL, p.EPRO_COD_EAN, p.CEMP_PK,
       f.EPRO_FOTO_PK AS FOTO_PK, f.EPRO_FOTO_URL, f.EPRO_FOTO_PATH
FROM ESTQ_PRODUTO p
LEFT JOIN ESTQ_PRODUTO_FOTO f ON p.EPRO_PK = f.EPRO_PK
${companyPk != null ? 'WHERE p.CEMP_PK = ?' : ''}
ORDER BY p.EPRO_DESCRICAO
''', companyPk != null ? [companyPk] : null);

    final Map<int, Map<String, dynamic>> products = {};

    for (final r in rows) {
      final productPk = r['EPRO_PK'] as int;
      final fotoPk = r['FOTO_PK'];
      final fotoUrl = r['EPRO_FOTO_URL'];
      final fotoPath = r['EPRO_FOTO_PATH'];

      products.putIfAbsent(productPk, () {
        return {
          'EPRO_PK': r['EPRO_PK'],
          'EPRO_DESCRICAO': r['EPRO_DESCRICAO'],
          'EPRO_VLR_VAREJO': r['EPRO_VLR_VAREJO'],
          'EPRO_ESTQ_ATUAL': r['EPRO_ESTQ_ATUAL'],
          'EPRO_COD_EAN': r['EPRO_COD_EAN'],
          'CEMP_PK': r['CEMP_PK'],
          'ESTQ_PRODUTO_FOTO': <Map<String, dynamic>>[],
        };
      });

      if (fotoPk != null || fotoUrl != null) {
        (products[productPk]!['ESTQ_PRODUTO_FOTO'] as List)
            .add({
          'EPRO_FOTO_PK': fotoPk,
          'EPRO_PK': productPk,
          'EPRO_FOTO_URL': fotoUrl,
          'EPRO_FOTO_PATH': fotoPath,
        });
      }
    }

    return products.values.toList();
  }

  /// Inserts or updates a product record.
  Future<void> insertOrUpdate(Map<String, dynamic> data) async {
    final db = await _db;
    final companyPk = data['CEMP_PK'] ?? await _getCompanyPk();
    if (companyPk != null) {
      data['CEMP_PK'] = companyPk;
    }
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

  /// Retrieves the photo associated with the given product.
  Future<Map<String, dynamic>?> getPhoto(int productPk) async {
    final db = await _db;
    final result = await db.query('ESTQ_PRODUTO_FOTO',
        where: 'EPRO_PK = ?', whereArgs: [productPk], limit: 1);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  /// Inserts or updates the photo record for a product.
  Future<void> upsertPhoto(int productPk,
      {String? url, String? path}) async {
    final db = await _db;
    await db.delete('ESTQ_PRODUTO_FOTO',
        where: 'EPRO_PK = ?', whereArgs: [productPk]);
    await db.insert('ESTQ_PRODUTO_FOTO', {
      'EPRO_PK': productPk,
      'EPRO_FOTO_URL': url,
      'EPRO_FOTO_PATH': path,
    });
  }

  /// Returns all photo records.
  Future<List<Map<String, dynamic>>> getAllPhotos() async {
    final db = await _db;
    final companyPk = await _getCompanyPk();
    if (companyPk != null) {
      return await db.rawQuery('''
SELECT f.* FROM ESTQ_PRODUTO_FOTO f
JOIN ESTQ_PRODUTO p ON f.EPRO_PK = p.EPRO_PK
WHERE p.CEMP_PK = ?
''', [companyPk]);
    }
    return await db.query('ESTQ_PRODUTO_FOTO');
  }

  /// Replaces all existing photos with the provided list.
  Future<void> replaceAllPhotos(List<Map<String, dynamic>> photos) async {
    final db = await _db;
    final batch = db.batch();
    batch.delete('ESTQ_PRODUTO_FOTO');
    for (final p in photos) {
      batch.insert('ESTQ_PRODUTO_FOTO', p,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Deletes the photo associated with the given product.
  Future<void> deletePhoto(int productPk) async {
    final db = await _db;
    await db.delete('ESTQ_PRODUTO_FOTO', where: 'EPRO_PK = ?', whereArgs: [productPk]);
  }
}
