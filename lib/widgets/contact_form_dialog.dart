import 'package:flutter/material.dart';

class ContactFormDialog extends StatefulWidget {
  final Map<String, dynamic>? contact;
  final ValueChanged<Map<String, dynamic>> onSave;

  const ContactFormDialog({Key? key, this.contact, required this.onSave})
      : super(key: key);

  @override
  State<ContactFormDialog> createState() => _ContactFormDialogState();
}

class _ContactFormDialogState extends State<ContactFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _fantasiaController;
  late TextEditingController _cnpjController;
  late TextEditingController _ieController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.contact?['CCOT_NOME']?.toString() ?? '');
    _fantasiaController = TextEditingController(
        text: widget.contact?['CCOT_FANTASIA']?.toString() ?? '');
    _cnpjController =
        TextEditingController(text: widget.contact?['CCOT_CNPJ']?.toString() ?? '');
    _ieController =
        TextEditingController(text: widget.contact?['CCOT_IE']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fantasiaController.dispose();
    _cnpjController.dispose();
    _ieController.dispose();
    super.dispose();
  }

  void _submit() {
    final data = <String, dynamic>{
      'CCOT_NOME': _nameController.text,
      'CCOT_FANTASIA': _fantasiaController.text,
      'CCOT_CNPJ': _cnpjController.text,
      'CCOT_IE': _ieController.text,
    };
    widget.onSave(data);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.contact == null ? 'Novo Cliente' : 'Editar Cliente'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: _fantasiaController,
              decoration: const InputDecoration(labelText: 'Fantasia'),
            ),
            TextField(
              controller: _cnpjController,
              decoration: const InputDecoration(labelText: 'CNPJ'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _ieController,
              decoration: const InputDecoration(labelText: 'IE'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
