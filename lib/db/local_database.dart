import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  static Database? _db;

  /// Returns the path to the database file.
  static Future<String> get path async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return join(documentsDir.path, 'erp_mobile.db');
  }

  /// Closes the database if it's open.
  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  /// Returns a singleton instance of the local database.
  static Future<Database> get instance async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  /// Opens the database and creates tables on first use.
  static Future<Database> _initDb() async {
    final dbPath = await path;
    return openDatabase(
      dbPath,
      version: 13,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE ESTQ_PRODUTO (
  EPRO_PK INTEGER PRIMARY KEY,
  EPRO_DESCRICAO TEXT,
  EPRO_VLR_VAREJO REAL,
  EPRO_ESTQ_ATUAL REAL,
  EPRO_COD_EAN TEXT,
  CEMP_PK INTEGER
)
''');
        await db.execute('''
CREATE TABLE ESTQ_PRODUTO_FOTO (
  EPRO_FOTO_PK INTEGER PRIMARY KEY AUTOINCREMENT,
  EPRO_PK INTEGER,
  EPRO_FOTO_URL TEXT,
  EPRO_FOTO_PATH TEXT
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
        await db.execute('''
CREATE TABLE CADE_USUARIO (
  CUSU_PK INTEGER PRIMARY KEY AUTOINCREMENT,
  CUSU_USUARIO TEXT NOT NULL,
  CUSU_SENHA TEXT,
  CEMP_PK INTEGER,
  CCOT_VEND_PK INTEGER
)
''');
        await db.execute('''
CREATE TABLE CADE_CONTATO (
  CCOT_PK INTEGER PRIMARY KEY AUTOINCREMENT,
  CCOT_NOME TEXT NOT NULL,
  CCOT_FANTASIA TEXT,
  CCOT_CNPJ TEXT,
  CCOT_IE TEXT,
  CCOT_END_CEP TEXT,
  CCOT_END_NOME_LOGRADOURO TEXT,
  CCOT_END_COMPLEMENTO TEXT,
  CCOT_END_QUADRA TEXT,
  CCOT_END_LOTE TEXT,
  CCOT_END_NUMERO TEXT,
  CCOT_END_BAIRRO TEXT,
  CCOT_END_MUNICIPIO TEXT,
  CCOT_END_CODIGO_IBGE TEXT,
  CCOT_END_UF TEXT,
  CCOT_END_LAT REAL,
  CCOT_END_LON REAL,
  CEMP_PK INTEGER,
  CCOT_TP_PESSOA TEXT
)
''');
        await db.execute('''
CREATE TABLE PEDI_DOCUMENTOS (
  PDOC_PK INTEGER PRIMARY KEY AUTOINCREMENT,
  PDOC_UUID TEXT,
  CEMP_PK INTEGER NOT NULL,
  PDOC_DT_EMISSAO TEXT,
  PDOC_VLR_TOTAL REAL,
  CCOT_PK INTEGER,
  CCOT_VEND_PK INTEGER,
  PDOC_ESTADO_PEDIDO TEXT,
  FOREIGN KEY(CCOT_PK) REFERENCES CADE_CONTATO(CCOT_PK),
  FOREIGN KEY(CEMP_PK) REFERENCES CADE_EMPRESA(CEMP_PK)
)
''');
        await db.execute('''
CREATE TABLE PEDI_ITENS (
  PITEN_PK INTEGER PRIMARY KEY AUTOINCREMENT,
  PDOC_UUID TEXT,
  PDOC_PK INTEGER NOT NULL,
  EPRO_PK INTEGER,
  PITEN_QTD REAL,
  PITEN_VLR_UNITARIO REAL,
  PITEN_VLR_TOTAL REAL,
  FOREIGN KEY(EPRO_PK) REFERENCES ESTQ_PRODUTO(EPRO_PK),
  FOREIGN KEY(PDOC_PK) REFERENCES PEDI_DOCUMENTOS(PDOC_PK)
)
''');
        await db.execute('''
CREATE TABLE SIS_LOG_EVENTO (
  LOG_PK INTEGER PRIMARY KEY AUTOINCREMENT,
  CEMP_PK INTEGER NOT NULL,
  CUSU_PK INTEGER,
  LOG_ENTIDADE TEXT NOT NULL,
  LOG_CHAVE INTEGER,
  LOG_TIPO TEXT NOT NULL,
  LOG_TELA TEXT,
  LOG_MENSAGEM TEXT,
  LOG_DADOS TEXT,
  LOG_DT TEXT DEFAULT CURRENT_TIMESTAMP
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
        if (oldVersion < 3) {
          await db
              .execute('ALTER TABLE ESTQ_PRODUTO ADD COLUMN CEMP_PK INTEGER');
        }
        if (oldVersion < 4) {
          await db.execute('''
CREATE TABLE CADE_USUARIO (
  CUSU_PK INTEGER PRIMARY KEY AUTOINCREMENT,
  CUSU_USUARIO TEXT NOT NULL,
  CUSU_SENHA TEXT,
  CEMP_PK INTEGER,
  CCOT_VEND_PK INTEGER
)
''');
        }
        if (oldVersion < 5) {
          await db.execute('''
CREATE TABLE CADE_CONTATO (
  CCOT_PK INTEGER PRIMARY KEY AUTOINCREMENT,
  CCOT_NOME TEXT NOT NULL,
  CCOT_FANTASIA TEXT,
  CCOT_CNPJ TEXT,
  CCOT_IE TEXT,
  CCOT_END_CEP TEXT,
  CCOT_END_NOME_LOGRADOURO TEXT,
  CCOT_END_COMPLEMENTO TEXT,
  CCOT_END_QUADRA TEXT,
  CCOT_END_LOTE TEXT,
  CCOT_END_NUMERO TEXT,
  CCOT_END_BAIRRO TEXT,
  CCOT_END_MUNICIPIO TEXT,
  CCOT_END_CODIGO_IBGE TEXT,
  CCOT_END_UF TEXT,
  CEMP_PK INTEGER,
          CCOT_TP_PESSOA TEXT
)
''');
        }
        if (oldVersion < 6) {
          await db.execute('''
CREATE TABLE PEDI_DOCUMENTOS (
  PDOC_PK INTEGER PRIMARY KEY AUTOINCREMENT,
  PDOC_UUID TEXT,
  CEMP_PK INTEGER NOT NULL,
  PDOC_DT_EMISSAO TEXT,
  PDOC_VLR_TOTAL REAL,
  CCOT_PK INTEGER,
  CCOT_VEND_PK INTEGER,
  FOREIGN KEY(CCOT_PK) REFERENCES CADE_CONTATO(CCOT_PK),
  FOREIGN KEY(CEMP_PK) REFERENCES CADE_EMPRESA(CEMP_PK)
)''');
        }
        if (oldVersion < 7) {
          await db.execute('''
CREATE TABLE PEDI_ITENS (
  PITEN_PK INTEGER PRIMARY KEY AUTOINCREMENT,
  PDOC_UUID TEXT,
  PDOC_PK INTEGER NOT NULL,
  EPRO_PK INTEGER,
  PITEN_QTD REAL,
  PITEN_VLR_UNITARIO REAL,
  PITEN_VLR_TOTAL REAL,
  FOREIGN KEY(EPRO_PK) REFERENCES ESTQ_PRODUTO(EPRO_PK),
  FOREIGN KEY(PDOC_PK) REFERENCES PEDI_DOCUMENTOS(PDOC_PK)
)''');
        }
        if (oldVersion < 8) {
          await db.execute(
              'ALTER TABLE CADE_CONTATO ADD COLUMN CCOT_END_LAT REAL');
          await db.execute(
              'ALTER TABLE CADE_CONTATO ADD COLUMN CCOT_END_LON REAL');
        }
        if (oldVersion < 9) {
          await db.execute(
              'ALTER TABLE ESTQ_PRODUTO_FOTO ADD COLUMN EPRO_FOTO_PATH TEXT');
        }
        if (oldVersion < 10) {
          await db.execute(
              'ALTER TABLE CADE_USUARIO ADD COLUMN CCOT_VEND_PK INTEGER');
          await db.execute(
              'ALTER TABLE PEDI_DOCUMENTOS ADD COLUMN CCOT_VEND_PK INTEGER');
        }
        if (oldVersion < 11) {
          await db.execute(
              'ALTER TABLE PEDI_DOCUMENTOS ADD COLUMN PDOC_ESTADO_PEDIDO TEXT');
        }
        if (oldVersion < 12) {
          await db.execute('''
CREATE TABLE SIS_LOG_EVENTO (
  LOG_PK INTEGER PRIMARY KEY AUTOINCREMENT,
  CEMP_PK INTEGER NOT NULL,
  CUSU_PK INTEGER,
  LOG_ENTIDADE TEXT NOT NULL,
  LOG_CHAVE INTEGER,
  LOG_TIPO TEXT NOT NULL,
  LOG_TELA TEXT,
  LOG_MENSAGEM TEXT,
  LOG_DADOS TEXT,
  LOG_DT TEXT DEFAULT CURRENT_TIMESTAMP
)''');
        }
        if (oldVersion < 13) {
          await db.execute('ALTER TABLE PEDI_DOCUMENTOS ADD COLUMN PDOC_UUID TEXT');
          await db.execute('ALTER TABLE PEDI_ITENS ADD COLUMN PDOC_UUID TEXT');
        }
      },
    );
  }
}
