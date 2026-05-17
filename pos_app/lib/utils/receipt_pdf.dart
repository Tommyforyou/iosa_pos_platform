import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'money.dart';

/*
|--------------------------------------------------------------------------
| Generate Receipt PDF
|--------------------------------------------------------------------------
| Creates printable POS receipt PDF.
|
| Current Features:
| - business title
| - order number
| - item listing
| - VAT included
| - discount
| - payment method
| - totals
|
| Future Features:
| - logo
| - QR code
| - fiscal number
| - barcode
| - thermal printer formatting
*/

Future<Uint8List> generateReceiptPdf({
  required Map<String, dynamic> order,
  required String paymentMethod,
  required double subtotal,
  required double taxAmount,
  required double discountAmount,
  required double totalAmount,
}) async {
  /*
  |--------------------------------------------------------------------------
  | PDF Document
  |--------------------------------------------------------------------------
  */

  final pdf = pw.Document();

  /*
  |--------------------------------------------------------------------------
  | Active Items
  |--------------------------------------------------------------------------
  */

  final items = (order['items'] as List<dynamic>)
      .where(
        (item) => item['is_voided'] != true,
      )
      .toList();

  /*
  |--------------------------------------------------------------------------
  | Build PDF Page
  |--------------------------------------------------------------------------
  */

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,

      build: (context) {
        return pw.Column(
          crossAxisAlignment:
              pw.CrossAxisAlignment.start,

          children: [
            /*
            |--------------------------------------------------------------------------
            | Business Header
            |--------------------------------------------------------------------------
            */

            pw.Center(
              child: pw.Text(
                'IOSA POS RESTAURANT',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            pw.SizedBox(height: 6),

            pw.Center(
              child: pw.Text(
                'Restaurant Receipt',
                style: const pw.TextStyle(
                  fontSize: 14,
                ),
              ),
            ),

            pw.Divider(),

            /*
            |--------------------------------------------------------------------------
            | Order Information
            |--------------------------------------------------------------------------
            */

            pw.Text(
              'Order Number: ${order['order_number']}',
            ),

            pw.Text(
              'Payment Method: ${paymentMethod.toUpperCase()}',
            ),

            pw.Text(
              'Date: ${DateTime.now()}',
            ),

            pw.SizedBox(height: 16),

            /*
            |--------------------------------------------------------------------------
            | Item Listing
            |--------------------------------------------------------------------------
            */

            pw.Table(
              border: pw.TableBorder.all(),

              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(2),
              },

              children: [
                /*
                |--------------------------------------------------------------------------
                | Table Header
                |--------------------------------------------------------------------------
                */

                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),

                  children: [
                    _cell(
                      'Item',
                      isBold: true,
                    ),

                    _cell(
                      'Qty',
                      isBold: true,
                    ),

                    _cell(
                      'Total',
                      isBold: true,
                    ),
                  ],
                ),

                /*
                |--------------------------------------------------------------------------
                | Item Rows
                |--------------------------------------------------------------------------
                */

                ...items.map((item) {
                  final quantity =
                      toMoneyDouble(item['quantity']);

                  final price =
                      toMoneyDouble(item['unit_price']);

                  final lineTotal =
                      quantity * price;

                  return pw.TableRow(
                    children: [
                      _cell(
                        item['product_name'],
                      ),

                      _cell(
                        quantity
                            .toStringAsFixed(0),
                      ),

                      _cell(
                        formatMoney(lineTotal),
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 20),

            /*
            |--------------------------------------------------------------------------
            | Financial Totals
            |--------------------------------------------------------------------------
            */

            _summaryRow(
              'Subtotal',
              formatMoney(subtotal),
            ),

            _summaryRow(
              'Discount',
              '- ${formatMoney(discountAmount)}',
            ),

            _summaryRow(
              'VAT Included',
              formatMoney(taxAmount),
            ),

            pw.Divider(),

            _summaryRow(
              'TOTAL',
              formatMoney(totalAmount),
              isBold: true,
            ),

            pw.SizedBox(height: 30),

            /*
            |--------------------------------------------------------------------------
            | Footer
            |--------------------------------------------------------------------------
            */

            pw.Center(
              child: pw.Text(
                'Thank you for your visit',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

/*
|--------------------------------------------------------------------------
| Table Cell Helper
|--------------------------------------------------------------------------
*/

pw.Widget _cell(
  String text, {
  bool isBold = false,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(8),

    child: pw.Text(
      text,

      style: pw.TextStyle(
        fontWeight:
            isBold
                ? pw.FontWeight.bold
                : pw.FontWeight.normal,
      ),
    ),
  );
}

/*
|--------------------------------------------------------------------------
| Summary Row Helper
|--------------------------------------------------------------------------
*/

pw.Widget _summaryRow(
  String label,
  String value, {
  bool isBold = false,
}) {
  final style = pw.TextStyle(
    fontSize: isBold ? 16 : 12,
    fontWeight:
        isBold
            ? pw.FontWeight.bold
            : pw.FontWeight.normal,
  );

  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(
      vertical: 4,
    ),

    child: pw.Row(
      mainAxisAlignment:
          pw.MainAxisAlignment.spaceBetween,

      children: [
        pw.Text(label, style: style),
        pw.Text(value, style: style),
      ],
    ),
  );
}