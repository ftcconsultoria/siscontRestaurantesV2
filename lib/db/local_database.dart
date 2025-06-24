import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';

class LocalDatabase {
  static Database? _db;

  /// Returns a singleton instance of the local database.
  static Future<Database> get instance async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  /// Opens the database and creates tables on first use.
  static Future<Database> _initDb() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final path = join(documentsDir.path, 'erp_mobile.db');
    return openDatabase(
      path,
      version: 2,
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
        await db.execute('''
CREATE TABLE CADE_EMPRESA (
  CEMP_PK INTEGER PRIMARY KEY AUTOINCREMENT,
  CEMP_NOME_FANTASIA TEXT NOT NULL,
  CEMP_RAZAO_SOCIAL TEXT,
  CEMP_CNPJ TEXT,
  CEMP_IE TEXT
)
''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
CREATE TABLE CADE_EMPRESA (
  CEMP_PK INTEGER PRIMARY KEY AUTOINCREMENT,
  CEMP_NOME_FANTASIA TEXT NOT NULL,
  CEMP_RAZAO_SOCIAL TEXT,
  CEMP_CNPJ TEXT,
  CEMP_IE TEXT
)
''');
        }
      },
    );
  }
}
