import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'bill_detail_screen.dart';

/*
|--------------------------------------------------------------------------
| Billing Screen
|--------------------------------------------------------------------------
| This screen is used by the cashier to view active orders that are ready
| for payment.
|
| Current responsibilities:
| - Load billable orders from Laravel
| - Display dine-in, takeaway, and delivery orders
| - Calculate simple order totals
|
| Next responsibilities:
| - Open payment screen
| - Save payment
| - Close order
| - Free dine-in table after payment
*/

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  /*
  |--------------------------------------------------------------------------
  | API Service
  |--------------------------------------------------------------------------
  */

  final ApiService apiService = ApiService();

  /*
  |--------------------------------------------------------------------------
  | Screen State
  |--------------------------------------------------------------------------
  */

  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  /*
  |--------------------------------------------------------------------------
  | Load Billable Orders
  |--------------------------------------------------------------------------
  */

  Future<void> loadOrders() async {
    try {
      final data = await apiService.getBillableOrders();

      setState(() {
        orders = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      setState(() {
        isLoading = false;
      });
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Order Label
  |--------------------------------------------------------------------------
  */

  String orderLabel(dynamic order) {
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
  | Calculate Order Total
  |--------------------------------------------------------------------------
  */

  double calculateTotal(dynamic order) {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        title: const Text('Billing / Cashier'),

        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isLoading = true;
              });

              loadOrders();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(
                  child: Text(
                    'No billable orders',
                    style: TextStyle(fontSize: 22),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final total = calculateTotal(order);

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.receipt_long),
                        ),
                        title: Text(
                          orderLabel(order),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text(
                          '${order['order_number']} • ${order['order_type']}',
                        ),
                        trailing: Text(
                          'Rs ${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BillDetailScreen(order: order),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}