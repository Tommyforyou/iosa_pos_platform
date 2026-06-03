import 'package:flutter/material.dart';
import '../services/api_service.dart';

/*
|--------------------------------------------------------------------------
| Dashboard Screen
|--------------------------------------------------------------------------
| Operational restaurant POS dashboard.
|
| Current dashboard metrics:
| - today's sales
| - completed orders
| - active orders
| - occupied tables
| - cash/card payment counts
|
| Future dashboard metrics:
| - top selling products
| - hourly revenue
| - VAT summary
| - staff performance
| - kitchen queue
*/

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  /*
  |--------------------------------------------------------------------------
  | API Service
  |--------------------------------------------------------------------------
  */

  final ApiService apiService = ApiService();

  /*
  |--------------------------------------------------------------------------
  | Dashboard State
  |--------------------------------------------------------------------------
  */

  Map<String, dynamic> stats = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    loadDashboard();
  }

  /*
  |--------------------------------------------------------------------------
  | Load Dashboard Statistics
  |--------------------------------------------------------------------------
  */

  Future<void> loadDashboard() async {
    try {
      final response = await apiService.getDashboardStatistics();

      setState(() {
        stats = response;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        title: const Text('POS Dashboard'),

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
          : GridView.count(
              padding: const EdgeInsets.all(20),

              crossAxisCount: 3,

              crossAxisSpacing: 18,
              mainAxisSpacing: 18,

              childAspectRatio: 1.4,

              children: [
                _DashboardCard(title: 'Today Sales', value: 'Rs ${(stats['today_sales'] ?? 0).toString()}', icon: Icons.attach_money),

                _DashboardCard(title: 'Completed Orders', value: '${stats['completed_orders'] ?? 0}', icon: Icons.receipt_long),

                _DashboardCard(title: 'Active Orders', value: '${stats['active_orders'] ?? 0}', icon: Icons.restaurant),

                _DashboardCard(title: 'Occupied Tables', value: '${stats['occupied_tables'] ?? 0}', icon: Icons.table_restaurant),

                _DashboardCard(title: 'Cash Payments', value: '${stats['cash_payments'] ?? 0}', icon: Icons.payments),

                _DashboardCard(title: 'Card Payments', value: '${stats['card_payments'] ?? 0}', icon: Icons.credit_card),
              ],
            ),
    );
  }
}

/*
|--------------------------------------------------------------------------
| Dashboard Card Widget
|--------------------------------------------------------------------------
| Reusable statistics card.
*/

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _DashboardCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,

      child: Padding(
        padding: const EdgeInsets.all(22),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(icon, size: 48, color: Colors.blueGrey),

            const SizedBox(height: 16),

            Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),

            const SizedBox(height: 8),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
