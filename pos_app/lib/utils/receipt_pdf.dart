import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'money.dart';

/*
|--------------------------------------------------------------------------
| Generate Thermal Receipt PDF
|--------------------------------------------------------------------------
| 80mm thermal receipt format.
|
| Supports:
| - compact POS receipt layout
| - buzzer number
| - customer details
| - VAT-exclusive subtotal
| - VAT amount
| - discount
| - total
| - payment method
*/

Future<Uint8List> generateReceiptPdf({
  required Map<String, dynamic> order,
  required String paymentMethod,
  required double subtotal,
  required double taxAmount,
  required double discountAmount,
  required double totalAmount,
}) async {
  final pdf = pw.Document();

  /*
  |--------------------------------------------------------------------------
  | 80mm Thermal Page Format
  |--------------------------------------------------------------------------
  */

  final pageFormat = PdfPageFormat.roll80.copyWith(
    marginLeft: 8,
    marginRight: 8,
    marginTop: 8,
    marginBottom: 8,
  );

  /*
  |--------------------------------------------------------------------------
  | Active Items
  |--------------------------------------------------------------------------
  */

  final items = (order['items'] as List<dynamic>)
      .where((item) => item['is_voided'] != true)
      .toList();

  /*
  |--------------------------------------------------------------------------
  | VAT Exclusive Calculation
  |--------------------------------------------------------------------------
  | Current totals are VAT-inclusive.
  */

  final vatExclusiveTotal = totalAmount - taxAmount;

  final taxableSales = vatExclusiveTotal;

  /*
  |--------------------------------------------------------------------------
  | Customer Details
  |--------------------------------------------------------------------------
  */

  final customer = order['customer'];
  print('RECEIPT ORDER BUZZER: ${order['buzzer_number']}');
  
  pdf.addPage(
    pw.Page(
      pageFormat: pageFormat,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            /*
            |--------------------------------------------------------------------------
            | Header
            |--------------------------------------------------------------------------
            */

            pw.Center(
              child: pw.Text(
                'IOSA RESTAURANT',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            pw.Center(
              child: pw.Text(
                'Thermal Receipt',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),

            _line(),

            _row('Receipt', order['order_number']?.toString() ?? '-'),
            _row('Date', _formatDate(DateTime.now())),
            _row('Payment', paymentMethod.toUpperCase()),

            if (order['buzzer_number'] != null &&
                order['buzzer_number'].toString().isNotEmpty)
              _row('Buzzer', order['buzzer_number'].toString(), isBold: true),

            if (customer != null) ...[
              _line(),
              _row('Customer', customer['name']?.toString() ?? ''),
              _row('Phone', customer['phone']?.toString() ?? ''),
              if (customer['address'] != null &&
                  customer['address'].toString().isNotEmpty)
                pw.Text(
                  'Address: ${customer['address']}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
            ],

            _line(),

            /*
            |--------------------------------------------------------------------------
            | Items
            |--------------------------------------------------------------------------
            */

            ...items.map((item) {
              final qty = toMoneyDouble(item['quantity']);
              final price = toMoneyDouble(item['unit_price']);
              final lineTotal = qty * price;

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    item['product_name']?.toString() ?? '',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  _row(
                    '${qty.toStringAsFixed(0)} x ${formatMoney(price)}',
                    formatMoney(lineTotal),
                  ),
                  pw.SizedBox(height: 3),
                ],
              );
            }),

            _line(),

            /*
            |--------------------------------------------------------------------------
            | VAT Summary
            |--------------------------------------------------------------------------
            */

            _row(
              'Taxable Sales',
              formatMoney(taxableSales),
            ),

            _row(
              'VAT',
              formatMoney(taxAmount),
            ),

            if (discountAmount > 0)
              _row(
                'Discount',
                '- ${formatMoney(discountAmount)}',
              ),

            _line(),

            _row(
              'TOTAL',
              formatMoney(totalAmount),
              isBold: true,
              fontSize: 12,
            ),

            _line(),

            /*
            |--------------------------------------------------------------------------
            | Footer
            |--------------------------------------------------------------------------
            */

            pw.Center(
              child: pw.Text(
                'Thank you',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            pw.SizedBox(height: 8),

            pw.Center(
              child: pw.Text(
                'Powered by IOSA POS',
                style: const pw.TextStyle(fontSize: 7),
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
| Row Helper
|--------------------------------------------------------------------------
*/

pw.Widget _row(
  String left,
  String right, {
  bool isBold = false,
  double fontSize = 8,
}) {
  final style = pw.TextStyle(
    fontSize: fontSize,
    fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
  );

  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Text(left, style: style),
        ),
        pw.SizedBox(width: 4),
        pw.Expanded(
          flex: 2,
          child: pw.Text(
            right,
            textAlign: pw.TextAlign.right,
            style: style,
          ),
        ),
      ],
    ),
  );
}

/*
|--------------------------------------------------------------------------
| Separator Line
|--------------------------------------------------------------------------
*/

pw.Widget _line() {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 5),
    child: pw.Divider(thickness: 0.6),
  );
}

/*
|--------------------------------------------------------------------------
| Date Formatter
|--------------------------------------------------------------------------
*/

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}