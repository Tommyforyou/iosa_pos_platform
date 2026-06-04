import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

/*
|--------------------------------------------------------------------------
| Customer Orders Screen
|--------------------------------------------------------------------------
| Shows QR code customer orders waiting for cashier approval.
*/

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  final ApiService apiService = ApiService();

  bool isLoading = true;

  List<dynamic> orders = [];

  Timer? refreshTimer;

  /*
  |--------------------------------------------------------------------------
  | Initial Load
  |--------------------------------------------------------------------------
  */

  @override
  void initState() {
    super.initState();

    loadOrders();

    /*
    |--------------------------------------------------------------------------
    | Auto Refresh
    |--------------------------------------------------------------------------
    */

    refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => loadOrders(),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Dispose
  |--------------------------------------------------------------------------
  */

  @override
  void dispose() {
    refreshTimer?.cancel();

    super.dispose();
  }

  /*
  |--------------------------------------------------------------------------
  | Load Customer Orders
  |--------------------------------------------------------------------------
  */

  Future<void> loadOrders() async {
    try {
      final data = await apiService.getCustomerOrders();

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
  | Approve Order
  |--------------------------------------------------------------------------
  */

  Future<void> approveOrder(int orderId) async {
    try {
      await apiService.approveCustomerOrder(orderId);

      await loadOrders();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer order approved'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Reject Order
  |--------------------------------------------------------------------------
  */

  Future<void> rejectOrder(int orderId) async {
    try {
      await apiService.rejectCustomerOrder(orderId);

      await loadOrders();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer order rejected'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Build
  |--------------------------------------------------------------------------
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Customer Orders'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: loadOrders),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? const Center(child: Text('No pending customer orders'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];

                final table = order['table'];
                final items = order['items'] ?? [];

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
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
                            const Icon(Icons.qr_code_2),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                table?['table_name'] ?? 'No Table',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'CUSTOMER ORDER',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 24),

                        /*
                            |--------------------------------------------------------------------------
                            | Order Items
                            |--------------------------------------------------------------------------
                            */
                        ...items.map((item) {
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
                                Text(
                                  'Rs ${item['unit_price']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 12),

                        /*
                            |--------------------------------------------------------------------------
                            | Total
                            |--------------------------------------------------------------------------
                            */
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Total: Rs ${order['total_amount']}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        /*
                            |--------------------------------------------------------------------------
                            | Actions
                            |--------------------------------------------------------------------------
                            */
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.check),
                                label: const Text('Approve'),
                                onPressed: () => approveOrder(order['id']),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.close),
                                label: const Text('Reject'),
                                onPressed: () => rejectOrder(order['id']),
                              ),
                            ),
                          ],
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
