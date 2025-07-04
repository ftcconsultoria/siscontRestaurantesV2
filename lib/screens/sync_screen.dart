import 'package:flutter/material.dart';
import '../db/sync_service.dart';

/// Screen that provides buttons to import or export data with Supabase.
class SyncScreen extends StatelessWidget {
  const SyncScreen({super.key});

  Future<void> _import(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Importando...')));
    try {
      await SyncService().pull();
      messenger.showSnackBar(
        const SnackBar(content: Text('Importação concluída'), backgroundColor: Colors.green),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erro: \$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _export(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Enviando...')));
    try {
      await SyncService().push();
      messenger.showSnackBar(
        const SnackBar(content: Text('Envio concluído'), backgroundColor: Colors.green),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erro: \$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sincronização')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => _import(context),
              child: const Text('Importar dados do Supabase'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _export(context),
              child: const Text('Enviar dados para o Supabase'),
            ),
          ],
        ),
      ),
    );
  }
}

