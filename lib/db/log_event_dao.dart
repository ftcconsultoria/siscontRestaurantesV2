import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'company_dao.dart';
import 'local_database.dart';

class LogEventDao {
  Future<Database> get _db async => await LocalDatabase.instance;
  final CompanyDao _companyDao = CompanyDao();

  Future<int?> _companyPk() async {
    final company = await _companyDao.getFirst();
    return company?['CEMP_PK'] as int?;
  }

  Future<int?> _loggedUserPk() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('logged_user_pk');
  }

  Future<void> insert({
    required String entidade,
    int? chave,
    required String tipo,
    String? tela,
    String? mensagem,
    Map<String, dynamic>? dados,
  }) async {
    final db = await _db;
    final data = <String, dynamic>{
      'LOG_ENTIDADE': entidade,
      'LOG_CHAVE': chave,
      'LOG_TIPO': tipo,
      'LOG_TELA': tela,
      'LOG_MENSAGEM': mensagem,
      'LOG_DADOS': dados != null ? jsonEncode(dados) : null,
      'LOG_DT': DateTime.now().toIso8601String(),
    };
    final cPk = await _companyPk();
    final uPk = await _loggedUserPk();
    if (cPk != null) data['CEMP_PK'] = cPk;
    if (uPk != null) data['CUSU_PK'] = uPk;
    await db.insert('SIS_LOG_EVENTO', data);
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _db;
    return db.query('SIS_LOG_EVENTO');
  }

  Future<void> deleteAll() async {
    final db = await _db;
    await db.delete('SIS_LOG_EVENTO');
  }
}
