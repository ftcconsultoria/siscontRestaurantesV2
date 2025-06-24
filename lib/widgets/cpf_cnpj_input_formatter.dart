import 'package:flutter/services.dart';

/// Formats input as CPF or CNPJ depending on [isCpf].
class CpfCnpjInputFormatter extends TextInputFormatter {
  final bool isCpf;

  CpfCnpjInputFormatter({required this.isCpf});

  static String formatCpf(String digits) {
    digits = digits.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 11) digits = digits.substring(0, 11);
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  static String formatCnpj(String digits) {
    digits = digits.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 14) digits = digits.substring(0, 14);
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8) buffer.write('/');
      if (i == 12) buffer.write('-');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final masked = isCpf ? formatCpf(digits) : formatCnpj(digits);
    return TextEditingValue(
      text: masked,
      selection: TextSelection.collapsed(offset: masked.length),
    );
  }
}
