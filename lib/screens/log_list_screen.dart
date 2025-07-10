import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import '../db/log_event_dao.dart';

/// Screen that lists log events stored in the local database.
class LogListScreen extends StatefulWidget {
  const LogListScreen({super.key});

  @override
  State<LogListScreen> createState() => _LogListScreenState();
}

class _LogListScreenState extends State<LogListScreen> {
  final LogEventDao _dao = LogEventDao();
  late Future<List<Map<String, dynamic>>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = _dao.getAll();
  }

  Future<void> _refresh() async {
    final logs = await _dao.getAll();
    setState(() {
      _logsFuture = Future.value(logs);
    });
  }

  Future<void> _exportLogs() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final logs = await _dao.getAll();
      if (logs.isEmpty) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Nenhum log para exportar')));
        return;
      }
      final buffer = StringBuffer();
      buffer.writeln(
          'LOG_PK,CEMP_PK,CUSU_PK,LOG_ENTIDADE,LOG_CHAVE,LOG_TIPO,LOG_TELA,LOG_MENSAGEM,LOG_DADOS,LOG_DT');
      for (final log in logs) {
        final line = [
          log['LOG_PK'],
          log['CEMP_PK'],
          log['CUSU_PK'],
          log['LOG_ENTIDADE'],
          log['LOG_CHAVE'],
          log['LOG_TIPO'],
          log['LOG_TELA'],
          log['LOG_MENSAGEM'],
          log['LOG_DADOS'],
          log['LOG_DT'],
        ]
            .map((e) => '"${e?.toString().replaceAll('"', '""') ?? ''}"')
            .join(',');
        buffer.writeln(line);
      }
      final dir = await getTemporaryDirectory();
      final path = p.join(dir.path, 'logs.csv');
      final file = File(path);
      await file.writeAsString(buffer.toString());
      await Share.shareXFiles([XFile(path)], text: 'ERP Mobile - logs');
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text('Erro ao exportar logs: $e')));
    }
  }

  Future<void> _clearLogs() async {
    await _dao.deleteAll();
    await _refresh();
  }

  Future<void> _confirmClearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar logs'),
        content: const Text('Deseja realmente excluir todos os logs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _clearLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM/yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton(onPressed: _exportLogs, icon: const Icon(Icons.share)),
          IconButton(onPressed: _confirmClearLogs, icon: const Icon(Icons.delete)),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return const Center(child: Text('Nenhum log encontrado'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              itemCount: logs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final log = logs[index];
                final dateStr = log['LOG_DT']?.toString();
                DateTime? date;
                if (dateStr != null) {
                  date = DateTime.tryParse(dateStr);
                }
                final dateText = date != null ? format.format(date) : '';
                final entidade = log['LOG_ENTIDADE'] ?? '';
                final tipo = log['LOG_TIPO'] ?? '';
                final mensagem = log['LOG_MENSAGEM'] ?? '';
                final dadosStr = log['LOG_DADOS']?.toString();
                String dados = '';
                if (dadosStr != null && dadosStr.isNotEmpty) {
                  try {
                    final obj = jsonDecode(dadosStr);
                    dados = const JsonEncoder.withIndent('  ').convert(obj);
                  } catch (_) {
                    dados = dadosStr;
                  }
                }
                return ListTile(
                  title: Text('$entidade - $tipo'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (mensagem.toString().isNotEmpty) Text(mensagem),
                      if (dados.isNotEmpty) Text(dados),
                      Text(dateText),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

