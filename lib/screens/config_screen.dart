import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../db/company_dao.dart';
import '../db/user_dao.dart';
import '../db/local_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final TextEditingController _cnpjController = TextEditingController();
  final CompanyDao _companyDao = CompanyDao();
  final UserDao _userDao = UserDao();
  String? _companyName;

  @override
  void initState() {
    super.initState();
    _loadLocalCompany();
  }

  Future<void> _loadLocalCompany() async {
    final c = await _companyDao.getFirst();
    if (c != null) {
      setState(() {
        _companyName = c['CEMP_NOME_FANTASIA'] as String?;
        _cnpjController.text = c['CEMP_CNPJ']?.toString() ?? '';
      });
    }
  }

  Future<void> _fetchCompany() async {
    final cnpj = _cnpjController.text.trim();
    if (cnpj.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
        const SnackBar(content: Text('Buscando empresa...')));
    try {
      final supabase = Supabase.instance.client;
      final result = await supabase
          .from('CADE_EMPRESA')
          .select(
              'CEMP_PK, CEMP_NOME_FANTASIA, CEMP_RAZAO_SOCIAL, CEMP_CNPJ, CEMP_IE')
          .eq('CEMP_CNPJ', cnpj)
          .maybeSingle();
      if (result != null) {
        await _companyDao.setCompany(result);
        final users = await supabase
            .from('CADE_USUARIO')
            .select('CUSU_PK, CUSU_USUARIO, CUSU_SENHA, CEMP_PK')
            .eq('CEMP_PK', result['CEMP_PK']);
        await _userDao.replaceAll(List<Map<String, dynamic>>.from(users));
        if (mounted) {
          setState(() {
            _companyName = result['CEMP_NOME_FANTASIA'] as String?;
          });
        }
        messenger.showSnackBar(const SnackBar(
            content: Text('Empresa configurada corretamente'),
            backgroundColor: Colors.green));
      } else {
        messenger.showSnackBar(const SnackBar(
            content: Text('Empresa não encontrada'),
            backgroundColor: Colors.red));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  /// Exports the SQLite database to a file named `erp_mobile_backup.db` in the
  /// application's documents directory or external storage if available.
  Future<void> _exportBackup() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final srcPath = await LocalDatabase.path;
      Directory? dir = await getExternalStorageDirectory();
      dir ??= await getApplicationDocumentsDirectory();
      final backupPath = p.join(dir.path, 'erp_mobile_backup.db');
      await File(srcPath).copy(backupPath);
      messenger.showSnackBar(
          SnackBar(content: Text('Backup exportado em $backupPath')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erro ao exportar: $e')));
    }
  }

  /// Imports the SQLite database from `erp_mobile_backup.db` located in the
  /// documents or external storage directory, replacing the current database.
  Future<void> _importBackup() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      Directory? dir = await getExternalStorageDirectory();
      dir ??= await getApplicationDocumentsDirectory();
      final backupPath = p.join(dir.path, 'erp_mobile_backup.db');
      final file = File(backupPath);
      if (!await file.exists()) {
        messenger.showSnackBar(
            SnackBar(content: Text('Backup não encontrado em $backupPath')));
        return;
      }
      final dbPath = await LocalDatabase.path;
      await LocalDatabase.close();
      await file.copy(dbPath);
      await LocalDatabase.instance; // reopen
      await _loadLocalCompany();
      messenger.showSnackBar(
          const SnackBar(content: Text('Backup importado com sucesso')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erro ao importar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuração')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Configuração da Empresa',
                style: TextStyle(fontSize: 20)),
            TextField(
              controller: _cnpjController,
              decoration: const InputDecoration(labelText: 'CNPJ'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            if (_companyName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Empresa: $_companyName',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 28,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchCompany,
              child: const Text('Carregar Empresa'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _exportBackup,
              child: const Text('Exportar Backup'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _importBackup,
              child: const Text('Importar Backup'),
            ),
          ],
        ),
      ),
    );
  }
}
