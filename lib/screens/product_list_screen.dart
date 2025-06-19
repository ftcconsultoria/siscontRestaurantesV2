import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:typed_data';
import 'barcode_scanner_screen.dart';
import '../widgets/product_form_dialog.dart';

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
            'EPRO_PK, EPRO_DESCRICAO, EPRO_VLR_VAREJO, EPRO_ESTQ_ATUAL, EPRO_COD_EAN, ESTQ_PRODUTO_FOTO(EPRO_FOTO_URL)')
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
    final supabase = Supabase.instance.client;
    final photos = await supabase
        .from('ESTQ_PRODUTO_FOTO')
        .select('EPRO_FOTO_URL')
        .eq('EPRO_PK', id);
    if (photos is List) {
      final paths = photos
          .map((p) => p['EPRO_FOTO_URL'] as String?)
          .where((url) => url != null)
          .map((url) => url!.split('/fotos-produtos/').last)
          .where((path) => path.isNotEmpty)
          .toList();
      if (paths.isNotEmpty) {
        await supabase.storage.from('fotos-produtos').remove(paths);
      }
    }
    await supabase.from('ESTQ_PRODUTO_FOTO').delete().eq('EPRO_PK', id);
    await supabase.from('ESTQ_PRODUTO').delete().eq('EPRO_PK', id);
    await _refreshProducts();
  }

  Future<void> _confirmDeleteProduct(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem certeza que deseja excluir este produto?'),
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
      await _deleteProduct(id);
    }
  }

  Future<Uint8List> _compressImage(Uint8List bytes,
      {int targetBytes = 100 * 1024}) async {
    int quality = 100;
    Uint8List result = bytes;
    while (result.lengthInBytes > targetBytes && quality > 10) {
      result = await FlutterImageCompress.compressWithList(bytes, quality: quality);
      quality -= 10;
    }
    return result;
  }

  Future<void> _takePhoto(int productPk) async {
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    var bytes = await image.readAsBytes();
    bytes = await _compressImage(bytes);
    final ext = 'jpg';
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = '$productPk/$fileName';
    final supabase = Supabase.instance.client;
    await supabase.storage.from('fotos-produtos').uploadBinary(path, bytes);
    final publicUrl =
        supabase.storage.from('fotos-produtos').getPublicUrl(path);
    await supabase.from('ESTQ_PRODUTO_FOTO').insert({
      'EPRO_PK': productPk,
      'EPRO_FOTO_URL': publicUrl,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto salva com sucesso')),
      );
    }
    await _refreshProducts();
  }

  void _showPhoto(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: CachedNetworkImage(imageUrl: url),
        ),
      ),
    );
  }

  void _showProductForm([Map<String, dynamic>? product]) {
    showDialog(
      context: context,
      builder: (_) => ProductFormDialog(
        product: product,
        onSave: _addOrUpdateProduct,
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
            switch (_searchType) {
              case 'Nome':
                return p['EPRO_DESCRICAO']
                        ?.toString()
                        .toLowerCase()
                        .contains(query) ??
                    false;
              case 'Código':
                return p['EPRO_PK']?.toString().contains(query) ?? false;
              case 'EAN':
                return p['EPRO_COD_EAN']?.toString().contains(query) ?? false;
              default:
                return false;
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
                    DropdownButton<String>(
                      value: _searchType,
                      items: const [
                        DropdownMenuItem(value: 'Nome', child: Text('Nome')),
                        DropdownMenuItem(value: 'Código', child: Text('Código')),
                        DropdownMenuItem(value: 'EAN', child: Text('EAN')),
                      ],
                      onChanged: (v) => setState(() => _searchType = v ?? 'Nome'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Pesquisar',
                          suffixIcon: _searchType == 'EAN'
                              ? IconButton(
                                  icon: const Icon(Icons.camera_alt),
                                  onPressed: () async {
                                    final code = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const BarcodeScannerScreen()),
                                    );
                                    if (code != null) {
                                      setState(() {
                                        _searchController.text =
                                            code.toString();
                                      });
                                    }
                                  },
                                )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
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
                    final fotos = produto['ESTQ_PRODUTO_FOTO'] as List?;
                    Widget leadingWidget = const SizedBox(
                      width: 70,
                      height: 70,
                      child: Icon(Icons.shopping_cart),
                    );
                    if (fotos != null && fotos.isNotEmpty) {
                      final url = fotos.first['EPRO_FOTO_URL'];
                      if (url != null && url is String && url.isNotEmpty) {
                        leadingWidget = GestureDetector(
                          onDoubleTap: () => _showPhoto(url),
                          child: SizedBox(
                            width: 70,
                            height: 70,
                            child: CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              placeholder: (c, s) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ),
                        );
                      }
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          color: Theme.of(context).cardColor,
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              leadingWidget,
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      (produto['EPRO_DESCRICAO'] ?? '')
                                          .toString()
                                          .toUpperCase(),
                                    ),
                                    Text('EAN: ${produto['EPRO_COD_EAN'] ?? ''}'),
                                    RichText(
                                      text: TextSpan(
                                        style: DefaultTextStyle.of(context).style,
                                        children: [
                                          const TextSpan(text: 'Preço: '),
                                          TextSpan(
                                              text: price,
                                              style: TextStyle(color: priceColor)),
                                          const TextSpan(text: ' - Estoque: '),
                                          TextSpan(
                                              text: stock,
                                              style: TextStyle(color: stockColor)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                                onPressed: () => _confirmDeleteProduct(produto['EPRO_PK']),
                              ),
                            ],
                          ),
                        ),
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