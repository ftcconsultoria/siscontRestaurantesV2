import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../db/company_dao.dart';
import 'config_screen.dart';

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

  /// Handles the login action and navigates to the home screen.
  void _login() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  /// Builds the login screen with email and password inputs.
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF283593), Color(0xFF0D47A1)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
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
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                        border: OutlineInputBorder(),
                      ),
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
          ),
        ),
      ),
      bottomNavigationBar: _companyName != null
          ? Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Text(
                'Empresa: $_companyName',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            )
          : null,
    );
  }
}