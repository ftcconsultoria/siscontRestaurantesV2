import 'package:flutter/material.dart';
import '../screens/barcode_scanner_screen.dart';

class ProductFormDialog extends StatefulWidget {
  final Map<String, dynamic>? product;
  final ValueChanged<Map<String, dynamic>> onSave;

  const ProductFormDialog({Key? key, this.product, required this.onSave})
      : super(key: key);

  @override
  /// Creates the mutable state for the dialog.
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  late TextEditingController _eanController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;

  @override
  /// Initializes the form controllers with existing product data.
  void initState() {
    super.initState();
    _eanController =
        TextEditingController(text: widget.product?['EPRO_COD_EAN']?.toString() ?? '');
    _descController = TextEditingController(
        text: widget.product?['EPRO_DESCRICAO']?.toString().toUpperCase() ?? '');
    _priceController =
        TextEditingController(text: widget.product?['EPRO_VLR_VAREJO']?.toString() ?? '');
    _stockController =
        TextEditingController(text: widget.product?['EPRO_ESTQ_ATUAL']?.toString() ?? '');
  }

  @override
  /// Disposes all controllers to free resources.
  void dispose() {
    _eanController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  /// Collects the form data and returns it via the callback.
  void _submit() {
    final data = <String, dynamic>{
      'EPRO_COD_EAN': _eanController.text,
      'EPRO_DESCRICAO': _descController.text.toUpperCase(),
      'EPRO_VLR_VAREJO':
          double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0,
      'EPRO_ESTQ_ATUAL':
          double.tryParse(_stockController.text.replaceAll(',', '.')) ?? 0,
    };
    if (widget.product != null) {
      data['EPRO_PK'] = widget.product!['EPRO_PK'];
    }
    widget.onSave(data);
    Navigator.pop(context);
  }

  @override
  /// Builds the dialog containing the product form fields.
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Novo Produto' : 'Editar Produto'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _eanController,
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
                    _eanController.text = code.toString();
                  }
                },
              ),
            ),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(labelText: 'Descrição'),
          ),
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(labelText: 'Preço'),
            keyboardType: TextInputType.number,
          ),
            TextField(
              controller: _stockController,
              decoration: const InputDecoration(labelText: 'Estoque'),
              keyboardType: TextInputType.number,
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
