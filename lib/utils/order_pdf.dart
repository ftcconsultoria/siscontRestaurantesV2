import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Helper class to generate a PDF representation of an order.
class OrderPdf {
  /// Generates a PDF document for the given [order] and [items].
  /// Returns the PDF file as [Uint8List].
  static Future<Uint8List> generate(
    Map<String, dynamic> order,
    Map<String, dynamic> client,
    String vendorName,
    List<Map<String, dynamic>> items,
  ) async {
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
      ),
    );
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateStr = order['PDOC_DT_EMISSAO']?.toString() ?? '';
    final date = dateStr.isNotEmpty
        ? DateFormat('yyyy-MM-dd').parse(dateStr)
        : DateTime.now();
    final total = items.fold<double>(
        0, (p, e) => p + (e['PITEN_VLR_TOTAL'] as num? ?? 0).toDouble());

    final addressParts = [
      client['CCOT_END_NOME_LOGRADOURO'],
      client['CCOT_END_NUMERO'],
      client['CCOT_END_COMPLEMENTO']
    ].whereType<String>().where((e) => e.isNotEmpty).toList();
    final address = addressParts.join(', ');

    final cityState = [
      client['CCOT_END_MUNICIPIO'],
      client['CCOT_END_UF']
    ].whereType<String>().where((e) => e.isNotEmpty).join(' - ');        

    pw.Widget cell(String text, {bool header = false, bool alignRight = false}) {
      return pw.Container(
        alignment:
            alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          text,
          style: header
              ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
              : const pw.TextStyle(),
        ),
      );
    }
    doc.addPage(           
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(1 * PdfPageFormat.cm),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text(
            'SISCONT - Sistemas de Automação Comercial - (62) 3277-1090',
            style: pw.TextStyle(color: PdfColors.lightBlue, fontSize: 10),
          ),
        ),
        build: (context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Pedido Núm: ${order['PDOC_PK'] ?? ''}',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text('Vendedor: $vendorName'),
              pw.SizedBox(height: 8),

              /// Tabela de informações do cliente
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(2),
                    1: pw.FlexColumnWidth(3),
                  },
                  children: [
                    pw.TableRow(children: [
                      cell('Cliente', header: true),
                      cell(client['CCOT_NOME'] ?? ''),
                    ]),
                    if (client['CCOT_CNPJ'] != null &&
                        (client['CCOT_CNPJ'] as String).isNotEmpty)
                      pw.TableRow(children: [
                        cell('CNPJ', header: true),
                        cell(client['CCOT_CNPJ']),
                      ]),
                    if (client['CCOT_IE'] != null &&
                        (client['CCOT_IE'] as String).isNotEmpty)
                      pw.TableRow(children: [
                        cell('IE', header: true),
                        cell(client['CCOT_IE']),
                      ]),
                    if (address.isNotEmpty)
                      pw.TableRow(children: [
                        cell('Endereço', header: true),
                        cell(address),
                      ]),
                    if (cityState.isNotEmpty)
                      pw.TableRow(children: [
                        cell('Cidade/CEP', header: true),
                        cell('$cityState  CEP: ${client['CCOT_END_CEP'] ?? ''}'),
                      ]),
                    pw.TableRow(children: [
                      cell('Data', header: true),
                      cell(DateFormat('dd/MM/yyyy').format(date)),
                    ]),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              /// Tabela de produtos
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFE0E0E0)),
                    children: [
                      cell('Produto', header: true),
                      cell('Qtd', header: true, alignRight: true),
                      cell('Vlr. Unitario', header: true, alignRight: true),
                      cell('Valor Total', header: true, alignRight: true),
                    ],
                  ),
                  ...List.generate(items.length, (index) {
                    final i = items[index];
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: index.isEven
                            ? PdfColor.fromInt(0xFFF5F5F5)
                            : PdfColor.fromInt(0xFFFFFFFF),
                      ),
                      children: [
                        cell(i['EPRO_DESCRICAO'] ?? ''),
                        cell(i['PITEN_QTD'].toString(), alignRight: true),
                        cell(
                          currency.format(i['PITEN_VLR_UNITARIO'] ?? 0),
                          alignRight: true,
                        ),
                        cell(
                          currency.format(i['PITEN_VLR_TOTAL'] ?? 0),
                          alignRight: true,
                        ),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 10),

              /// Total
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Total: ${currency.format(total)}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),    
    );
    return doc.save();
  }
}
