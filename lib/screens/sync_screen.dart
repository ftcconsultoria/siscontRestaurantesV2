import 'package:flutter/material.dart';
import '../db/sync_service.dart';
import '../db/log_event_dao.dart';
import '../widgets/progress_dialog.dart';

/// Screen that provides buttons to import or export data with Supabase.
class SyncScreen extends StatelessWidget {
  const SyncScreen({super.key});

  final LogEventDao _logDao = LogEventDao();

  Future<void> _import(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final progress = ValueNotifier<double>(0);
    final message = ValueNotifier<String>('Importando...');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        message: message,
        progress: progress,
      ),
    );
    try {
      await SyncService().pull(onProgress: (v) => progress.value = v);
      messenger.showSnackBar(
        const SnackBar(content: Text('Importação concluída'), backgroundColor: Colors.green),
      );
      await _logDao.insert(
          entidade: 'SYNC',
          tipo: 'IMPORT',
          tela: 'SyncScreen',
          mensagem: 'Importação concluída');
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erro: \$e'),
          backgroundColor: Colors.red,
        ),
      );
      await _logDao.insert(
          entidade: 'SYNC',
          tipo: 'ERRO_IMPORT',
          tela: 'SyncScreen',
          mensagem: e.toString());
    } finally {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      progress.dispose();
      message.dispose();
    }
  }

  Future<void> _export(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final progress = ValueNotifier<double>(0);
    final message = ValueNotifier<String>('Enviando...');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        message: message,
        progress: progress,
      ),
    );
    try {
      await SyncService().push(
        onProgress: (v) => progress.value = v,
        onStatus: (s) => message.value = 'Enviando $s...',
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Envio concluído'), backgroundColor: Colors.green),
      );
      await _logDao.insert(
          entidade: 'SYNC',
          tipo: 'EXPORT',
          tela: 'SyncScreen',
          mensagem: 'Envio concluído');
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erro: \$e'),
          backgroundColor: Colors.red,
        ),
      );
      await _logDao.insert(
          entidade: 'SYNC',
          tipo: 'ERRO_EXPORT',
          tela: 'SyncScreen',
          mensagem: e.toString());
    } finally {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      progress.dispose();
      message.dispose();
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

