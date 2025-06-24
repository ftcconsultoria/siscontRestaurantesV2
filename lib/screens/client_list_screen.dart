import 'package:flutter/material.dart';
import '../widgets/contact_form_dialog.dart';
import '../db/contact_dao.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final ContactDao _dao = ContactDao();
  late Future<List<Map<String, dynamic>>> _clientsFuture;

  @override
  void initState() {
    super.initState();
    _clientsFuture = _dao.getAll();
  }

  Future<void> _refresh() async {
    final list = await _dao.getAll();
    setState(() {
      _clientsFuture = Future.value(list);
    });
  }

  Future<void> _addOrUpdate(Map<String, dynamic> data) async {
    await _dao.insertOrUpdate(data);
    await _refresh();
  }

  Future<void> _delete(int id) async {
    await _dao.delete(id);
    await _refresh();
  }

  Future<void> _confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Deseja realmente excluir este cliente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _delete(id);
    }
  }

  void _showForm([Map<String, dynamic>? contact]) {
    showDialog(
      context: context,
      builder: (context) => ContactFormDialog(
        contact: contact,
        onSave: _addOrUpdate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _clientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final clients = snapshot.data ?? [];
          if (clients.isEmpty) {
            return const Center(child: Text('Nenhum cliente cadastrado'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final c = clients[index];
                return ListTile(
                  title: Text(c['CCOT_NOME'] ?? ''),
                  subtitle: c['CCOT_FANTASIA'] != null && c['CCOT_FANTASIA'] != ''
                      ? Text(c['CCOT_FANTASIA'])
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showForm(c),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDelete(c['CCOT_PK']),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
