import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../db/company_dao.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  /// Creates the mutable state for this widget.
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cnpjController = TextEditingController();
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
        if (mounted) {
          setState(() {
            _companyName = result['CEMP_NOME_FANTASIA'] as String?;
          });
        }
        messenger
            .showSnackBar(const SnackBar(content: Text('Empresa carregada')));
      } else {
        messenger
            .showSnackBar(const SnackBar(content: Text('Empresa não encontrada')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erro: $e')));
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text("Login", style: TextStyle(fontSize: 32)),
              TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email')),
              TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha')),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _login, child: const Text('Entrar')),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text('Configuração da Empresa',
                  style: TextStyle(fontSize: 20)),
              TextField(
                controller: _cnpjController,
                decoration: const InputDecoration(labelText: 'CNPJ'),
                keyboardType: TextInputType.number,
              ),
              if (_companyName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Empresa: $_companyName'),
                ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _fetchCompany,
                child: const Text('Carregar Empresa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}