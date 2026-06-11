import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

/*
|--------------------------------------------------------------------------
| Kitchen Performance Dashboard Screen
|--------------------------------------------------------------------------
| This screen displays live kitchen performance metrics.
|
| It is intended for managers and supervisors to monitor:
| - Orders received today
| - Pending kitchen items
| - Items currently being prepared
| - Ready items
| - Longest waiting order
| - Delayed orders
|--------------------------------------------------------------------------
*/

class KitchenPerformanceDashboardScreen extends StatefulWidget {
  const KitchenPerformanceDashboardScreen({super.key});

  @override
  State<KitchenPerformanceDashboardScreen> createState() =>
      _KitchenPerformanceDashboardScreenState();
}

class _KitchenPerformanceDashboardScreenState
    extends State<KitchenPerformanceDashboardScreen> {
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

  bool isLoading = true;
  Map<String, dynamic> dashboard = {};
  Timer? refreshTimer;

  /*
  |--------------------------------------------------------------------------
  | Init State
  |--------------------------------------------------------------------------
  */

  @override
  void initState() {
    super.initState();

    loadDashboard();

    refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => loadDashboard(),
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
  | Load Dashboard Data
  |--------------------------------------------------------------------------
  */

  Future<void> loadDashboard() async {
    try {
      final data = await apiService.getKitchenPerformanceDashboard();

      if (!mounted) return;

      setState(() {
        dashboard = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  /*
  |--------------------------------------------------------------------------
  | KPI Card
  |--------------------------------------------------------------------------
  */

  Widget kpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Longest Waiting Order Card
  |--------------------------------------------------------------------------
  */

  Widget longestWaitingOrderCard() {
    final order = dashboard['longest_waiting_order'];

    final orderNumber = order == null
        ? '-'
        : (order['daily_order_number'] ?? order['order_number'] ?? order['id'])
              .toString();

    final waitingMinutes = (dashboard['longest_waiting_minutes'] ?? 0)
        .toString();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.red.withOpacity(0.12),
              child: const Icon(Icons.timer, color: Colors.red, size: 34),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Longest Waiting Order',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    order == null
                        ? 'No active waiting order'
                        : 'Order $orderNumber • $waitingMinutes minutes',
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        title: const Text('Kitchen Performance Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isLoading = true;
              });

              loadDashboard();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  /*
                  |--------------------------------------------------------------------------
                  | KPI Grid
                  |--------------------------------------------------------------------------
                  */
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.75,
                      children: [
                        kpiCard(
                          title: 'Orders Today',
                          value: (dashboard['orders_today'] ?? 0).toString(),
                          icon: Icons.receipt_long,
                          color: Colors.blue,
                        ),
                        kpiCard(
                          title: 'Pending Items',
                          value: (dashboard['pending_items'] ?? 0).toString(),
                          icon: Icons.hourglass_empty,
                          color: Colors.orange,
                        ),
                        kpiCard(
                          title: 'Currently Preparing',
                          value: (dashboard['currently_preparing'] ?? 0)
                              .toString(),
                          icon: Icons.restaurant,
                          color: Colors.deepPurple,
                        ),
                        kpiCard(
                          title: 'Ready Items',
                          value: (dashboard['ready_items'] ?? 0).toString(),
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                        kpiCard(
                          title: 'Longest Waiting',
                          value:
                              '${dashboard['longest_waiting_minutes'] ?? 0} min',
                          icon: Icons.access_time,
                          color: Colors.red,
                        ),
                        kpiCard(
                          title: 'Delayed Orders',
                          value: (dashboard['delayed_orders'] ?? 0).toString(),
                          icon: Icons.warning,
                          color: Colors.redAccent,
                        ),
                      ],
                    ),
                  ),

                  /*
                  |--------------------------------------------------------------------------
                  | Longest Waiting Order Details
                  |--------------------------------------------------------------------------
                  */
                  longestWaitingOrderCard(),
                ],
              ),
            ),
    );
  }
}
