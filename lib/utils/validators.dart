import 'package:flutter/material.dart';

/// Validates a CPF string. Non numeric characters are ignored.
bool isValidCpf(String cpf) {
  cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
  if (cpf.length != 11) return false;
  if (RegExp(r'^(\\d)\\1*\$').hasMatch(cpf)) return false;
  final digits = cpf.split('').map(int.parse).toList();
  var sum = 0;
  for (var i = 0; i < 9; i++) {
    sum += digits[i] * (10 - i);
  }
  var first = 11 - (sum % 11);
  if (first >= 10) first = 0;
  if (first != digits[9]) return false;
  sum = 0;
  for (var i = 0; i < 10; i++) {
    sum += digits[i] * (11 - i);
  }
  var second = 11 - (sum % 11);
  if (second >= 10) second = 0;
  return second == digits[10];
}

/// Validates a CNPJ string. Non numeric characters are ignored.
bool isValidCnpj(String cnpj) {
  cnpj = cnpj.replaceAll(RegExp(r'[^0-9]'), '');
  if (cnpj.length != 14) return false;
  if (RegExp(r'^(\\d)\\1*\$').hasMatch(cnpj)) return false;
  final digits = cnpj.split('').map(int.parse).toList();
  const calc1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  var sum = 0;
  for (var i = 0; i < calc1.length; i++) {
    sum += digits[i] * calc1[i];
  }
  var first = sum % 11;
  first = first < 2 ? 0 : 11 - first;
  if (first != digits[12]) return false;
  const calc2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  sum = 0;
  for (var i = 0; i < calc2.length; i++) {
    sum += digits[i] * calc2[i];
  }
  var second = sum % 11;
  second = second < 2 ? 0 : 11 - second;
  return second == digits[13];
}

/// Shows a SnackBar indicating validity of a CPF or CNPJ.
void showDocumentValidation(
    BuildContext context, String value, bool isPessoaFisica) {
  if (value.trim().isEmpty) return;
  final valid = isPessoaFisica ? isValidCpf(value) : isValidCnpj(value);
  final label = isPessoaFisica ? 'CPF' : 'CNPJ';
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    SnackBar(
      content: Text('$label ${valid ? 'válido' : 'inválido'}'),
      backgroundColor: valid ? Colors.green : Colors.red,
    ),
  );
}

