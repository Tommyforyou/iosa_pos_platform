import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'kitchen_performance_dashboard_screen.dart';

/*
|--------------------------------------------------------------------------
| Kitchen Display Screen
|--------------------------------------------------------------------------
| Professional Kitchen Display System (KDS).
|
| Features:
| - live kitchen order cards
| - auto-refresh
| - color-coded statuses
| - kitchen workflow buttons
| - order age display
|
| Workflow:
| sent_to_kitchen
| → preparing
| → ready
| → served
*/

class KitchenDisplayScreen extends StatefulWidget {
  const KitchenDisplayScreen({super.key});

  @override
  State<KitchenDisplayScreen> createState() => _KitchenDisplayScreenState();
}

class _KitchenDisplayScreenState extends State<KitchenDisplayScreen> {
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

  /*
  |--------------------------------------------------------------------------
  | Auto Refresh Timer
  |--------------------------------------------------------------------------
  */

  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();

    loadKitchenOrders();

    /*
    |--------------------------------------------------------------------------
    | Auto Refresh Every 5 Seconds
    |--------------------------------------------------------------------------
    */

    refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => loadKitchenOrders(silent: true),
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  /*
  |--------------------------------------------------------------------------
  | Load Kitchen Orders
  |--------------------------------------------------------------------------
  */

  Future<void> loadKitchenOrders({bool silent = false}) async {
    try {
      final data = await apiService.getKitchenDisplayOrders();

      setState(() {
        orders = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      if (!silent) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Update Order Status
  |--------------------------------------------------------------------------
  */

  Future<void> updateOrderStatus({
    required int orderId,
    required String status,
  }) async {
    try {
      await apiService.updateKitchenOrderStatus(
        orderId: orderId,
        status: status,
      );

      await loadKitchenOrders(silent: true);
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
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
  | Status Color
  |--------------------------------------------------------------------------
  */

  Color statusColor(String status) {
    switch (status) {
      case 'sent_to_kitchen':
        return Colors.orange;

      case 'preparing':
        return Colors.blue;

      case 'ready':
        return Colors.green;

      case 'served':
        return Colors.grey;

      default:
        return Colors.blueGrey;
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Status Label
  |--------------------------------------------------------------------------
  */

  String statusLabel(String status) {
    switch (status) {
      case 'sent_to_kitchen':
        return 'NEW';

      case 'preparing':
        return 'PREPARING';

      case 'ready':
        return 'READY';

      case 'served':
        return 'SERVED';

      default:
        return status.toUpperCase();
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Order Age
  |--------------------------------------------------------------------------
  */

  String orderAge(dynamic order) {
    final createdAt = DateTime.tryParse(order['created_at'].toString());

    if (createdAt == null) {
      return '-';
    }

    final diff = DateTime.now().difference(createdAt);

    if (diff.inMinutes < 1) {
      return 'Just now';
    }

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min';
    }

    return '${diff.inHours} hr ${diff.inMinutes % 60} min';
  }

  /*
  |--------------------------------------------------------------------------
  | Next Action
  |--------------------------------------------------------------------------
  */

  Widget actionButton(dynamic order) {
    final status = order['status'];

    if (status == 'sent_to_kitchen') {
      return ElevatedButton.icon(
        onPressed: () {
          updateOrderStatus(orderId: order['id'], status: 'preparing');
        },
        icon: const Icon(Icons.restaurant),
        label: const Text('Start Preparing'),
      );
    }

    if (status == 'preparing') {
      return ElevatedButton.icon(
        onPressed: () {
          updateOrderStatus(orderId: order['id'], status: 'ready');
        },
        icon: const Icon(Icons.check_circle),
        label: const Text('Mark Ready'),
      );
    }

    if (status == 'ready') {
      return ElevatedButton.icon(
        onPressed: () {
          updateOrderStatus(orderId: order['id'], status: 'served');
        },
        icon: const Icon(Icons.done_all),
        label: const Text('Mark Served'),
      );
    }

    return const SizedBox.shrink();
  }

  /*
  |--------------------------------------------------------------------------
  | Build
  |--------------------------------------------------------------------------
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        title: const Text('Kitchen Display System'),
        actions: [
          /*
          |--------------------------------------------------------------------------
          | Kitchen Dashboard
          |--------------------------------------------------------------------------
          */
          IconButton(
            tooltip: 'Kitchen Dashboard',
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const KitchenPerformanceDashboardScreen(),
                ),
              );
            },
          ),

          /*
          |--------------------------------------------------------------------------
          | Refresh
          |--------------------------------------------------------------------------
          */
          IconButton(
            onPressed: () {
              setState(() {
                isLoading = true;
              });

              loadKitchenOrders();
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
                'No kitchen orders',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final order = orders[index];
                final items = order['items'] as List<dynamic>;
                final status = order['status'];

                return Card(
                  elevation: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /*
                          |--------------------------------------------------------------------------
                          | Order Header
                          |--------------------------------------------------------------------------
                          */
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        color: statusColor(status),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),

                            Text(
                              'Order ${order['daily_order_number'] ?? order['order_number']} • ${orderAge(order)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      /*
                          |--------------------------------------------------------------------------
                          | Status Badge
                          |--------------------------------------------------------------------------
                          */
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor(status).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusLabel(status),
                            style: TextStyle(
                              color: statusColor(status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      /*
                          |--------------------------------------------------------------------------
                          | Item List
                          |--------------------------------------------------------------------------
                          */
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: items.length,
                          itemBuilder: (context, itemIndex) {
                            final item = items[itemIndex];

                            if (item['is_voided'] == true) {
                              return const SizedBox.shrink();
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 15,
                                    child: Text(
                                      item['quantity']
                                          .toString()
                                          .split('.')
                                          .first,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item['product_name'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      /*
                          |--------------------------------------------------------------------------
                          | Action Button
                          |--------------------------------------------------------------------------
                          */
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: actionButton(order),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
