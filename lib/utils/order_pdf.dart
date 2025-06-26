import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

/// Helper class to generate a PDF representation of an order.
class OrderPdf {
  /// Generates a PDF document for the given [order] and [items].
  /// Returns the PDF file as [Uint8List].
  static Future<Uint8List> generate(
    Map<String, dynamic> order,
    String clientName,
    List<Map<String, dynamic>> items,
  ) async {
    final doc = pw.Document();
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateStr = order['PDOC_DT_EMISSAO']?.toString() ?? '';
    final date = dateStr.isNotEmpty
        ? DateFormat('yyyy-MM-dd').parse(dateStr)
        : DateTime.now();
    final total = items.fold<double>(0,
        (p, e) => p + (e['PITEN_VLR_TOTAL'] as num? ?? 0).toDouble());

    doc.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Pedido ${order['PDOC_PK'] ?? ''}',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Cliente: $clientName'),
              pw.Text('Data: ${DateFormat('dd/MM/yyyy').format(date)}'),
              pw.SizedBox(height: 16),
              pw.Table.fromTextArray(
                headers: ['Produto', 'Qtd', 'Valor Total'],
                data: items
                    .map((i) => [
                          i['EPRO_DESCRICAO'] ?? '',
                          i['PITEN_QTD'].toString(),
                          currency.format(i['PITEN_VLR_TOTAL'] ?? 0),
                        ])
                    .toList(),
                border: pw.TableBorder.all(),
                headerStyle:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                cellStyle: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total: ${currency.format(total)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    return doc.save();
  }
}
