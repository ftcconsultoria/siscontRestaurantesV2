import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/order_dao.dart';
import '../db/order_item_dao.dart';
import 'order_form_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final OrderDao _dao = OrderDao();
  final OrderItemDao _itemDao = OrderItemDao();
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchOrders();
  }

  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    final list = await _dao.getAll();
    return list;
  }

  Future<void> _refresh() async {
    final list = await _fetchOrders();
    setState(() {
      _ordersFuture = Future.value(list);
    });
  }

  Future<void> _addOrUpdate(
      Map<String, dynamic> order, List<Map<String, dynamic>> items) async {
    final id = await _dao.insertOrUpdate(order);
    await _itemDao.replaceItems(id, items);
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
        content: const Text('Deseja realmente excluir este pedido?'),
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

  void _showForm([Map<String, dynamic>? order]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderFormScreen(
          order: order,
          onSave: _addOrUpdate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('Nenhum pedido cadastrado'));
          }
          final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final o = orders[index];
                final dateStr = o['PDOC_DT_EMISSAO']?.toString();
                String date = '';
                if (dateStr != null && dateStr.isNotEmpty) {
                  final parsed = DateTime.tryParse(dateStr);
                  if (parsed != null) {
                    date = DateFormat('dd/MM/yyyy').format(parsed);
                  }
                }
                final value = currency.format(o['PDOC_VLR_TOTAL'] ?? 0);
                return ListTile(
                  title: Text(
                    'Pedido ${o['PDOC_PK'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cliente: ${o['CCOT_NOME'] ?? ''}'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('Data: $date')),
                          Text('Valor: $value'),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showForm(o),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDelete(o['PDOC_PK']),
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
