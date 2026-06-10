import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

/*
|--------------------------------------------------------------------------
| Order Status Display Screen
|--------------------------------------------------------------------------
| Waiting hall screen for customers to see order progress.
*/

class OrderStatusDisplayScreen extends StatefulWidget {
  const OrderStatusDisplayScreen({super.key});

  @override
  State<OrderStatusDisplayScreen> createState() =>
      _OrderStatusDisplayScreenState();
}

class _OrderStatusDisplayScreenState extends State<OrderStatusDisplayScreen> {
  final ApiService apiService = ApiService();

  Timer? refreshTimer;

  bool isLoading = true;

  List<dynamic> preparingOrders = [];
  List<dynamic> readyOrders = [];
  List<dynamic> receivedOrders = [];

  /*
  |--------------------------------------------------------------------------
  | Init
  |--------------------------------------------------------------------------
  */

  @override
  void initState() {
    super.initState();

    loadOrderStatus();

    refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => loadOrderStatus(),
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
  | Load Order Status
  |--------------------------------------------------------------------------
  */

  Future<void> loadOrderStatus() async {
    try {
      final data = await apiService.getOrderStatusDisplay();

      if (!mounted) return;

      setState(() {
        receivedOrders = data['received'] ?? [];
        preparingOrders = data['preparing'] ?? [];
        readyOrders = data['ready'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Order Number
  |--------------------------------------------------------------------------
  */

  String orderNumber(dynamic order) {
    if (order['daily_order_number'] != null) {
      return order['daily_order_number'].toString();
    }

    return order['order_number']?.toString() ?? 'ORD-${order['id']}';
  }

  /*
  |--------------------------------------------------------------------------
  | Status Column
  |--------------------------------------------------------------------------
  */

  Widget statusColumn({
    required String title,
    required Color color,
    required List<dynamic> orders,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 90,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 38,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            Expanded(
              child: orders.isEmpty
                  ? const Center(
                      child: Text(
                        'No orders',
                        style: TextStyle(fontSize: 28, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 12,
                          ),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: color.withOpacity(0.35)),
                          ),
                          child: Center(
                            child: Text(
                              orderNumber(order),
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Build
  |--------------------------------------------------------------------------
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back'),
                        ),

                        const Expanded(
                          child: Center(
                            child: Text(
                              'ORDER STATUS',
                              style: TextStyle(
                                fontSize: 52,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 100),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Please collect your order when it appears under READY',
                    style: TextStyle(fontSize: 24, color: Colors.white70),
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: Row(
                      children: [
                        statusColumn(
                          title: 'RECEIVED',
                          color: Colors.blue,
                          orders: receivedOrders,
                        ),
                        statusColumn(
                          title: 'PREPARING',
                          color: Colors.orange,
                          orders: preparingOrders,
                        ),
                        statusColumn(
                          title: 'READY',
                          color: Colors.green,
                          orders: readyOrders,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
