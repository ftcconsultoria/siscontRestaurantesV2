import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../db/company_dao.dart';
import '../db/user_dao.dart';
import 'config_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  /// Creates the mutable state for this widget.
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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

  /// Validates credentials against the local database and logs in the user.
  Future<void> _login() async {
    final username = _emailController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) return;
    final user = await _userDao.getByCredentials(username, password);
    final messenger = ScaffoldMessenger.of(context);
    if (user == null) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Usuário ou senha inválidos'),
          backgroundColor: Colors.red));
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('logged_user_pk', user['CUSU_PK'] as int);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  /// Builds the login screen with email and password inputs.
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openConfig,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email')),
              TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha')),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _login, child: const Text('Entrar')),
              if (_companyName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 32.0),
                  child: Text(
                    'Empresa: $_companyName',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.lightBlue,
                      fontSize: 28,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}