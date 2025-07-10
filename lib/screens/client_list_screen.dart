import 'package:flutter/material.dart';
import 'client_form_screen.dart';
import '../db/contact_dao.dart';
import '../db/log_event_dao.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final ContactDao _dao = ContactDao();
  final LogEventDao _logDao = LogEventDao();
  late Future<List<Map<String, dynamic>>> _clientsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchType = 'Nome';
  List<Map<String, dynamic>> _clients = [];

  @override
  void initState() {
    super.initState();
    _clientsFuture = _fetchClients();
  }

  Future<List<Map<String, dynamic>>> _fetchClients() async {
    final list = await _dao.getAll();
    _clients = list;
    return list;
  }

  Future<void> _refresh() async {
    final list = await _fetchClients();
    setState(() {
      _clientsFuture = Future.value(list);
    });
  }

  Future<void> _addOrUpdate(Map<String, dynamic> data) async {
    final messenger = ScaffoldMessenger.of(context);
    final isNew = !_clients.any((c) => c['CCOT_CNPJ'] == data['CCOT_CNPJ']);
    try {
      await _dao.insertOrUpdate(data);
      if (isNew) {
        await _logDao.insert(
            entidade: 'CLIENTE',
            tipo: 'NOVO',
            tela: 'ClientListScreen');
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao salvar cliente: $e'), backgroundColor: Colors.red),
      );
      await _logDao.insert(
          entidade: 'CLIENTE',
          tipo: 'ERRO',
          tela: 'ClientListScreen',
          mensagem: e.toString());
    }
    await _refresh();
  }

  Future<void> _delete(String cnpj) async {
    await _dao.delete(cnpj);
    await _refresh();
  }

  Future<void> _confirmDelete(String cnpj) async {
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
      await _delete(cnpj);
    }
  }

  void _showForm([Map<String, dynamic>? contact]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientFormScreen(
          client: contact,
          onSave: _addOrUpdate,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          final clients = _clients;
          if (clients.isEmpty) {
            return const Center(child: Text('Nenhum cliente cadastrado'));
          }
          final query = _searchController.text.toLowerCase();
          final filtered = clients.where((c) {
            if (query.isEmpty) return true;
            switch (_searchType) {
              case 'Nome':
                return c['CCOT_NOME']
                        ?.toString()
                        .toLowerCase()
                        .contains(query) ??
                    false;
              case 'Fantasia':
                return c['CCOT_FANTASIA']
                        ?.toString()
                        .toLowerCase()
                        .contains(query) ??
                    false;
              case 'Doc':
                final doc = c['CCOT_CNPJ']
                    ?.toString()
                    .replaceAll(RegExp(r'[^0-9]'), '');
                final q = query.replaceAll(RegExp(r'[^0-9]'), '');
                return doc?.contains(q) ?? false;
              default:
                return false;
            }
          }).toList();

          if (filtered.isEmpty) {
            return const Center(child: Text('Nenhum cliente encontrado.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      DropdownButton<String>(
                        value: _searchType,
                        items: const [
                          DropdownMenuItem(value: 'Nome', child: Text('Nome')),
                          DropdownMenuItem(
                              value: 'Fantasia', child: Text('Fantasia')),
                          DropdownMenuItem(value: 'Doc', child: Text('CPF/CNPJ')),
                        ],
                        onChanged: (v) => setState(() => _searchType = v ?? 'Nome'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration:
                              const InputDecoration(labelText: 'Pesquisar'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final c = filtered[index];
                      final docLabel =
                          (c['CCOT_TP_PESSOA'] ?? 'JURIDICA') == 'FISICA'
                              ? 'CPF'
                              : 'CNPJ';
                      final fantasia = c['CCOT_FANTASIA'];
                      return ListTile(
                        title: Text(c['CCOT_NOME'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (fantasia != null && fantasia.toString().isNotEmpty)
                              Text(fantasia.toString()),
                            Text('$docLabel: ${c['CCOT_CNPJ'] ?? ''}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showForm(c),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _confirmDelete(c['CCOT_CNPJ']),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
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
