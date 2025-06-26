import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/contact_dao.dart';

class OrderFormScreen extends StatefulWidget {
  final Map<String, dynamic>? order;
  final ValueChanged<Map<String, dynamic>> onSave;

  const OrderFormScreen({Key? key, this.order, required this.onSave})
      : super(key: key);

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  late DateTime _date;
  late TextEditingController _valueController;
  late TextEditingController _clientController;
  int? _contactPk;
  final ContactDao _contactDao = ContactDao();
  List<Map<String, dynamic>> _contacts = [];

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(
        text: widget.order?['PDOC_VLR_TOTAL']?.toString() ?? '');
    _clientController = TextEditingController();
    final dateStr = widget.order?['PDOC_DT_EMISSAO']?.toString();
    _date = dateStr != null && dateStr.isNotEmpty
        ? DateTime.tryParse(dateStr) ?? DateTime.now()
        : DateTime.now();
    _contactPk = widget.order?['CCOT_PK'] as int?;
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final list = await _contactDao.getAll();
    setState(() {
      _contacts = list;
      if (_contactPk != null) {
        final current =
            list.firstWhere((c) => c['CCOT_PK'] == _contactPk, orElse: () => {});
        _clientController.text = current['CCOT_NOME'] ?? '';
      }
    });
  }

  @override
  void dispose() {
    _valueController.dispose();
    _clientController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  Future<void> _showClientSearch() async {
    if (_contacts.isEmpty) await _loadContacts();
    String query = '';
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final filtered = _contacts.where((c) {
              final name = (c['CCOT_NOME'] ?? '').toString().toLowerCase();
              final doc = (c['CCOT_CNPJ'] ?? '')
                  .toString()
                  .replaceAll(RegExp(r'[^0-9]'), '');
              final qLower = query.toLowerCase();
              final qDigits = query.replaceAll(RegExp(r'[^0-9]'), '');
              return name.contains(qLower) || doc.contains(qDigits);
            }).toList();

            return SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Pesquisar',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => query = v),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final c = filtered[index];
                        return ListTile(
                          title: Text(c['CCOT_NOME'] ?? ''),
                          subtitle: Text(c['CCOT_CNPJ'] ?? ''),
                          onTap: () => Navigator.pop(context, c),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selected != null) {
      setState(() {
        _contactPk = selected['CCOT_PK'] as int?;
        _clientController.text = selected['CCOT_NOME'] ?? '';
      });
    }
  }

  void _submit() {
    final data = <String, dynamic>{
      'PDOC_DT_EMISSAO': DateFormat('yyyy-MM-dd').format(_date),
      'PDOC_VLR_TOTAL':
          double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0,
      'CCOT_PK': _contactPk,
    };
    if (widget.order != null) {
      data['PDOC_PK'] = widget.order!['PDOC_PK'];
    }
    widget.onSave(data);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.order == null ? 'Novo Pedido' : 'Editar Pedido'),
        actions: [
          IconButton(onPressed: _submit, icon: const Icon(Icons.save)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _clientController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Cliente',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _showClientSearch,
              ),
            ),
            onTap: _showClientSearch,
          ),
          const SizedBox(height: 16),
          TextField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Data',
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _pickDate,
              ),
            ),
            controller: TextEditingController(
                text: DateFormat('yyyy-MM-dd').format(_date)),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueController,
            decoration: const InputDecoration(labelText: 'Valor Total'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }
}
