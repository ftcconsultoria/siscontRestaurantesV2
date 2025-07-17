import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/company_dao.dart';
import '../db/user_dao.dart';
import '../db/local_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/log_event_dao.dart';
import 'log_list_screen.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final TextEditingController _cnpjController = TextEditingController();
  final CompanyDao _companyDao = CompanyDao();
  final UserDao _userDao = UserDao();
  final LogEventDao _logDao = LogEventDao();
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
    messenger
        .showSnackBar(const SnackBar(content: Text('Buscando empresa...')));
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
            .select(
                'CUSU_PK, CUSU_USUARIO, CUSU_SENHA, CEMP_PK, CCOT_VEND_PK')
            .eq('CEMP_PK', result['CEMP_PK']);
        await _userDao.replaceAll(List<Map<String, dynamic>>.from(users));
        if (mounted) {
          setState(() {
            _companyName = result['CEMP_NOME_FANTASIA'] as String?;
          });
        }
        await _registerDevice(result['CEMP_PK'] as int);
        messenger.showSnackBar(const SnackBar(
            content: Text('Empresa configurada corretamente'),
            backgroundColor: Colors.green));
        await _logDao.insert(
            entidade: 'CONFIG',
            tipo: 'CARREGAR_EMPRESA',
            tela: 'ConfigScreen',
            mensagem: 'Empresa configurada');
      } else {
        messenger.showSnackBar(const SnackBar(
            content: Text('Empresa não encontrada'),
            backgroundColor: Colors.red));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erro: $e')));
      await _logDao.insert(
          entidade: 'CONFIG',
          tipo: 'ERRO_EMPRESA',
          tela: 'ConfigScreen',
          mensagem: e.toString());
    }
  }

  Future<void> _registerDevice(int companyPk) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var uuid = prefs.getString('device_uuid');
      if (uuid == null) {
        uuid = const Uuid().v4();
        await prefs.setString('device_uuid', uuid);
      }
      final deviceInfo = DeviceInfoPlugin();
      String model = '';
      String system = '';
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        model = info.model;
        system = 'Android ${info.version.release}';
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        model = info.utsname.machine;
        system = '${info.systemName} ${info.systemVersion}';
      } else {
        model = Platform.operatingSystem;
        system = Platform.operatingSystemVersion;
      }
      final supabase = Supabase.instance.client;
      final data = {
        'uuid': uuid,
        'aparelho': model,
        'sistema': system,
        'CEMP_PK': companyPk,
      };
      try {
        await supabase.from('dispositivos_autorizados').upsert(data);
      } catch (e, s) {
        await _logDao.insert(
          entidade: 'CONFIG',
          tipo: 'ERRO_EXPORT',
          tela: 'ConfigScreen',
          mensagem: e.toString(),
          dados: {
            'tabela': 'dispositivos_autorizados',
            'objeto': data,
            'stack': s.toString(),
          },
        );
      }
    } catch (_) {}
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
      await Share.shareXFiles([XFile(backupPath)],
          text: 'SISCONT Restaurantes - backup do banco de dados');
      await _logDao.insert(
          entidade: 'CONFIG',
          tipo: 'EXPORT_BACKUP',
          tela: 'ConfigScreen',
          mensagem: 'Backup exportado');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erro ao exportar: $e')));
      await _logDao.insert(
          entidade: 'CONFIG',
          tipo: 'ERRO_EXPORT',
          tela: 'ConfigScreen',
          mensagem: e.toString());
    }
  }

  /// Imports the SQLite database from the default backup location and
  /// replaces the current database with it.
  Future<void> _importBackup() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      Directory? dir = await getExternalStorageDirectory();
      dir ??= await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'erp_mobile_backup.db'));
      if (!await file.exists()) {
        messenger.showSnackBar(
            SnackBar(content: Text('Backup não encontrado em ${file.path}')));
        return;
      }
      final dbPath = await LocalDatabase.path;
      await LocalDatabase.close();
      await file.copy(dbPath);
      await LocalDatabase.instance; // reopen
      await _loadLocalCompany();
      messenger.showSnackBar(
          const SnackBar(content: Text('Backup importado com sucesso')));
      await _logDao.insert(
          entidade: 'CONFIG',
          tipo: 'IMPORT_BACKUP',
          tela: 'ConfigScreen',
          mensagem: 'Backup importado');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erro ao importar: $e')));
      await _logDao.insert(
          entidade: 'CONFIG',
          tipo: 'ERRO_IMPORT',
          tela: 'ConfigScreen',
          mensagem: e.toString());
    }
  }

  void _openLogs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LogListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuração')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Configuração da Empresa',
                style: TextStyle(fontSize: 20),
              ),
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
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _openLogs,
                child: const Text('Ver Logs'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
