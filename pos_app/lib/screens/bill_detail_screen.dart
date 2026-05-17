import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/money.dart';
import '../utils/discount.dart';

import 'receipt_screen.dart';

/*
|--------------------------------------------------------------------------
| Bill Detail Screen
|--------------------------------------------------------------------------
| Cashier screen for reviewing and settling one unpaid bill.
|
| Responsibilities:
| - Display active bill items
| - Exclude voided items from totals
| - Allow cashier to void disputed items with reason
| - Apply discount
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

  final List<String> paymentMethods = [
    'cash',
    'card',
    'juice',
    'cheque',
    'complimentary',
  ];

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
  | Active Items
  |--------------------------------------------------------------------------
  | Voided items are excluded from billing totals and receipt.
  */

  List<dynamic> activeItems() {
    return (widget.order['items'] as List<dynamic>)
        .where(
          (item) => item['is_voided'] != true,
        )
        .toList();
  }

  /*
  |--------------------------------------------------------------------------
  | Calculate Subtotal
  |--------------------------------------------------------------------------
  */

  double subtotal() {
    double total = 0;

    for (final item in activeItems()) {
      final quantity = toMoneyDouble(item['quantity']);
      final price = toMoneyDouble(item['unit_price']);

      total += quantity * price;
    }

    return total;
  }

  /*
  |--------------------------------------------------------------------------
  | Mark Item As Voided Locally
  |--------------------------------------------------------------------------
  | Updates UI immediately after successful backend void.
  */

  void markItemAsVoided(int itemId) {
    setState(() {
      final items = widget.order['items'] as List<dynamic>;

      final index = items.indexWhere(
        (item) => item['id'] == itemId,
      );

      if (index >= 0) {
        items[index]['is_voided'] = true;
      }
    });
  }

  /*
  |--------------------------------------------------------------------------
  | Show Void Dialog
  |--------------------------------------------------------------------------
  | Cashier must enter reason before voiding.
  */

  Future<void> showVoidDialog(dynamic item) async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Void Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item['product_name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Void Reason',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Void Item'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final reason = controller.text.trim();

    if (reason.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Void reason is required'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    try {
      await apiService.voidRestaurantOrderItem(
        itemId: item['id'],
        voidReason: reason,
      );

      markItemAsVoided(item['id']);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item voided successfully'),
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

  /*
  |--------------------------------------------------------------------------
  | Process Payment
  |--------------------------------------------------------------------------
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
    final items = activeItems();

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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Bill - ${orderLabel()}'),
      ),
      body: Row(
        children: [
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatMoney(lineTotal),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_forever,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            showVoidDialog(item);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Container(
            width: 390,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    return ChoiceChip(
                      label: Text(
                        '${discount.toStringAsFixed(0)}%',
                      ),
                      selected: discountPercentage == discount,
                      onSelected: (_) {
                        setState(() {
                          discountPercentage = discount;

                          if (discount == 100) {
                            paymentMethod = 'complimentary';
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const Divider(height: 32),

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
                    return ChoiceChip(
                      label: Text(method.toUpperCase()),
                      selected: paymentMethod == method,
                      onSelected: (_) {
                        setState(() {
                          paymentMethod = method;

                          if (method == 'complimentary') {
                            discountPercentage = 100;
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const Divider(height: 32),

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

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: items.isEmpty
                        ? null
                        : () => processPayment(
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