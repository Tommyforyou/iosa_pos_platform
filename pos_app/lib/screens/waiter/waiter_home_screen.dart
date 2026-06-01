import 'package:flutter/material.dart';
import '../table_screen.dart';
import 'waiter_orders_screen.dart';

/*
|--------------------------------------------------------------------------
| Waiter Home Screen
|--------------------------------------------------------------------------
| Main navigation screen for restaurant waiters.
|
| Functions:
| - Open Restaurant Tables
| - View My Active Orders
| - Future: Logout
|
*/

class WaiterHomeScreen extends StatelessWidget {
  const WaiterHomeScreen({super.key});

  /*
  |--------------------------------------------------------------------------
  | Navigation Helper
  |--------------------------------------------------------------------------
  */

  void openScreen(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Waiter Terminal')),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,

          children: [
            /*
            |--------------------------------------------------------------------------
            | Restaurant Tables
            |--------------------------------------------------------------------------
            */
            _WaiterCard(
              title: 'Tables',
              subtitle: 'Take customer orders',
              icon: Icons.table_restaurant,
              onTap: () => openScreen(context, const TableScreen()),
            ),

            /*
            |--------------------------------------------------------------------------
            | My Orders
            |--------------------------------------------------------------------------
            */
            _WaiterCard(
              title: 'My Orders',
              subtitle: 'Track active orders',
              icon: Icons.receipt_long,
              onTap: () => openScreen(context, const WaiterOrdersScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

/*
|--------------------------------------------------------------------------
| Waiter Card Widget
|--------------------------------------------------------------------------
*/

class _WaiterCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _WaiterCard({required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(12),

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Icon(icon, size: 60),

              const SizedBox(height: 12),

              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

              const SizedBox(height: 8),

              Text(subtitle, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
