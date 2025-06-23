import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';

class LocalDatabase {
  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final path = join(documentsDir.path, 'erp_mobile.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE ESTQ_PRODUTO (
  EPRO_PK INTEGER PRIMARY KEY,
  EPRO_DESCRICAO TEXT,
  EPRO_VLR_VAREJO REAL,
  EPRO_ESTQ_ATUAL REAL,
  EPRO_COD_EAN TEXT
)
''');
        await db.execute('''
CREATE TABLE ESTQ_PRODUTO_FOTO (
  EPRO_FOTO_PK INTEGER PRIMARY KEY AUTOINCREMENT,
  EPRO_PK INTEGER,
  EPRO_FOTO_URL TEXT
)
''');
      },
    );
  }
}
