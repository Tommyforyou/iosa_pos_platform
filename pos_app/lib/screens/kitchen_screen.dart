import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

/*
|--------------------------------------------------------------------------
| Kitchen Screen
|--------------------------------------------------------------------------
| This screen is the Kitchen Display System (KDS).
|
| Purpose:
| - Show active kitchen orders
| - Show item preparation statuses
| - Allow kitchen staff to update order progress
|
| Workflow:
| pending
|    ↓
| preparing
|    ↓
| ready
|    ↓
| served
|
| This screen is intended for:
| - kitchen monitors
| - tablets
| - cashier verification
| - food preparation workflow management
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
  | Handles communication with Laravel backend.
  */
  final ApiService apiService = ApiService();

  /*
  |--------------------------------------------------------------------------
  | Screen State
  |--------------------------------------------------------------------------
  | orders: active kitchen orders from backend
  | isLoading: controls loading spinner state
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

    /*
    |--------------------------------------------------------------------------
    | Initial Kitchen Load
    |--------------------------------------------------------------------------
    | Load active orders immediately when kitchen screen opens.
    */
    loadOrders();

    /*
    |--------------------------------------------------------------------------
    | Auto Refresh Every 5 Seconds
    |--------------------------------------------------------------------------
    */

    refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => loadOrders(),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Load Kitchen Orders
  |--------------------------------------------------------------------------
  | Loads active restaurant orders from Laravel.
  |
  | These are displayed on the kitchen display screen.
  */
  Future<void> loadOrders() async {
    try {
      final data = await apiService.getKitchenOrders();

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
  | Table Name Helper
  |--------------------------------------------------------------------------
  | Determines how order source is displayed.
  |
  | Examples:
  | - Table 4
  | - Takeaway
  | - Delivery
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

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
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
    final createdAt = DateTime.tryParse(
      order['created_at'].toString(),
    );

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
  | Build
  |--------------------------------------------------------------------------
  */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*
      |--------------------------------------------------------------------------
      | Background Styling
      |--------------------------------------------------------------------------
      */
      backgroundColor: const Color(0xFFF8FAFC),

      /*
      |--------------------------------------------------------------------------
      | App Bar
      |--------------------------------------------------------------------------
      */
      appBar: AppBar(
        title: const Text('Kitchen Display'),

        actions: [
          /*
          |--------------------------------------------------------------------------
          | Manual Refresh Button
          |--------------------------------------------------------------------------
          | Reloads latest kitchen orders.
          */
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
      | Main Kitchen Body
      |--------------------------------------------------------------------------
      */
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : orders.isEmpty
              ? const Center(
                  child: Text(
                    'No kitchen orders',
                    style: TextStyle(fontSize: 22),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,

                  /*
                  |--------------------------------------------------------------------------
                  | Kitchen Grid Layout
                  |--------------------------------------------------------------------------
                  | Each card represents one restaurant order.
                  */
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),

                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final items = order['items'] as List<dynamic>;

                    /*
                    |--------------------------------------------------------------------------
                    | Kitchen Status Checks
                    |--------------------------------------------------------------------------
                    | Used to dynamically enable/disable action buttons.
                    */
                    final allPreparing = items.every(
                      (item) => item['kitchen_status'] == 'preparing',
                    );

                    final allReady = items.every(
                      (item) => item['kitchen_status'] == 'ready',
                    );

                    final allServed = items.every(
                      (item) => item['kitchen_status'] == 'served',
                    );

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
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),

                              decoration: BoxDecoration(
                               color: kitchenStatusColor(
                                  items.isNotEmpty
                                      ? items.first['kitchen_status']
                                      : 'pending',
                                ),

                                borderRadius: BorderRadius.circular(12),
                              ),

                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                children: [
                                  Text(
                                    tableName(order),

                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    '${order['order_number']} • ${orderAge(order)}',

                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Divider(height: 24),

                            /*
                            |--------------------------------------------------------------------------
                            | Kitchen Item List
                            |--------------------------------------------------------------------------
                            | Displays all products inside the order.
                            */
                            Expanded(
                              child: ListView.builder(
                                itemCount: items.length,
                                itemBuilder: (context, itemIndex) {
                                  final item = items[itemIndex];

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),

                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

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
                                                .replaceAll('.000', ''),
                                          ),
                                        ),

                                        const SizedBox(width: 10),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,

                                            children: [
                                              /*
                                              |--------------------------------------------------------------------------
                                              | Product Name
                                              |--------------------------------------------------------------------------
                                              */
                                              Text(
                                                item['product_name'],
                                                style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                              ),

                                              /*
                                              |--------------------------------------------------------------------------
                                              | Kitchen Status Display
                                              |--------------------------------------------------------------------------
                                              */
                                              Text(
                                                'Status: ${item['kitchen_status']}',
                                                style: const TextStyle(
                                                  color: Colors.blueGrey,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),

                                              /*
                                              |--------------------------------------------------------------------------
                                              | Optional Kitchen Notes
                                              |--------------------------------------------------------------------------
                                              */
                                              if (item['notes'] != null)
                                                Text(
                                                  item['notes'],
                                                  style: const TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 8),

                            /*
                            |--------------------------------------------------------------------------
                            | Kitchen Action Buttons
                            |--------------------------------------------------------------------------
                            | Controls full kitchen preparation workflow.
                            */
                            Column(
                              children: [
                                /*
                                |--------------------------------------------------------------------------
                                | Set To Preparing
                                |--------------------------------------------------------------------------
                                */
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        allPreparing || allReady || allServed
                                            ? null
                                            : () async {
                                                for (final item in items) {
                                                  await apiService
                                                      .updateKitchenItemStatus(
                                                    itemId: item['id'],
                                                    kitchenStatus:
                                                        'preparing',
                                                  );
                                                }

                                                await loadOrders();
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
                                            for (final item in items) {
                                              await apiService
                                                  .updateKitchenItemStatus(
                                                itemId: item['id'],
                                                kitchenStatus: 'ready',
                                              );
                                            }

                                            await loadOrders();
                                          },
                                    icon:
                                        const Icon(Icons.check_circle_outline),
                                    label: Text(
                                      allReady || allServed
                                          ? 'Ready'
                                          : 'Mark Ready',
                                    ),
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
                                            for (final item in items) {
                                              await apiService
                                                  .updateKitchenItemStatus(
                                                itemId: item['id'],
                                                kitchenStatus: 'served',
                                              );
                                            }

                                            await loadOrders();
                                          },
                                    icon: const Icon(Icons.done_all),
                                    label: Text(
                                      allServed
                                          ? 'Served'
                                          : 'Mark Served',
                                    ),
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