import 'package:flutter/material.dart';

/*
|--------------------------------------------------------------------------
| Receipt Screen
|--------------------------------------------------------------------------
| This screen displays a print-style receipt after payment.
|
| Current purpose:
| - Preview receipt
| - Show business/order/payment details
| - Prepare for future thermal printer integration
|
| Future improvements:
| - ESC/POS thermal printing
| - PDF export
| - MRA e-invoice QR code
| - VAT invoice format
*/

class ReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  final String paymentMethod;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;

  const ReceiptScreen({
    super.key,
    required this.order,
    required this.paymentMethod,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
  });

  /*
  |--------------------------------------------------------------------------
  | Order Label
  |--------------------------------------------------------------------------
  */
  String orderLabel() {
    if (order['order_type'] == 'takeaway') {
      return 'Takeaway';
    }

    if (order['order_type'] == 'delivery') {
      return 'Delivery';
    }

    if (order['table'] != null) {
      return order['table']['table_name'];
    }

    return 'Order';
  }

  @override
  Widget build(BuildContext context) {
    final items = (order['items'] as List<dynamic>)
    .where(
      (item) => item['is_voided'] != true,
    )
    .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        title: const Text('Receipt Preview'),
      ),

      body: Center(
        child: Container(
          width: 420,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          color: Colors.white,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /*
              |--------------------------------------------------------------------------
              | Business Header
              |--------------------------------------------------------------------------
              */
              const Text(
                'IOSA Restaurant POS Demo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Mauritius',
                textAlign: TextAlign.center,
              ),

              const Divider(height: 32),

              /*
              |--------------------------------------------------------------------------
              | Order Information
              |--------------------------------------------------------------------------
              */
              Text('Order: ${order['order_number']}'),
              Text('Type: ${orderLabel()}'),
              Text('Payment: ${paymentMethod.toUpperCase()}'),

              const Divider(height: 32),

              /*
              |--------------------------------------------------------------------------
              | Receipt Items
              |--------------------------------------------------------------------------
              */
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    final quantity =
                        double.parse(item['quantity'].toString());

                    final price =
                        double.parse(item['unit_price'].toString());

                    final lineTotal = quantity * price;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${quantity.toStringAsFixed(0)} x ${item['product_name']}',
                            ),
                          ),
                          Text(
                            'Rs ${lineTotal.toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const Divider(height: 32),

              /*
              |--------------------------------------------------------------------------
              | Totals
              |--------------------------------------------------------------------------
              */
              _ReceiptRow(
                label: 'Subtotal',
                value: 'Rs ${subtotal.toStringAsFixed(2)}',
              ),

              _ReceiptRow(
                label: 'VAT',
                value: taxAmount == 0
                    ? 'Included'
                    : 'Rs ${taxAmount.toStringAsFixed(2)}',
              ),

              _ReceiptRow(
                label: 'Discount',
                value: 'Rs ${discountAmount.toStringAsFixed(2)}',
              ),

              const Divider(height: 24),

              _ReceiptRow(
                label: 'TOTAL',
                value: 'Rs ${totalAmount.toStringAsFixed(2)}',
                isBold: true,
              ),

              const SizedBox(height: 24),

              /*
              |--------------------------------------------------------------------------
              | Print Button Placeholder
              |--------------------------------------------------------------------------
              */
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Printer integration will be added next.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.print),
                label: const Text('Print Receipt'),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*
|--------------------------------------------------------------------------
| Receipt Row Widget
|--------------------------------------------------------------------------
| Reusable row for receipt totals.
*/

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontSize: isBold ? 20 : 15,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}