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
  int? _contactPk;
  final ContactDao _contactDao = ContactDao();
  List<Map<String, dynamic>> _contacts = [];

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(
        text: widget.order?['PDOC_VLR_TOTAL']?.toString() ?? '');
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
    });
  }

  @override
  void dispose() {
    _valueController.dispose();
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
          DropdownButtonFormField<int>(
            value: _contactPk,
            decoration: const InputDecoration(labelText: 'Cliente'),
            items: _contacts
                .map((c) => DropdownMenuItem(
                      value: c['CCOT_PK'] as int?,
                      child: Text(c['CCOT_NOME'] ?? ''),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _contactPk = v),
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
