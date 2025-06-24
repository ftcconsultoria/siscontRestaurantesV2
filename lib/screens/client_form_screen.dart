import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../widgets/uppercase_input_formatter.dart';
import '../widgets/cpf_cnpj_input_formatter.dart';
import '../utils/validators.dart';

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
  late final FocusNode _cnpjFocusNode;
  late final FocusNode _cepFocusNode;
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
  late String _tipoPessoa;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _nameController =
        TextEditingController(text: c?['CCOT_NOME']?.toString().toUpperCase() ?? '');
    _fantasiaController = TextEditingController(
        text: c?['CCOT_FANTASIA']?.toString().toUpperCase() ?? '');
    _cnpjController = TextEditingController(text: c?['CCOT_CNPJ']?.toString() ?? '');
    _cnpjFocusNode = FocusNode();
    _cnpjFocusNode.addListener(() {
      if (!_cnpjFocusNode.hasFocus) {
        showDocumentValidation(
            context, _cnpjController.text, _tipoPessoa == 'FISICA');
        if (widget.client == null &&
            _tipoPessoa == 'JURIDICA' &&
            isValidCnpj(_cnpjController.text)) {
          _lookupCnpj();
        }
      }
    });
    _cepFocusNode = FocusNode();
    _cepFocusNode.addListener(() {
      if (!_cepFocusNode.hasFocus) {
        _lookupCep();
      }
    });
    _ieController = TextEditingController(text: c?['CCOT_IE']?.toString() ?? '');
    _cepController = TextEditingController(text: c?['CCOT_END_CEP']?.toString() ?? '');
    _logradouroController =
        TextEditingController(text: c?['CCOT_END_NOME_LOGRADOURO']?.toString().toUpperCase() ?? '');
    _complementoController = TextEditingController(
        text: c?['CCOT_END_COMPLEMENTO']?.toString().toUpperCase() ?? '');
    _quadraController =
        TextEditingController(text: c?['CCOT_END_QUADRA']?.toString().toUpperCase() ?? '');
    _loteController =
        TextEditingController(text: c?['CCOT_END_LOTE']?.toString().toUpperCase() ?? '');
    _numeroController = TextEditingController(text: c?['CCOT_END_NUMERO']?.toString() ?? '');
    _bairroController =
        TextEditingController(text: c?['CCOT_END_BAIRRO']?.toString().toUpperCase() ?? '');
    _municipioController =
        TextEditingController(text: c?['CCOT_END_MUNICIPIO']?.toString().toUpperCase() ?? '');
    _codigoIbgeController = TextEditingController(text: c?['CCOT_END_CODIGO_IBGE']?.toString() ?? '');
    _ufController = TextEditingController(text: c?['CCOT_END_UF']?.toString() ?? '');
    _tipoPessoa = c?['CCOT_TP_PESSOA']?.toString() ?? 'JURIDICA';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fantasiaController.dispose();
    _cnpjController.dispose();
    _cnpjFocusNode.dispose();
    _cepFocusNode.dispose();
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
    super.dispose();
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<void> _lookupCnpj() async {
    final cnpj = _cnpjController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cnpj.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    if (!await _hasInternet()) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Sem conexão com a internet')));
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: SizedBox(
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Aguardando dados da Receita'),
            ],
          ),
        ),
      ),
    );
    try {
      final url = Uri.parse('https://publica.cnpj.ws/cnpj/' + cnpj);
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        setState(() {
          _nameController.text =
              (data['razao_social'] ?? _nameController.text).toString();
          final est = data['estabelecimento'] as Map<String, dynamic>?;
          _fantasiaController.text = (data['nome_fantasia'] ??
                  est?['nome_fantasia'] ?? _fantasiaController.text)
              .toString();
          if (est != null) {
            _cepController.text = est['cep']?.toString() ?? _cepController.text;
            _logradouroController.text =
                (est['logradouro'] ?? _logradouroController.text).toString();
            _numeroController.text =
                est['numero']?.toString() ?? _numeroController.text;
            _complementoController.text =
                (est['complemento'] ?? _complementoController.text).toString();
            _bairroController.text =
                (est['bairro'] ?? _bairroController.text).toString();
            final cidade = est['cidade'] as Map<String, dynamic>?;
            if (cidade != null) {
              _municipioController.text =
                  (cidade['nome'] ?? _municipioController.text).toString();
              _codigoIbgeController.text =
                  cidade['ibge_id']?.toString() ?? _codigoIbgeController.text;
            }
            final estado = est['estado'] as Map<String, dynamic>?;
            if (estado != null) {
              _ufController.text =
                  (estado['sigla'] ?? _ufController.text).toString();
            }
            final inscricoes = est['inscricoes_estaduais'];
            if (inscricoes is List && inscricoes.isNotEmpty) {
              final ie = inscricoes.first['inscricao_estadual'];
              if (ie != null) _ieController.text = ie.toString();
            }
          }
        });
        messenger.showSnackBar(const SnackBar(
            content: Text('Dados preenchidos a partir do CNPJ'),
            backgroundColor: Colors.green));
      } else {
        messenger.showSnackBar(SnackBar(
            content: Text('Erro ao consultar CNPJ: ${resp.statusCode}')));
      }
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text('Erro ao consultar CNPJ: $e')));
    } finally {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _lookupCep() async {
    final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) return;
    final messenger = ScaffoldMessenger.of(context);
    if (!await _hasInternet()) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Sem conexão com a internet')));
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: SizedBox(
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Consultando CEP'),
            ],
          ),
        ),
      ),
    );
    try {
      final url = Uri.parse('https://viacep.com.br/ws/' + cep + '/json/');
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        if (data['erro'] != true) {
          setState(() {
            _logradouroController.text =
                (data['logradouro'] ?? _logradouroController.text).toString();
            _bairroController.text =
                (data['bairro'] ?? _bairroController.text).toString();
            _municipioController.text =
                (data['localidade'] ?? _municipioController.text).toString();
            _ufController.text =
                (data['uf'] ?? _ufController.text).toString();
            _codigoIbgeController.text =
                (data['ibge'] ?? _codigoIbgeController.text).toString();
          });
          messenger.showSnackBar(const SnackBar(
              content: Text('Dados preenchidos a partir do CEP'),
              backgroundColor: Colors.green));
        } else {
          messenger
              .showSnackBar(const SnackBar(content: Text('CEP não encontrado')));
        }
      } else {
        messenger.showSnackBar(
            SnackBar(content: Text('Erro ao consultar CEP: ${resp.statusCode}')));
      }
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text('Erro ao consultar CEP: $e')));
    } finally {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  void _submit() {
    final data = <String, dynamic>{
      'CCOT_NOME': _nameController.text.toUpperCase(),
      'CCOT_FANTASIA': _fantasiaController.text.toUpperCase(),
      'CCOT_CNPJ': _cnpjController.text,
      'CCOT_IE': _ieController.text,
      'CCOT_END_CEP': _cepController.text,
      'CCOT_END_NOME_LOGRADOURO': _logradouroController.text.toUpperCase(),
      'CCOT_END_COMPLEMENTO': _complementoController.text.toUpperCase(),
      'CCOT_END_QUADRA': _quadraController.text.toUpperCase(),
      'CCOT_END_LOTE': _loteController.text.toUpperCase(),
      'CCOT_END_NUMERO': _numeroController.text,
      'CCOT_END_BAIRRO': _bairroController.text.toUpperCase(),
      'CCOT_END_MUNICIPIO': _municipioController.text.toUpperCase(),
      'CCOT_END_CODIGO_IBGE': _codigoIbgeController.text,
      'CCOT_END_UF': _ufController.text,
      'CCOT_TP_PESSOA': _tipoPessoa,
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
            DropdownButtonFormField<String>(
              value: _tipoPessoa,
              decoration: const InputDecoration(labelText: 'Tipo Pessoa'),
              items: const [
                DropdownMenuItem(value: 'FISICA', child: Text('FÍSICA')),
                DropdownMenuItem(value: 'JURIDICA', child: Text('JURÍDICA')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _tipoPessoa = v;
                    final digits =
                        _cnpjController.text.replaceAll(RegExp(r'[^0-9]'), '');
                    final masked = v == 'FISICA'
                        ? CpfCnpjInputFormatter.formatCpf(digits)
                        : CpfCnpjInputFormatter.formatCnpj(digits);
                    _cnpjController.value = TextEditingValue(
                      text: masked,
                      selection:
                          TextSelection.collapsed(offset: masked.length),
                    );
                  });
                }
              },
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
              inputFormatters: [UpperCaseTextFormatter()],
              textCapitalization: TextCapitalization.characters,
            ),
            TextField(
              controller: _fantasiaController,
              decoration: const InputDecoration(labelText: 'Fantasia'),
              inputFormatters: [UpperCaseTextFormatter()],
              textCapitalization: TextCapitalization.characters,
            ),
            TextField(
              controller: _cnpjController,
              focusNode: _cnpjFocusNode,
              decoration: InputDecoration(
                  labelText: _tipoPessoa == 'FISICA' ? 'CPF' : 'CNPJ'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                CpfCnpjInputFormatter(isCpf: _tipoPessoa == 'FISICA')
              ],
            ),
            TextField(
              controller: _ieController,
              decoration: const InputDecoration(labelText: 'IE'),
              enabled: _tipoPessoa != 'FISICA',
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cepController,
              focusNode: _cepFocusNode,
              decoration: const InputDecoration(labelText: 'CEP'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _logradouroController,
              decoration: const InputDecoration(labelText: 'Logradouro'),
              inputFormatters: [UpperCaseTextFormatter()],
              textCapitalization: TextCapitalization.characters,
            ),
            TextField(
              controller: _complementoController,
              decoration: const InputDecoration(labelText: 'Complemento'),
              inputFormatters: [UpperCaseTextFormatter()],
              textCapitalization: TextCapitalization.characters,
            ),
            TextField(
              controller: _quadraController,
              decoration: const InputDecoration(labelText: 'Quadra'),
              inputFormatters: [UpperCaseTextFormatter()],
              textCapitalization: TextCapitalization.characters,
            ),
            TextField(
              controller: _loteController,
              decoration: const InputDecoration(labelText: 'Lote'),
              inputFormatters: [UpperCaseTextFormatter()],
              textCapitalization: TextCapitalization.characters,
            ),
            TextField(
              controller: _numeroController,
              decoration: const InputDecoration(labelText: 'Número'),
            ),
            TextField(
              controller: _bairroController,
              decoration: const InputDecoration(labelText: 'Bairro'),
              inputFormatters: [UpperCaseTextFormatter()],
              textCapitalization: TextCapitalization.characters,
            ),
            TextField(
              controller: _municipioController,
              decoration: const InputDecoration(labelText: 'Município'),
              inputFormatters: [UpperCaseTextFormatter()],
              textCapitalization: TextCapitalization.characters,
            ),
            TextField(
              controller: _codigoIbgeController,
              decoration: const InputDecoration(labelText: 'Código IBGE'),
            ),
            TextField(
              controller: _ufController,
              decoration: const InputDecoration(labelText: 'UF'),
            ),
          ],
        ),
      ),
    );
  }
}

