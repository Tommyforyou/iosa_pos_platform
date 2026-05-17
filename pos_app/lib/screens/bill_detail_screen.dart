import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/money.dart';
import '../utils/discount.dart';
import 'receipt_screen.dart';

/*
|--------------------------------------------------------------------------
| Bill Detail Screen
|--------------------------------------------------------------------------
| This screen is used by the cashier to review and settle one bill.
|
| Responsibilities:
| - Display bill items
| - Calculate subtotal
| - Apply percentage discount
| - Show VAT included amount
| - Select payment method
| - Process payment
| - Open receipt preview
*/

class BillDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  BillDetailScreen({
    super.key,
    required this.order,
  });

  @override
  State<BillDetailScreen> createState() =>
      _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  /*
  |--------------------------------------------------------------------------
  | API Service
  |--------------------------------------------------------------------------
  */

  final ApiService apiService = ApiService();

  /*
  |--------------------------------------------------------------------------
  | Payment Configuration
  |--------------------------------------------------------------------------
  */

  String paymentMethod = 'cash';
  double discountPercentage = 0;

  /*
  |--------------------------------------------------------------------------
  | Available Payment Methods
  |--------------------------------------------------------------------------
  */

  final List<String> paymentMethods = [
    'cash',
    'card',
    'juice',
    'cheque',
    'complimentary',
  ];

  /*
  |--------------------------------------------------------------------------
  | Available Discount Percentages
  |--------------------------------------------------------------------------
  */

  final List<double> discountOptions = [
    0,
    5,
    10,
    15,
    50,
    100,
  ];

  /*
  |--------------------------------------------------------------------------
  | Order Label
  |--------------------------------------------------------------------------
  | Converts order type/table information into a cashier-friendly label.
  */

  String orderLabel() {
    if (widget.order['order_type'] == 'takeaway') {
      return 'Takeaway';
    }

    if (widget.order['order_type'] == 'delivery') {
      return 'Delivery';
    }

    if (widget.order['table'] != null) {
      return widget.order['table']['table_name'];
    }

    return 'Order';
  }

  /*
  |--------------------------------------------------------------------------
  | Calculate Subtotal
  |--------------------------------------------------------------------------
  | Calculates total before discount.
  */

