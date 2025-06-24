import 'package:flutter/material.dart';

class ClientFormScreen extends StatefulWidget {
  final Map<String, dynamic>? client;
  final ValueChanged<Map<String, dynamic>> onSave;

  const ClientFormScreen({Key? key, this.client, required this.onSave})
      : super(key: key);

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _fantasiaController;
  late final TextEditingController _cnpjController;
  late final TextEditingController _ieController;
  late final TextEditingController _cepController;
  late final TextEditingController _logradouroController;
  late final TextEditingController _complementoController;
  late final TextEditingController _quadraController;
  late final TextEditingController _loteController;
  late final TextEditingController _numeroController;
  late final TextEditingController _bairroController;
  late final TextEditingController _municipioController;
  late final TextEditingController _codigoIbgeController;
  late final TextEditingController _ufController;
  late final TextEditingController _tipoPessoaController;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _nameController = TextEditingController(text: c?['CCOT_NOME']?.toString() ?? '');
    _fantasiaController =
        TextEditingController(text: c?['CCOT_FANTASIA']?.toString() ?? '');
    _cnpjController = TextEditingController(text: c?['CCOT_CNPJ']?.toString() ?? '');
    _ieController = TextEditingController(text: c?['CCOT_IE']?.toString() ?? '');
    _cepController = TextEditingController(text: c?['CCOT_END_CEP']?.toString() ?? '');
    _logradouroController =
        TextEditingController(text: c?['CCOT_END_NOME_LOGRADOURO']?.toString() ?? '');
    _complementoController =
        TextEditingController(text: c?['CCOT_END_COMPLEMENTO']?.toString() ?? '');
    _quadraController = TextEditingController(text: c?['CCOT_END_QUADRA']?.toString() ?? '');
    _loteController = TextEditingController(text: c?['CCOT_END_LOTE']?.toString() ?? '');
    _numeroController = TextEditingController(text: c?['CCOT_END_NUMERO']?.toString() ?? '');
    _bairroController = TextEditingController(text: c?['CCOT_END_BAIRRO']?.toString() ?? '');
    _municipioController = TextEditingController(text: c?['CCOT_END_MUNICIPIO']?.toString() ?? '');
    _codigoIbgeController = TextEditingController(text: c?['CCOT_END_CODIGO_IBGE']?.toString() ?? '');
    _ufController = TextEditingController(text: c?['CCOT_END_UF']?.toString() ?? '');
    _tipoPessoaController = TextEditingController(text: c?['CCOT_TP_PESSOA']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fantasiaController.dispose();
    _cnpjController.dispose();
    _ieController.dispose();
    _cepController.dispose();
    _logradouroController.dispose();
    _complementoController.dispose();
    _quadraController.dispose();
    _loteController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _municipioController.dispose();
    _codigoIbgeController.dispose();
    _ufController.dispose();
    _tipoPessoaController.dispose();
    super.dispose();
  }

  void _submit() {
    final data = <String, dynamic>{
      'CCOT_NOME': _nameController.text,
      'CCOT_FANTASIA': _fantasiaController.text,
      'CCOT_CNPJ': _cnpjController.text,
      'CCOT_IE': _ieController.text,
      'CCOT_END_CEP': _cepController.text,
      'CCOT_END_NOME_LOGRADOURO': _logradouroController.text,
      'CCOT_END_COMPLEMENTO': _complementoController.text,
      'CCOT_END_QUADRA': _quadraController.text,
      'CCOT_END_LOTE': _loteController.text,
      'CCOT_END_NUMERO': _numeroController.text,
      'CCOT_END_BAIRRO': _bairroController.text,
      'CCOT_END_MUNICIPIO': _municipioController.text,
      'CCOT_END_CODIGO_IBGE': _codigoIbgeController.text,
      'CCOT_END_UF': _ufController.text,
      'CCOT_TP_PESSOA': _tipoPessoaController.text,
    };
    if (widget.client != null) {
      data['CCOT_PK'] = widget.client!['CCOT_PK'];
    }
    widget.onSave(data);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client == null ? 'Novo Cliente' : 'Editar Cliente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
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
            const SizedBox(height: 16),
            TextField(
              controller: _cepController,
              decoration: const InputDecoration(labelText: 'CEP'),
            ),
            TextField(
              controller: _logradouroController,
              decoration: const InputDecoration(labelText: 'Logradouro'),
            ),
            TextField(
              controller: _complementoController,
              decoration: const InputDecoration(labelText: 'Complemento'),
            ),
            TextField(
              controller: _quadraController,
              decoration: const InputDecoration(labelText: 'Quadra'),
            ),
            TextField(
              controller: _loteController,
              decoration: const InputDecoration(labelText: 'Lote'),
            ),
            TextField(
              controller: _numeroController,
              decoration: const InputDecoration(labelText: 'Número'),
            ),
            TextField(
              controller: _bairroController,
              decoration: const InputDecoration(labelText: 'Bairro'),
            ),
            TextField(
              controller: _municipioController,
              decoration: const InputDecoration(labelText: 'Município'),
            ),
            TextField(
              controller: _codigoIbgeController,
              decoration: const InputDecoration(labelText: 'Código IBGE'),
            ),
            TextField(
              controller: _ufController,
              decoration: const InputDecoration(labelText: 'UF'),
            ),
            TextField(
              controller: _tipoPessoaController,
              decoration: const InputDecoration(labelText: 'Tipo Pessoa'),
            ),
          ],
        ),
      ),
    );
  }
}

