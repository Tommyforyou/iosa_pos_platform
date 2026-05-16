import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'receipt_screen.dart';

/*
|--------------------------------------------------------------------------
| Bill Detail Screen
|--------------------------------------------------------------------------
| This screen displays the detailed bill for one restaurant order.
|
| Responsibilities:
| - Show order identity
| - Show dine-in/takeaway/delivery label
| - Show ordered items
| - Calculate subtotal
| - Prepare for payment processing
*/

class BillDetailScreen extends StatelessWidget {
 final Map<String, dynamic> order;
 /*
 |--------------------------------------------------------------------------
 | API Service
 |--------------------------------------------------------------------------
 */
 final ApiService apiService = ApiService();

    BillDetailScreen({
    super.key,
    required this.order,
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

  /*
  |--------------------------------------------------------------------------
  | Calculate Subtotal
  |--------------------------------------------------------------------------
  */

  double subtotal() {
    double total = 0;

    for (final item in order['items']) {
      final quantity = double.parse(item['quantity'].toString());
      final price = double.parse(item['unit_price'].toString());

      total += quantity * price;
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    final total = subtotal();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Bill - ${orderLabel()}'),
      ),
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
              itemCount: order['items'].length,
              itemBuilder: (context, index) {
                final item = order['items'][index];

                final quantity = double.parse(item['quantity'].toString());
                final price = double.parse(item['unit_price'].toString());
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
                      '${quantity.toStringAsFixed(0)} × Rs ${price.toStringAsFixed(2)}',
                    ),
                    trailing: Text(
                      'Rs ${lineTotal.toStringAsFixed(2)}',
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
            width: 360,
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
                  order['order_number'],
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const Divider(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal'),
                    Text('Rs ${total.toStringAsFixed(2)}'),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('VAT'),
                    Text('Included'),
                  ],
                ),

                const Divider(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rs ${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                    onPressed: () async {

                    /*
                    |--------------------------------------------------------------------------
                    | Process Cash Payment
                    |--------------------------------------------------------------------------
                    */

                    try {

                        final result =
                            await apiService.processRestaurantPayment(

                        orderId: order['id'],

                        paymentMethod: 'cash',

                        subtotal: total,
                        taxAmount: 0,
                        discountAmount: 0,
                        totalAmount: total,
                        );

                        if (!context.mounted) return;

                        /*
                        |--------------------------------------------------------------------------
                        | Show Success Message
                        |--------------------------------------------------------------------------
                        */

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
                        | Close Bill Screen
                        |--------------------------------------------------------------------------
                        */

                        /*
                        |--------------------------------------------------------------------------
                        | Open Receipt Screen
                        |--------------------------------------------------------------------------
                        */

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReceiptScreen(
                              order: order,
                              paymentMethod: 'cash',
                              subtotal: total,
                              taxAmount: 0,
                              discountAmount: 0,
                              totalAmount: total,
                            ),
                          ),
                        );

                    } catch (e) {

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.red,
                        ),
                        );
                    }
                    },

                    icon: const Icon(Icons.payments),

                    label: const Text(
                    'Pay Cash',
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