double subtotal() {
  double total = 0;

  final activeItems = (widget.order['items'] as List<dynamic>)
      .where(
        (item) => item['is_voided'] != true,
      )
      .toList();

  for (final item in activeItems) {
    final quantity = toMoneyDouble(item['quantity']);
    final price = toMoneyDouble(item['unit_price']);

    total += quantity * price;
  }

  return total;
}

  /*
  |--------------------------------------------------------------------------
  | Process Payment
  |--------------------------------------------------------------------------
  | Sends payment data to Laravel backend.
  |
  | Backend will:
  | - mark order as paid
  | - close order
  | - release table if dine-in
  */

  Future<void> processPayment({
    required double subtotalAmount,
    required double discountAmount,
    required double vatIncluded,
    required double finalTotal,
  }) async {
    try {
      final result = await apiService.processRestaurantPayment(
        orderId: widget.order['id'],
        paymentMethod: paymentMethod,
        subtotal: subtotalAmount,
        taxAmount: vatIncluded,
        discountAmount: discountAmount,
        totalAmount: finalTotal,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ??
                'Payment processed successfully',
          ),
        ),
      );

      /*
      |--------------------------------------------------------------------------
      | Open Receipt After Payment
      |--------------------------------------------------------------------------
      */

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptScreen(
            order: widget.order,
            paymentMethod: paymentMethod,
            subtotal: subtotalAmount,
            taxAmount: vatIncluded,
            discountAmount: discountAmount,
            totalAmount: finalTotal,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    /*
    |--------------------------------------------------------------------------
    | Bill Calculations
    |--------------------------------------------------------------------------
    */

    final subtotalAmount = subtotal();

    final discountAmount = calculateDiscountAmount(
      subtotal: subtotalAmount,
      discountPercentage: discountPercentage,
    );

    final finalTotal = calculateFinalTotal(
      subtotal: subtotalAmount,
      discountPercentage: discountPercentage,
    );

    final vatIncluded = calculateVatIncluded(finalTotal);

    /*
    |--------------------------------------------------------------------------
    | Active Bill Items
    |--------------------------------------------------------------------------
    | Voided items must not affect billing totals.
    */    

    final items = (widget.order['items'] as List<dynamic>)
        .where(
          (item) => item['is_voided'] != true,
        )
        .toList();    

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      /*
      |--------------------------------------------------------------------------
      | App Bar
      |--------------------------------------------------------------------------
      */

      appBar: AppBar(
        title: Text('Bill - ${orderLabel()}'),
      ),

      /*
      |--------------------------------------------------------------------------
      | Main Layout
      |--------------------------------------------------------------------------
      | Left: item listing
      | Right: totals, discount, payment method, payment button
      */

      body: Row(
        children: [
          /*
          |--------------------------------------------------------------------------
          | Bill Items
          |--------------------------------------------------------------------------
          */

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                final quantity = toMoneyDouble(item['quantity']);
                final price = toMoneyDouble(item['unit_price']);
                final lineTotal = quantity * price;

                return Card(
                  child: ListTile(
                    title: Text(
                      item['product_name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${quantity.toStringAsFixed(0)} × ${formatMoney(price)}',
                    ),
                    trailing: Text(
                      formatMoney(lineTotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          /*
          |--------------------------------------------------------------------------
          | Bill Summary Panel
          |--------------------------------------------------------------------------
          */

          Container(
            width: 390,
            padding: const EdgeInsets.all(20),
            color: Colors.white,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                /*
                |--------------------------------------------------------------------------
                | Bill Header
                |--------------------------------------------------------------------------
                */

                Text(
                  orderLabel(),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  widget.order['order_number'],
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const Divider(height: 32),

                /*
                |--------------------------------------------------------------------------
                | Discount Selector
                |--------------------------------------------------------------------------
                */

                const Text(
                  'Discount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: discountOptions.map((discount) {
                    final isSelected =
                        discountPercentage == discount;

                    return ChoiceChip(
                      label: Text(
                        '${discount.toStringAsFixed(0)}%',
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          discountPercentage = discount;

                          /*
                          |--------------------------------------------------------------------------
                          | Complimentary Shortcut
                          |--------------------------------------------------------------------------
                          | 100% discount is treated as complimentary.
                          */
                          if (discount == 100) {
                            paymentMethod = 'complimentary';
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const Divider(height: 32),

                /*
                |--------------------------------------------------------------------------
                | Payment Method Selector
                |--------------------------------------------------------------------------
                */

                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: paymentMethods.map((method) {
                    final isSelected =
                        paymentMethod == method;

                    return ChoiceChip(
                      label: Text(method.toUpperCase()),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          paymentMethod = method;

                          /*
                          |--------------------------------------------------------------------------
                          | Complimentary Payment Shortcut
                          |--------------------------------------------------------------------------
                          | Complimentary payment should always make the bill zero.
                          */
                          if (method == 'complimentary') {
                            discountPercentage = 100;
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const Divider(height: 32),

                /*
                |--------------------------------------------------------------------------
                | Totals
                |--------------------------------------------------------------------------
                */

                _SummaryRow(
                  label: 'Subtotal',
                  value: formatMoney(subtotalAmount),
                ),

                _SummaryRow(
                  label:
                      'Discount (${discountPercentage.toStringAsFixed(0)}%)',
                  value: '- ${formatMoney(discountAmount)}',
                ),

                _SummaryRow(
                  label: 'VAT Included',
                  value: formatMoney(vatIncluded),
                ),

                const Divider(height: 28),

                _SummaryRow(
                  label: 'TOTAL',
                  value: formatMoney(finalTotal),
                  isBold: true,
                ),

                const Spacer(),

                /*
                |--------------------------------------------------------------------------
                | Payment Button
                |--------------------------------------------------------------------------
                */

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => processPayment(
                      subtotalAmount: subtotalAmount,
                      discountAmount: discountAmount,
                      vatIncluded: vatIncluded,
                      finalTotal: finalTotal,
                    ),
                    icon: const Icon(Icons.payments),
                    label: Text(
                      paymentMethod == 'complimentary'
                          ? 'Settle Complimentary'
                          : 'Pay ${paymentMethod.toUpperCase()}',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/*
|--------------------------------------------------------------------------
| Summary Row Widget
|--------------------------------------------------------------------------
| Reusable row for bill totals.
*/

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontSize: isBold ? 22 : 15,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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