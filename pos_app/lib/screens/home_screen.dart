import 'package:flutter/material.dart';
import 'table_screen.dart';
import 'kitchen_screen.dart';
import 'order_screen.dart';
import 'billing_screen.dart';
import 'dashboard_screen.dart';
import 'daily_sales_report_screen.dart';
import 'counter_pos_screen.dart';
import 'category_management_screen.dart';
import 'product_management_screen.dart';
import 'sales_history_screen.dart';

/*
|--------------------------------------------------------------------------
| POS Home Screen
|--------------------------------------------------------------------------
| This screen acts as the main navigation hub of the POS app.
|
| From here, the user can quickly access:
| - Restaurant table ordering
| - Kitchen display
| - Later: takeaway orders
| - Later: delivery orders
|
| This avoids changing main.dart manually every time we want to test
| a different POS module.
*/

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /*
  |--------------------------------------------------------------------------
  | Navigation Helper
  |--------------------------------------------------------------------------
  | Opens the selected screen using Flutter navigation.
  */
  void openScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        title: const Text('IOSA POS Platform'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          childAspectRatio: 1.4,
          children: [
            /*
            |--------------------------------------------------------------------------
            | Restaurant Tables
            |--------------------------------------------------------------------------
            */

            _HomeCard(
              title: 'Tables',
              subtitle: 'Dine-in orders',
              icon: Icons.table_restaurant,
              onTap: () => openScreen(
                context,
                const TableScreen(),
              ),
            ),

            /*
            |--------------------------------------------------------------------------
            | Kitchen Display
            |--------------------------------------------------------------------------
            */

            _HomeCard(
              title: 'Kitchen Display',
              subtitle: 'Pending / preparing / ready',
              icon: Icons.soup_kitchen,
              onTap: () => openScreen(
                context,
                const KitchenScreen(),
              ),
            ),

            /*
            |--------------------------------------------------------------------------
            | Takeaway Orders
            |--------------------------------------------------------------------------
            | We will connect this to OrderScreen in the next step.
            */

            _HomeCard(
              title: 'Takeaway',
              subtitle: 'Coming next',
              icon: Icons.shopping_bag,
              onTap: () => openScreen(
                context,
                const OrderScreen(
                  orderType: 'takeaway',
                ),
              ),
            ),

            /*
            |--------------------------------------------------------------------------
            | Delivery Orders
            |--------------------------------------------------------------------------
            | We will connect this to OrderScreen in the next step.
            */

            _HomeCard(
              title: 'Delivery',
              subtitle: 'Coming next',
              icon: Icons.delivery_dining,
              onTap: () => openScreen(
                context,
                const OrderScreen(
                  orderType: 'delivery',
                ),
              ),
            ),
            /*
            |--------------------------------------------------------------------------
            | Billing / Cashier
            |--------------------------------------------------------------------------
            | Opens active orders that are ready for payment.
            */
            _HomeCard(
              title: 'Billing',
              subtitle: 'Cashier payment screen',
              icon: Icons.point_of_sale,
              onTap: () => openScreen(
                context,
                const BillingScreen(),
              ),
            ),
            /*
            |--------------------------------------------------------------------------
            | Dashboard
            |--------------------------------------------------------------------------
            | Operational POS dashboard and statistics.
            */

            _HomeCard(
              title: 'Dashboard',
              subtitle: 'Sales and operations overview',
              icon: Icons.dashboard,
              onTap: () => openScreen(
                context,
                const DashboardScreen(),
              ),
            ),
            /*
            |--------------------------------------------------------------------------
            | Daily Sales Report
            |--------------------------------------------------------------------------
            | Financial and operational daily POS report.
            */

            _HomeCard(
              title: 'Daily Report',
              subtitle: 'Sales and payment report',
              icon: Icons.bar_chart,
              onTap: () => openScreen(
                context,
                const DailySalesReportScreen(),
              ),
            ),
            /*
            |--------------------------------------------------------------------------
            | Counter Pos
            |--------------------------------------------------------------------------
            | Sales Express
            */
            _HomeCard(
              title: 'Counter POS',
              subtitle: 'Fast order and payment',
              icon: Icons.fastfood,
              onTap: () => openScreen(
                context,
                const CounterPosScreen(),
              ),
            ),
            /*
            |--------------------------------------------------------------------------
            | Show Sales History
            |--------------------------------------------------------------------------
            | Allow to view / reprint Sales receipt
            */
            _HomeCard(
              title: 'Sales History',
              subtitle: 'View sales and reprint receipts',
              icon: Icons.receipt_long,
              onTap: () => openScreen(
                context,
                const SalesHistoryScreen(),
              ),
            ),            
            /*
            |--------------------------------------------------------------------------
            | Manage Categories
            |--------------------------------------------------------------------------
            | edit/delete/update/deactivate categories
            */
            _HomeCard(
              title: 'Categories',
              subtitle: 'Manage product categories',
              icon: Icons.category,
              onTap: () => openScreen(
                context,
                const CategoryManagementScreen(),
              ),
            ),
            /*
            |--------------------------------------------------------------------------
            | CRUD Products
            |--------------------------------------------------------------------------
            | Manage Product and Prices
            */            
            _HomeCard(
              title: 'Products',
              subtitle: 'Manage products and prices',
              icon: Icons.inventory_2,
              onTap: () => openScreen(
                context,
                const ProductManagementScreen(),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

/*
|--------------------------------------------------------------------------
| Reusable Home Card Widget
|--------------------------------------------------------------------------
| This keeps the home screen clean and gives every POS module
| the same premium card style.
*/

class _HomeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 52,
                color: Colors.blueGrey,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}