import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM/yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Logs')),
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
                return ListTile(
                  title: Text('$entidade - $tipo'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (mensagem.toString().isNotEmpty) Text(mensagem),
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

