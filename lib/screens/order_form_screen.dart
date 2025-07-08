import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/order_pdf.dart';
import '../db/contact_dao.dart';
import '../db/product_dao.dart';
import '../db/order_item_dao.dart';
import 'barcode_scanner_screen.dart';

class OrderFormScreen extends StatefulWidget {
  final Map<String, dynamic>? order;
  final void Function(Map<String, dynamic>, List<Map<String, dynamic>>) onSave;

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
  final ProductDao _productDao = ProductDao();
  final OrderItemDao _itemDao = OrderItemDao();
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController();
    _clientController = TextEditingController();
    final dateStr = widget.order?['PDOC_DT_EMISSAO']?.toString();
    _date = dateStr != null && dateStr.isNotEmpty
        ? DateTime.tryParse(dateStr) ?? DateTime.now()
        : DateTime.now();
    _contactPk = widget.order?['CCOT_PK'] as int?;
    _loadContacts();
    _loadProducts();
    _loadItems();
  }

  Future<void> _loadContacts() async {
    final list = await _contactDao.getAll();
    setState(() {
      _contacts = list;
      if (_contactPk != null) {
        final current = list.firstWhere((c) => c['CCOT_PK'] == _contactPk,
            orElse: () => {});
        _clientController.text = current['CCOT_NOME'] ?? '';
      }
    });
  }

  Future<void> _loadProducts() async {
    final list = await _productDao.getAll();
    setState(() => _products = list);
  }

  Future<void> _loadItems() async {
    if (widget.order != null) {
      final list = await _itemDao.getByOrder(widget.order!['PDOC_PK']);
      setState(() {
        _items = List<Map<String, dynamic>>.from(list);
      });
    }
    _updateTotal();
  }

  void _updateTotal() {
    final total = _items.fold<double>(
        0, (p, e) => p + (e['PITEN_VLR_TOTAL'] as num? ?? 0).toDouble());
    _valueController.text = total.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _valueController.dispose();
    _clientController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    if (widget.order != null) return;
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
    String searchType = 'Nome';
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
              if (query.isEmpty) return true;
              if (searchType == 'CPF/CNPJ') {
                return doc.contains(qDigits);
              }
              return name.contains(qLower);
            }).toList();

            return SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 140,
                          child: DropdownButtonFormField<String>(
                            value: searchType,
                            decoration:
                                const InputDecoration(labelText: 'Tipo'),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Nome', child: Text('Nome')),
                              DropdownMenuItem(
                                  value: 'CPF/CNPJ', child: Text('CPF/CNPJ')),
                            ],
                            onChanged: (v) =>
                                setState(() => searchType = v ?? 'Nome'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            autofocus: true,
                            decoration: const InputDecoration(
                              labelText: 'Pesquisar',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (v) => setState(() => query = v),
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

  void _showPhoto(String pathOrUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: pathOrUrl.startsWith('http')
              ? CachedNetworkImage(imageUrl: pathOrUrl)
              : Image.file(File(pathOrUrl)),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _showProductSearch() async {
    if (_products.isEmpty) await _loadProducts();
    String query = '';
    String searchType = 'Nome';
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final filtered = _products.where((p) {
              final name = (p['EPRO_DESCRICAO'] ?? '').toString().toLowerCase();
              final ean = (p['EPRO_COD_EAN'] ?? '').toString();
              if (query.isEmpty) return true;
              if (searchType == 'EAN') {
                return ean.contains(query);
              }
              return name.contains(query.toLowerCase());
            }).toList();
            final priceFormat =
                NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
            final stockFormat = NumberFormat.decimalPattern('pt_BR')
              ..minimumFractionDigits = 2
              ..maximumFractionDigits = 2;
            return SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButton<String>(
                          value: searchType,
                          items: const [
                            DropdownMenuItem(
                                value: 'Nome', child: Text('Nome')),
                            DropdownMenuItem(value: 'EAN', child: Text('EAN')),
                          ],
                          onChanged: (v) =>
                              setState(() => searchType = v ?? 'Nome'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            autofocus: true,
                            decoration: InputDecoration(
                              labelText: 'Pesquisar',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: searchType == 'EAN'
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
                                            query = code.toString();
                                          });
                                        }
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (v) => setState(() => query = v),
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
                        final p = filtered[index];
                        final price =
                            priceFormat.format(p['EPRO_VLR_VAREJO'] ?? 0);
                        final estqAtual = p['EPRO_ESTQ_ATUAL'] ?? 0;
                        final stock = stockFormat.format(estqAtual);
                        Widget leadingWidget = const SizedBox(
                          width: 70,
                          height: 70,
                          child: Icon(Icons.shopping_cart),
                        );
                        final fotos = p['ESTQ_PRODUTO_FOTO'] as List?;
                        if (fotos != null && fotos.isNotEmpty) {
                          final path = fotos.first['EPRO_FOTO_PATH'];
                          final url = fotos.first['EPRO_FOTO_URL'];
                          String? displayPath;
                          if (path is String && path.isNotEmpty) {
                            displayPath = path;
                          } else if (url is String && url.isNotEmpty) {
                            displayPath = url;
                          }
                          if (displayPath != null) {
                            leadingWidget = GestureDetector(
                              onDoubleTap: () => _showPhoto(displayPath!),
                              child: SizedBox(
                                width: 70,
                                height: 70,
                                child: displayPath.startsWith('http')
                                    ? CachedNetworkImage(
                                        imageUrl: displayPath,
                                        fit: BoxFit.cover,
                                        placeholder: (c, s) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    : Image.file(
                                        File(displayPath),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            );
                          }
                        }
                        return ListTile(
                          leading: leadingWidget,
                          title: Text(p['EPRO_DESCRICAO'] ?? ''),
                          subtitle: Text(
                              'EAN: ${p['EPRO_COD_EAN'] ?? ''}\nPreço: $price - Estoque: $stock'),
                          tileColor: estqAtual == 0
                              ? Colors.red.withOpacity(0.2)
                              : null,
                          onTap: () => Navigator.pop(context, p),
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
    return selected;
  }

  Future<void> _addItem() async {
    final product = await _showProductSearch();
    if (product == null) return;
    final stock = (product['EPRO_ESTQ_ATUAL'] as num? ?? 0).toDouble();
    final messenger = ScaffoldMessenger.of(context);
    if (stock <= 0) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Produto sem estoque disponível'),
          backgroundColor: Colors.red));
      return;
    }
    final qtyController = TextEditingController(text: '1');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product['EPRO_DESCRICAO'] ?? ''),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantidade'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final qty = double.tryParse(qtyController.text.replaceAll(',', '.')) ?? 0;
      if (qty > stock) {
        messenger.showSnackBar(SnackBar(
            content: Text('Quantidade maior que estoque disponível ($stock)'),
            backgroundColor: Colors.red));
        return;
      }
      final unit = (product['EPRO_VLR_VAREJO'] as num? ?? 0).toDouble();
      final total = qty * unit;
      setState(() {
        _items.add({
          'EPRO_PK': product['EPRO_PK'],
          'PITEN_QTD': qty,
          'PITEN_VLR_UNITARIO': unit,
          'PITEN_VLR_TOTAL': total,
          'EPRO_DESCRICAO': product['EPRO_DESCRICAO'],
          'EPRO_COD_EAN': product['EPRO_COD_EAN'],
          'EPRO_ESTQ_ATUAL': product['EPRO_ESTQ_ATUAL'],
        });
        _updateTotal();
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _updateTotal();
    });
  }

  Future<void> _editItemQuantity(int index) async {
    final item = _items[index];
    final stock = (item['EPRO_ESTQ_ATUAL'] as num? ?? 0).toDouble();
    final controller =
        TextEditingController(text: item['PITEN_QTD']?.toString() ?? '0');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['EPRO_DESCRICAO'] ?? ''),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantidade'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final qty = double.tryParse(controller.text.replaceAll(',', '.')) ??
          item['PITEN_QTD'];
      final messenger = ScaffoldMessenger.of(context);
      if (stock <= 0) {
        messenger.showSnackBar(const SnackBar(
            content: Text('Produto sem estoque disponível'),
            backgroundColor: Colors.red));
        return;
      }
      if (qty > stock) {
        messenger.showSnackBar(SnackBar(
            content: Text('Quantidade maior que estoque disponível ($stock)'),
            backgroundColor: Colors.red));
        return;
      }
      final unit = (item['PITEN_VLR_UNITARIO'] as num? ?? 0).toDouble();
      setState(() {
        _items[index]['PITEN_QTD'] = qty;
        _items[index]['PITEN_VLR_TOTAL'] = qty * unit;
        _updateTotal();
      });
    }
  }

  void _submit() {
    final total = _items.fold<double>(
        0, (p, e) => p + (e['PITEN_VLR_TOTAL'] as num? ?? 0).toDouble());
    final data = <String, dynamic>{
      'PDOC_DT_EMISSAO': DateFormat('yyyy-MM-dd').format(_date),
      'PDOC_VLR_TOTAL': total,
      'CCOT_PK': _contactPk,
    };
    if (widget.order != null) {
      data['PDOC_PK'] = widget.order!['PDOC_PK'];
    }
    widget.onSave(data, _items);
    Navigator.pop(context);
  }

  Future<void> _printOrder() async {
    if (widget.order == null) return;
    final pdf = await OrderPdf.generate(
      widget.order!,
      _clientController.text,
      _items,
    );
    await Printing.layoutPdf(onLayout: (_) async => pdf);
  }

  Future<void> _shareOrder() async {
    if (widget.order == null) return;
    final pdf = await OrderPdf.generate(
      widget.order!,
      _clientController.text,
      _items,
    );
    final dir = await getTemporaryDirectory();
    final sanitized = _clientController.text.replaceAll(RegExp(r'\s+'), '_');
    final file =
        File('${dir.path}/Pedido_${widget.order!['PDOC_PK']}_$sanitized.pdf');
    await file.writeAsBytes(pdf);
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final value = currency.format(widget.order!['PDOC_VLR_TOTAL'] ?? 0);
    final text =
        'Segue PDF do Pedido Numero: ${widget.order!['PDOC_PK']}\\nValor: $value';
    await Share.shareXFiles([XFile(file.path)], text: text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.order == null ? 'Novo Pedido' : 'Editar Pedido'),
        actions: [
          if (widget.order != null) ...[
            IconButton(onPressed: _printOrder, icon: const Icon(Icons.print)),
            IconButton(onPressed: _shareOrder, icon: const Icon(Icons.share)),
          ],
          IconButton(onPressed: _submit, icon: const Icon(Icons.save)),
        ],
      ),
      body: SafeArea(
        child: ListView(
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Data',
                    suffixIcon: widget.order == null
                        ? IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: _pickDate,
                          )
                        : null,
                  ),
                  controller: TextEditingController(
                      text: DateFormat('yyyy-MM-dd').format(_date)),
                  onTap: widget.order == null ? _pickDate : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _valueController,
                  readOnly: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Valor Total'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // The product table should never exceed the screen width so we
          // constrain its size based on the current layout. Long product
          // descriptions are truncated to avoid horizontal scrolling.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Builder(builder: (context) {
              final tableWidth = MediaQuery.of(context).size.width - 32;
              final nameWidth = tableWidth * 0.45;
              return ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: tableWidth,
                  maxWidth: tableWidth,
                ),
                child: DataTable(
                  border: TableBorder.all(color: Colors.grey),
                  columnSpacing: 12,
                  horizontalMargin: 8,
                  columns: const [
                    DataColumn(label: Text('Nome')),
                  DataColumn(label: Text('Qtd')),
                  DataColumn(label: Text('Vlr Total')),
                  DataColumn(label: Text('')),
                ],
                rows: List.generate(_items.length, (index) {
                  final i = _items[index];
                  final estq = (i['EPRO_ESTQ_ATUAL'] as num?)?.toDouble() ?? 0;
                  final rowColor = estq == 0
                      ? MaterialStateProperty.all(Colors.red.withOpacity(0.2))
                      : null;
                  return DataRow(
                    color: rowColor,
                    cells: [
                      DataCell(
                        SizedBox(
                          width: nameWidth,
                          child: Text(
                            i['EPRO_DESCRICAO'] ?? '',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        InkWell(
                          onDoubleTap: () => _editItemQuantity(index),
                          child: Text('${i['PITEN_QTD']}'),
                        ),
                      ),
                      DataCell(Text('${i['PITEN_VLR_TOTAL']}')),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeItem(index),
                        ),
                      ),
                    ],
                  );
                }),
              )
              );
            }),
          ),          
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Produto'),
            ),
          ),
        ],
      ),
      ),      
    );
  }
}
