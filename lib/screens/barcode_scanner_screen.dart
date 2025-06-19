import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatelessWidget {
  const BarcodeScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear Código')),
      body: MobileScanner(
        onDetect: (capture) {
          final barcode = capture.barcodes.first;
          final String? value = barcode.rawValue;
          if (value != null) {
            Navigator.pop(context, value);
          }
        },
      ),
    );
  }
}
