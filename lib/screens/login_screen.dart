import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../db/company_dao.dart';
import '../db/user_dao.dart';
import '../db/log_event_dao.dart';
import 'config_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/uppercase_input_formatter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  /// Creates the mutable state for this widget.
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
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
      });
    }
  }

  void _openConfig() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ConfigScreen()),
    );
    if (mounted) {
      _loadLocalCompany();
    }
  }

  /// Checks if this device has been authorized on Supabase.
  Future<bool> _isDeviceAuthorized() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uuid = prefs.getString('device_uuid');
      if (uuid == null) return false;
      final supabase = Supabase.instance.client;
      final result = await supabase
          .from('dispositivos_autorizados')
          .select('autorizado')
          .eq('uuid', uuid)
          .maybeSingle();
      if (result == null) return false;
      return result['autorizado'] == true;
    } catch (e) {
      await _logDao.insert(
          entidade: 'LOGIN',
          tipo: 'ERRO_AUTORIZACAO',
          tela: 'LoginScreen',
          mensagem: e.toString());
      return false;
    }
  }

  /// Validates credentials against the local database and logs in the user.
  Future<void> _login() async {
    final username = _userController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) return;
    final user = await _userDao.getByCredentials(username, password);
    final messenger = ScaffoldMessenger.of(context);
    if (user == null) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Usuário ou senha inválidos'),
          backgroundColor: Colors.red));
      await _logDao.insert(
          entidade: 'LOGIN',
          tipo: 'ERRO',
          tela: 'LoginScreen',
          mensagem: 'Usuário ou senha inválidos');
      return;
    }
    if (!await _isDeviceAuthorized()) {
      messenger.showSnackBar(const SnackBar(
          content:
              Text('Dispositivo não autorizado. Solicite autorização à empresa'),
          backgroundColor: Colors.red));
      await _logDao.insert(
          entidade: 'LOGIN',
          tipo: 'NAO_AUTORIZADO',
          tela: 'LoginScreen',
          mensagem: 'Dispositivo não autorizado');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('logged_user_pk', user['CUSU_PK'] as int);
    await _logDao.insert(
        entidade: 'LOGIN',
        tipo: 'SUCESSO',
        tela: 'LoginScreen',
        mensagem: 'Login realizado');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override

  /// Builds the login screen with email and password inputs.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Login'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openConfig,
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF283593), Color(0xFF0D47A1)],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_companyName != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    alignment: Alignment.center,
                    child: Text(
                      _companyName!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Card(
                  elevation: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _userController,
                          decoration: const InputDecoration(
                            labelText: 'Usuário',
                            prefixIcon: Icon(Icons.mail_outline),
                            border: OutlineInputBorder(),
                          ),
                          inputFormatters: [UpperCaseTextFormatter()],
                          textCapitalization: TextCapitalization.characters,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Entrar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      )
    );
  }
}
