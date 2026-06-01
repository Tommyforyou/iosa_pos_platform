import 'package:flutter/material.dart';
import '../../services/api_service.dart';

/*
|--------------------------------------------------------------------------
| Waiter Orders Screen
|--------------------------------------------------------------------------
| Displays active restaurant orders for waiter monitoring.
*/

class WaiterOrdersScreen extends StatefulWidget {
  const WaiterOrdersScreen({super.key});

  @override
  State<WaiterOrdersScreen> createState() => _WaiterOrdersScreenState();
}

class _WaiterOrdersScreenState extends State<WaiterOrdersScreen> {
  final ApiService apiService = ApiService();

  bool isLoading = true;
  List<dynamic> orders = [];

  /*
  |--------------------------------------------------------------------------
  | Initial Load
  |--------------------------------------------------------------------------
  */

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  /*
  |--------------------------------------------------------------------------
  | Load Waiter Orders
  |--------------------------------------------------------------------------
  */

  Future<void> loadOrders() async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await apiService.getWaiterOrders();

      setState(() {
        orders = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Status Badge Color
  |--------------------------------------------------------------------------
  */

  Color statusColor(String? status) {
    switch (status) {
      case 'ready':
        return Colors.green;
      case 'preparing':
        return Colors.orange;
      case 'open':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
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
        title: const Text('My Active Orders'),
        actions: [IconButton(onPressed: loadOrders, icon: const Icon(Icons.refresh))],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? const Center(child: Text('No active orders found'))
          : RefreshIndicator(
              onRefresh: loadOrders,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final table = order['table'];
                  final items = order['items'] ?? [];

                  //debugPrint(order.toString());

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /*
                              |--------------------------------------------------------------------------
                              | Order Header
                              |--------------------------------------------------------------------------
                              */
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(order['table']?['table_name'] ?? 'No Table', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: statusColor(order['status']), borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                  '${order['status'] ?? 'unknown'}'.toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          /*
                              |--------------------------------------------------------------------------
                              | Order Items
                              |--------------------------------------------------------------------------
                              */
                          ...items.map<Widget>((item) {
                            final product = item['product'];

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Text('${item['quantity']} x ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Expanded(child: Text(product != null ? product['name'] ?? '' : 'Unknown item')),
                                ],
                              ),
                            );
                          }).toList(),

                          const SizedBox(height: 10),

                          /*
                          |--------------------------------------------------------------------------
                          | Bill Request Action
                          |--------------------------------------------------------------------------
                          */
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: order['bill_requested_at'] != null
                                  ? null
                                  : () async {
                                      try {
                                        await apiService.requestBill(orderId: order['id']);

                                        if (!mounted) return;

                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill requested successfully')));

                                        loadOrders();
                                      } catch (e) {
                                        if (!mounted) return;

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                                      }
                                    },
                              icon: Icon(order['bill_requested_at'] != null ? Icons.check_circle : Icons.receipt_long, size: 18),
                              label: Text(order['bill_requested_at'] != null ? 'Bill Requested' : 'Request Bill'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
