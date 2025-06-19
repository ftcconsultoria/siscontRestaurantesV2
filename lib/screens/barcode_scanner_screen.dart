import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  String? _scannedValue;

  void _onDetect(BarcodeCapture capture) {
    final value = capture.barcodes.first.rawValue;
    if (value != null && value != _scannedValue) {
      setState(() {
        _scannedValue = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear Código')),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          if (_scannedValue != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Código: \$_scannedValue',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, _scannedValue),
                      child: const Text('Usar código'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
