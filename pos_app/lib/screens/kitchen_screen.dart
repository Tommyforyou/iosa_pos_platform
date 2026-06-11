import 'dart:async';
import 'package:flutter/material.dart';

import '../services/api_service.dart';

/*
|--------------------------------------------------------------------------
| Kitchen Screen
|--------------------------------------------------------------------------
| Kitchen Display System (KDS).
|
| Purpose:
| - show active kitchen orders
| - show table/takeaway/delivery source
| - show buzzer number for food court/counter orders
| - auto-refresh kitchen orders
| - update kitchen item statuses
|
| Workflow:
| pending
| → preparing
| → ready
| → served
*/

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
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

    loadOrders();

    /*
    |--------------------------------------------------------------------------
    | Auto Refresh Every 5 Seconds
    |--------------------------------------------------------------------------
    */

    refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => loadOrders(silent: true),
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

  Future<void> loadOrders({bool silent = false}) async {
    try {
      final data = await apiService.getKitchenOrders();

      if (!mounted) return;

      setState(() {
        orders = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      if (!silent && mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Table / Order Label
  |--------------------------------------------------------------------------
  */

  String tableName(dynamic order) {
    if (order['order_type'] == 'takeaway') {
      return 'Takeaway';
    }

    if (order['order_type'] == 'delivery') {
      return 'Delivery';
    }

    if (order['table'] == null) {
      return 'No Table';
    }

    return order['table']['table_name'] ?? 'Table';
  }

  /*
  |--------------------------------------------------------------------------
  | Kitchen Status Color
  |--------------------------------------------------------------------------
  */

  Color kitchenStatusColor(String status) {
    switch (status) {
      case 'pending':
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

    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }

  /*
  |--------------------------------------------------------------------------
  | Header Status
  |--------------------------------------------------------------------------
  | Uses first active item status to color the whole kitchen card.
  */

  String headerStatus(List<dynamic> items) {
    if (items.isEmpty) {
      return 'pending';
    }

    return items.first['kitchen_status'] ?? 'pending';
  }

  /*
  |--------------------------------------------------------------------------
  | Update All Items
  |--------------------------------------------------------------------------
  */

  Future<void> updateAllItems({
    required List<dynamic> items,
    required String kitchenStatus,
  }) async {
    try {
      for (final item in items) {
        await apiService.updateKitchenItemStatus(
          itemId: item['id'],
          kitchenStatus: kitchenStatus,
        );
      }

      await loadOrders(silent: true);
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
  | Build Order Header
  |--------------------------------------------------------------------------
  */

  Widget buildOrderHeader({
    required dynamic order,
    required List<dynamic> items,
  }) {
    final status = headerStatus(items);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kitchenStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /*
          |--------------------------------------------------------------------------
          | Table / Order Type
          |--------------------------------------------------------------------------
          */
          Text(
            tableName(order),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 4),

          /*
          |--------------------------------------------------------------------------
          | Order Number And Age
          |--------------------------------------------------------------------------
          */
          Text(
            'Order: ${order['daily_order_number'] ?? order['order_number']} • ${orderAge(order)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),

          /*
          |--------------------------------------------------------------------------
          | Food Court Buzzer Number
          |--------------------------------------------------------------------------
          */
          if (order['buzzer_number'] != null &&
              order['buzzer_number'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'BUZZER ${order['buzzer_number']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Build Kitchen Item Row
  |--------------------------------------------------------------------------
  */

  Widget buildKitchenItem(dynamic item) {
    if (item['is_voided'] == true) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /*
          |--------------------------------------------------------------------------
          | Quantity Badge
          |--------------------------------------------------------------------------
          */
          CircleAvatar(
            radius: 14,
            child: Text(
              item['quantity']
                  .toString()
                  .replaceAll('.000', '')
                  .split('.')
                  .first,
            ),
          ),

          const SizedBox(width: 10),

          /*
          |--------------------------------------------------------------------------
          | Product Details
          |--------------------------------------------------------------------------
          */
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['product_name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 3),

                Text(
                  'Status: ${item['kitchen_status']}',
                  style: TextStyle(
                    color: kitchenStatusColor(
                      item['kitchen_status'] ?? 'pending',
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                if (item['notes'] != null &&
                    item['notes'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item['notes'],
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Build Kitchen Actions
  |--------------------------------------------------------------------------
  */

  Widget buildKitchenActions(List<dynamic> items) {
    final activeItems = items.where((item) => item['is_voided'] != true);

    final allPreparing =
        activeItems.isNotEmpty &&
        activeItems.every((item) => item['kitchen_status'] == 'preparing');

    final allReady =
        activeItems.isNotEmpty &&
        activeItems.every((item) => item['kitchen_status'] == 'ready');

    final allServed =
        activeItems.isNotEmpty &&
        activeItems.every((item) => item['kitchen_status'] == 'served');

    return Column(
      children: [
        /*
        |--------------------------------------------------------------------------
        | Set Preparing
        |--------------------------------------------------------------------------
        */
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: allPreparing || allReady || allServed
                ? null
                : () async {
                    await updateAllItems(
                      items: items,
                      kitchenStatus: 'preparing',
                    );
                  },
            icon: const Icon(Icons.restaurant),
            label: Text(
              allPreparing || allReady || allServed
                  ? 'Preparing Started'
                  : 'Set All To Preparing',
            ),
          ),
        ),

        const SizedBox(height: 8),

        /*
        |--------------------------------------------------------------------------
        | Mark Ready
        |--------------------------------------------------------------------------
        */
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: allReady || allServed
                ? null
                : () async {
                    await updateAllItems(items: items, kitchenStatus: 'ready');
                  },
            icon: const Icon(Icons.check_circle_outline),
            label: Text(allReady || allServed ? 'Ready' : 'Mark Ready'),
          ),
        ),

        const SizedBox(height: 8),

        /*
        |--------------------------------------------------------------------------
        | Mark Served
        |--------------------------------------------------------------------------
        */
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: allServed
                ? null
                : () async {
                    await updateAllItems(items: items, kitchenStatus: 'served');
                  },
            icon: const Icon(Icons.done_all),
            label: Text(allServed ? 'Served' : 'Mark Served'),
          ),
        ),
      ],
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
      backgroundColor: const Color(0xFFF8FAFC),

      /*
      |--------------------------------------------------------------------------
      | App Bar
      |--------------------------------------------------------------------------
      */
      appBar: AppBar(
        title: const Text('Kitchen Display'),
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

      /*
      |--------------------------------------------------------------------------
      | Body
      |--------------------------------------------------------------------------
      */
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? const Center(
              child: Text(
                'No kitchen orders',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final order = orders[index];

                final items = (order['items'] as List<dynamic>? ?? [])
                    .where((item) => item['is_voided'] != true)
                    .toList();

                return Card(
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /*
                            |--------------------------------------------------------------------------
                            | Order Header
                            |--------------------------------------------------------------------------
                            */
                        buildOrderHeader(order: order, items: items),

                        const Divider(height: 24),

                        /*
                            |--------------------------------------------------------------------------
                            | Kitchen Item List
                            |--------------------------------------------------------------------------
                            */
                        Expanded(
                          child: items.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No active items',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: items.length,
                                  itemBuilder: (context, itemIndex) {
                                    final item = items[itemIndex];

                                    return buildKitchenItem(item);
                                  },
                                ),
                        ),

                        const SizedBox(height: 8),

                        /*
                            |--------------------------------------------------------------------------
                            | Kitchen Action Buttons
                            |--------------------------------------------------------------------------
                            */
                        buildKitchenActions(items),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
