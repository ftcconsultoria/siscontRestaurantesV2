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
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'PEDIDO ${order['PDOC_PK'] ?? ''}',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Cliente: $clientName'),
                  pw.Text('Data: ${DateFormat('dd/MM/yyyy').format(date)}'),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Table.fromTextArray(
                headers: ['Produto', 'Qtd', 'Unit.', 'Valor Total'],
                data: items
                    .map((i) => [
                          i['EPRO_DESCRICAO'] ?? '',
                          i['PITEN_QTD'].toString(),
                          currency.format(i['PITEN_VLR_UNITARIO'] ?? 0),
                          currency.format(i['PITEN_VLR_TOTAL'] ?? 0),
                        ])
                    .toList(),
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration:
                    const pw.BoxDecoration(color: pw.PdfColors.grey300),
                cellStyle: const pw.TextStyle(fontSize: 12),
                cellAlignment: pw.Alignment.centerLeft,
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
