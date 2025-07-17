import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  static Database? _db;

  static Future<String> get path async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return join(documentsDir.path, 'erp_mobile.db');
  }

  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await path;
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: _createSchema,
      onUpgrade: (db, oldVersion, newVersion) async {
        await _dropTables(db);
        await _createSchema(db, newVersion);
      },
    );
  }

  static Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
CREATE TABLE cade_empresa (
  cemp_pk INTEGER PRIMARY KEY AUTOINCREMENT,
  cemp_nome_fantasia TEXT NOT NULL,
  cemp_razao_social TEXT,
  cemp_cnpj TEXT,
  cemp_ie TEXT
)''');
    await db.execute('''
CREATE TABLE cade_mesa (
  cmes_pk INTEGER PRIMARY KEY AUTOINCREMENT,
  cemp_pk INTEGER NOT NULL,
  cmes_numero INTEGER NOT NULL,
  cmes_status TEXT NOT NULL,
  cmes_descricao TEXT,
  FOREIGN KEY(cemp_pk) REFERENCES cade_empresa(cemp_pk) ON DELETE CASCADE
)''');
    await db.execute('''
CREATE TABLE estq_grupo (
  egru_pk INTEGER PRIMARY KEY AUTOINCREMENT,
  cemp_pk INTEGER NOT NULL,
  egru_descricao TEXT NOT NULL,
  FOREIGN KEY(cemp_pk) REFERENCES cade_empresa(cemp_pk) ON DELETE CASCADE
)''');
    await db.execute('''
CREATE TABLE estq_produto (
  epro_pk INTEGER PRIMARY KEY AUTOINCREMENT,
  cemp_pk INTEGER NOT NULL,
  egru_pk INTEGER NOT NULL,
  epro_descricao TEXT NOT NULL,
  epro_vlr_varejo REAL NOT NULL,
  epro_ativo INTEGER DEFAULT 1,
  FOREIGN KEY(cemp_pk) REFERENCES cade_empresa(cemp_pk) ON DELETE CASCADE,
  FOREIGN KEY(egru_pk) REFERENCES estq_grupo(egru_pk) ON DELETE CASCADE
)''');
    await db.execute('''
CREATE TABLE cade_usuario (
  cusu_pk INTEGER,
  cemp_pk INTEGER NOT NULL,
  ccot_vend_pk INTEGER,
  cusu_usuario TEXT NOT NULL,
  cusu_senha TEXT,
  PRIMARY KEY (cusu_pk, cemp_pk),
  FOREIGN KEY(cemp_pk) REFERENCES cade_empresa(cemp_pk) ON DELETE CASCADE
)''');
    await db.execute('''
CREATE TABLE pedi_documentos (
  pdoc_pk INTEGER PRIMARY KEY AUTOINCREMENT,
  cemp_pk INTEGER NOT NULL,
  cmes_pk INTEGER,
  pdoc_dt_emissao TEXT NOT NULL,
  pdoc_dt_conclusao TEXT,
  pdoc_status TEXT NOT NULL,
  cusu_pk INTEGER,
  FOREIGN KEY(cemp_pk) REFERENCES cade_empresa(cemp_pk) ON DELETE CASCADE,
  FOREIGN KEY(cmes_pk) REFERENCES cade_mesa(cmes_pk) ON DELETE SET NULL,
  FOREIGN KEY(cusu_pk, cemp_pk) REFERENCES cade_usuario(cusu_pk, cemp_pk) ON DELETE SET NULL
)''');
    await db.execute('''
CREATE TABLE pedi_itens (
  piten_pk INTEGER PRIMARY KEY AUTOINCREMENT,
  pdoc_pk INTEGER NOT NULL,
  epro_pk INTEGER NOT NULL,
  piten_qtd INTEGER NOT NULL,
  piten_obs TEXT,
  piten_status TEXT,
  piten_dt_enviado TEXT,
  FOREIGN KEY(pdoc_pk) REFERENCES pedi_documentos(pdoc_pk) ON DELETE CASCADE,
  FOREIGN KEY(epro_pk) REFERENCES estq_produto(epro_pk) ON DELETE CASCADE
)''');
    await db.execute('''
CREATE TABLE cade_pagamento (
  cpag_pk INTEGER PRIMARY KEY AUTOINCREMENT,
  cemp_pk INTEGER NOT NULL,
  cpag_descricao TEXT NOT NULL,
  FOREIGN KEY(cemp_pk) REFERENCES cade_empresa(cemp_pk) ON DELETE CASCADE
)''');
    await db.execute('''
CREATE TABLE flux_documentos_pagamentos (
  fdpa_pk INTEGER PRIMARY KEY AUTOINCREMENT,
  cemp_pk INTEGER NOT NULL,
  cpag_pk INTEGER NOT NULL,
  pdoc_pk INTEGER NOT NULL,
  fdpa_valor REAL NOT NULL,
  pago_em TEXT,
  FOREIGN KEY(cemp_pk) REFERENCES cade_empresa(cemp_pk) ON DELETE CASCADE,
  FOREIGN KEY(cpag_pk) REFERENCES cade_pagamento(cpag_pk) ON DELETE SET NULL,
  FOREIGN KEY(pdoc_pk) REFERENCES pedi_documentos(pdoc_pk) ON DELETE CASCADE
)''');
  }

  static Future<void> _dropTables(Database db) async {
    await db.execute('DROP TABLE IF EXISTS flux_documentos_pagamentos');
    await db.execute('DROP TABLE IF EXISTS cade_pagamento');
    await db.execute('DROP TABLE IF EXISTS pedi_itens');
    await db.execute('DROP TABLE IF EXISTS pedi_documentos');
    await db.execute('DROP TABLE IF EXISTS cade_usuario');
    await db.execute('DROP TABLE IF EXISTS estq_produto');
    await db.execute('DROP TABLE IF EXISTS estq_grupo');
    await db.execute('DROP TABLE IF EXISTS cade_mesa');
    await db.execute('DROP TABLE IF EXISTS cade_empresa');
  }
}
