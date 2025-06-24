import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'product_list_screen.dart';
import '../db/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  /// Builds the main menu with navigation options and sync actions.
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Painel ERP')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Produtos'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProductListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Sincronizar'),
              onTap: () async {
                Navigator.pop(context);
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                    const SnackBar(content: Text('Sincronizando...')));
                try {
                  await SyncService().sync();
                  messenger.showSnackBar(
                      const SnackBar(content: Text('Sincronização concluída')));
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('Erro: $e')));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('logged_user_pk');
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text('Bem-vindo ao ERP Mobile'),
      ),
    );
  }
}
