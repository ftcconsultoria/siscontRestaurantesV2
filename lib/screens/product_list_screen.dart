import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'barcode_scanner_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late Future<List<Map<String, dynamic>>> _productsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchType = 'Nome';
  List<Map<String, dynamic>> _products = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();
  }

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    final response = await Supabase.instance.client
        .from('ESTQ_PRODUTO')
        .select(
            'EPRO_PK, EPRO_DESCRICAO, EPRO_VLR_VAREJO, EPRO_ESTQ_ATUAL, EPRO_COD_EAN')
        .order('EPRO_DESCRICAO');
    final list = List<Map<String, dynamic>>.from(response);
    _products = list;
    return list;
  }

  Future<void> _refreshProducts() async {
    final list = await _fetchProducts();
    setState(() {
      _productsFuture = Future.value(list);
    });
  }

  Future<void> _addOrUpdateProduct(Map<String, dynamic> data) async {
    if (data['EPRO_PK'] == null) {
      await Supabase.instance.client.from('ESTQ_PRODUTO').insert(data);
    } else {
      final id = data['EPRO_PK'];
      await Supabase.instance.client
          .from('ESTQ_PRODUTO')
          .update(data)
          .eq('EPRO_PK', id);
    }
    await _refreshProducts();
  }

  Future<void> _deleteProduct(int id) async {
    await Supabase.instance.client
        .from('ESTQ_PRODUTO')
        .delete()
        .eq('EPRO_PK', id);
    await _refreshProducts();
  }

  Future<void> _takePhoto(int productPk) async {
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);
    await Supabase.instance.client.from('ESTQ_PRODUTO_FOTO').insert({
      'EPRO_PK': productPk,
      'EPRO_FOTO': base64Image,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto salva com sucesso')),
      );
    }
  }

  void _showProductForm([Map<String, dynamic>? product]) {
    final eanController =
        TextEditingController(text: product?['EPRO_COD_EAN']?.toString() ?? '');
    final descController = TextEditingController(
        text: product?['EPRO_DESCRICAO']?.toString().toUpperCase() ?? '');
    final priceController = TextEditingController(
        text: product?['EPRO_VLR_VAREJO']?.toString() ?? '');
    final stockController = TextEditingController(
        text: product?['EPRO_ESTQ_ATUAL']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(product == null ? 'Novo Produto' : 'Editar Produto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: eanController,
              decoration: InputDecoration(
                labelText: 'EAN',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () async {
                    final code = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BarcodeScannerScreen()),
                    );
                    if (code != null) {
                      eanController.text = code.toString();
                    }
                  },
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Preço'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: stockController,
              decoration: const InputDecoration(labelText: 'Estoque'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final data = <String, dynamic>{
                'EPRO_COD_EAN': eanController.text,
                'EPRO_DESCRICAO': descController.text.toUpperCase(),
                'EPRO_VLR_VAREJO':
                    double.tryParse(priceController.text.replaceAll(',', '.')) ??
                        0,
                'EPRO_ESTQ_ATUAL':
                    double.tryParse(stockController.text.replaceAll(',', '.')) ??
                        0,
              };
              if (product != null) {
                data['EPRO_PK'] = product['EPRO_PK'];
              }
              Navigator.pop(context);
              _addOrUpdateProduct(data);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Produtos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductForm(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          final produtos = _products;

          final query = _searchController.text.toLowerCase();
          final filtered = produtos.where((p) {
            if (query.isEmpty) return true;
            if (_searchType == 'Nome') {
              return p['EPRO_DESCRICAO']
                      ?.toString()
                      .toLowerCase()
                      .contains(query) ??
                  false;
            } else {
              return p['EPRO_PK']?.toString().contains(query) ?? false;
            }
          }).toList();

          if (filtered.isEmpty) {
            return const Center(child: Text('Nenhum produto encontrado.'));
          }

          final priceFormat =
              NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
          final stockFormat = NumberFormat.decimalPattern('pt_BR')
            ..minimumFractionDigits = 2
            ..maximumFractionDigits = 2;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Pesquisar',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _searchType,
                      items: const [
                        DropdownMenuItem(value: 'Nome', child: Text('Nome')),
                        DropdownMenuItem(value: 'Código', child: Text('Código')),
                      ],
                      onChanged: (v) => setState(() => _searchType = v ?? 'Nome'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final produto = filtered[index];
                    final precoValor = produto['EPRO_VLR_VAREJO'] ?? 0;
                    final estoqueValor = produto['EPRO_ESTQ_ATUAL'] ?? 0;
                    final price = priceFormat.format(precoValor);
                    final stock = stockFormat.format(estoqueValor);
                    final priceColor = precoValor == 0 ? Colors.red : null;
                    final stockColor = estoqueValor < 0 ? Colors.red : null;
                    return ListTile(
                      leading: const Icon(Icons.shopping_cart),
                      title: Text(
                        (produto['EPRO_DESCRICAO'] ?? '').toString().toUpperCase(),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('EAN: ${produto['EPRO_COD_EAN'] ?? ''}'),
                          RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                              children: [
                                const TextSpan(text: 'Preço: '),
                                TextSpan(text: price, style: TextStyle(color: priceColor)),
                                const TextSpan(text: ' - Estoque: '),
                                TextSpan(text: stock, style: TextStyle(color: stockColor)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.photo_camera),
                            onPressed: () => _takePhoto(produto['EPRO_PK']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showProductForm(produto),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteProduct(produto['EPRO_PK']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}