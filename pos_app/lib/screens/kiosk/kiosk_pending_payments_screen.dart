import 'package:flutter/material.dart';

import '../../services/api_service.dart';

/*
|--------------------------------------------------------------------------
| Kiosk Pending Payments Screen
|--------------------------------------------------------------------------
| Cashier receives payment for kiosk orders before sending to kitchen.
*/

class KioskPendingPaymentsScreen extends StatefulWidget {
  const KioskPendingPaymentsScreen({super.key});

  @override
  State<KioskPendingPaymentsScreen> createState() =>
      _KioskPendingPaymentsScreenState();
}

class _KioskPendingPaymentsScreenState
    extends State<KioskPendingPaymentsScreen> {
  /*
  |--------------------------------------------------------------------------
  | Services
  |--------------------------------------------------------------------------
  */

  final ApiService apiService = ApiService();

  /*
  |--------------------------------------------------------------------------
  | State
  |--------------------------------------------------------------------------
  */

  bool isLoading = true;

  List<dynamic> orders = [];

  /*
  |--------------------------------------------------------------------------
  | Init State
  |--------------------------------------------------------------------------
  */

  @override
  void initState() {
    super.initState();

    loadOrders();
  }

  /*
  |--------------------------------------------------------------------------
  | Load Pending Kiosk Orders
  |--------------------------------------------------------------------------
  */

  Future<void> loadOrders() async {
    try {
      final data = await apiService.getPendingKioskOrders();

      if (!mounted) return;

      setState(() {
        orders = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Receive Payment
  |--------------------------------------------------------------------------
  */

  Future<void> receivePayment(int orderId, String paymentMethod) async {
    try {
      await apiService.payKioskOrder(
        orderId: orderId,
        paymentMethod: paymentMethod,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment received. Order sent to kitchen.'),
          backgroundColor: Colors.green,
        ),
      );

      await loadOrders();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Payment Method Dialog
  |--------------------------------------------------------------------------
  */

  Future<void> showPaymentDialog(dynamic order) async {
    String selectedMethod = 'cash';

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Receive Payment - ${order['order_number'] ?? order['id']}',
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /*
                    |--------------------------------------------------------------------------
                    | Amount
                    |--------------------------------------------------------------------------
                    */
                    Text(
                      'Total: Rs ${order['total_amount']}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(height: 20),

                    /*
                    |--------------------------------------------------------------------------
                    | Payment Method
                    |--------------------------------------------------------------------------
                    */
                    DropdownButtonFormField<String>(
                      value: selectedMethod,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'card', child: Text('Card')),
                        DropdownMenuItem(value: 'juice', child: Text('Juice')),
                        DropdownMenuItem(
                          value: 'bank_transfer',
                          child: Text('Bank Transfer'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedMethod = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Receive Payment'),
                  onPressed: () async {
                    Navigator.pop(context);

                    await receivePayment(order['id'], selectedMethod);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Build Screen
  |--------------------------------------------------------------------------
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiosk Pending Payments'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: loadOrders),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? const Center(
              child: Text(
                'No pending kiosk payments',
                style: TextStyle(fontSize: 20, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final items = order['items'] ?? [];

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /*
                            |--------------------------------------------------------------------------
                            | Order Header
                            |--------------------------------------------------------------------------
                            */
                        Row(
                          children: [
                            const Icon(Icons.touch_app, color: Colors.orange),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                order['order_number'] ?? 'K-${order['id']}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              'Rs ${order['total_amount']}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 24),

                        /*
                            |--------------------------------------------------------------------------
                            | Items
                            |--------------------------------------------------------------------------
                            */
                        ...items.map<Widget>((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Text(
                                  '${item['quantity']} x',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(item['product_name'] ?? 'Item'),
                                ),
                                Text('Rs ${item['unit_price']}'),
                              ],
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 16),

                        /*
                            |--------------------------------------------------------------------------
                            | Action
                            |--------------------------------------------------------------------------
                            */
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.payments),
                            label: const Text('Receive Payment'),
                            onPressed: () => showPaymentDialog(order),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
