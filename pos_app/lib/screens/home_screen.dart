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
import 'purchase_receipt_screen.dart';
import 'purchase_screen.dart';
import 'supplier_screen.dart';
import 'z_report_screen.dart';
import 'stock_movement_screen.dart';
import 'quick_sale_screen.dart';
import 'quick_sale_history_screen.dart';
import 'business_settings_screen.dart';
import 'customer_management_screen.dart';
import 'accounts_payable_dashboard_screen.dart';
import 'vat_dashboard_screen.dart';

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
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(title: const Text('IOSA POS Platform')),

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
              onTap: () => openScreen(context, const TableScreen()),
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
              onTap: () => openScreen(context, const KitchenScreen()),
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
              onTap: () => openScreen(context, const OrderScreen(orderType: 'takeaway')),
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
              onTap: () => openScreen(context, const OrderScreen(orderType: 'delivery')),
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
              onTap: () => openScreen(context, const BillingScreen()),
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
              onTap: () => openScreen(context, const DashboardScreen()),
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
              onTap: () => openScreen(context, const DailySalesReportScreen()),
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
              onTap: () => openScreen(context, const CounterPosScreen()),
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
              onTap: () => openScreen(context, const SalesHistoryScreen()),
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
              onTap: () => openScreen(context, const CategoryManagementScreen()),
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
              onTap: () => openScreen(context, const ProductManagementScreen()),
            ),

            /*
            |--------------------------------------------------------------------------
            | Z report
            |--------------------------------------------------------------------------
            | Show Daily Sales
            */
            _HomeCard(
              title: 'Z-Report',
              subtitle: 'Daily sales closing and cash reconciliation',
              icon: Icons.summarize,
              onTap: () => openScreen(context, const ZReportScreen()),
            ),

            /*
            |--------------------------------------------------------------------------
            | Show Stock Movement
            |--------------------------------------------------------------------------
            | 
            */
            _HomeCard(
              title: 'Stock Movements',
              subtitle: 'Audit inventory in/out history',
              icon: Icons.timeline,
              onTap: () => openScreen(context, const StockMovementScreen()),
            ),

            /*
            |--------------------------------------------------------------------------
            | Show Stock Movement
            |--------------------------------------------------------------------------
            */
            _HomeCard(
              title: 'Business Settings',
              subtitle: 'Company, VAT and MRA setup',
              icon: Icons.settings,
              onTap: () => openScreen(context, const BusinessSettingsScreen()),
            ),
            /*
            |--------------------------------------------------------------------------
            | Purchasing Group
            |--------------------------------------------------------------------------
            */
            Container(
              margin: const EdgeInsets.only(bottom: 20),

              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(28),

                border: Border.all(color: Colors.grey.shade200),

                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  /*
                  |--------------------------------------------------------------------------
                  | Section Header
                  |--------------------------------------------------------------------------
                  */
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,

                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),

                        child: const Icon(Icons.shopping_cart_checkout, color: Colors.orange, size: 28),
                      ),

                      const SizedBox(width: 14),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text('Purchasing', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

                            SizedBox(height: 3),

                            Text('Supplier management, OCR receipts and purchase tracking.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  /*
                  |--------------------------------------------------------------------------
                  | Nested Cards
                  |--------------------------------------------------------------------------
                  */
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 140,
                        child: _MiniHomeCard(
                          title: 'Purchase OCR',
                          subtitle: 'Scan receipts',
                          icon: Icons.document_scanner,
                          onTap: () => openScreen(context, const PurchaseReceiptScreen()),
                        ),
                      ),

                      SizedBox(
                        width: 200,
                        height: 140,
                        child: _MiniHomeCard(
                          title: 'Purchases',
                          subtitle: 'Purchase list',
                          icon: Icons.shopping_cart_checkout,
                          onTap: () => openScreen(context, const PurchaseScreen()),
                        ),
                      ),

                      SizedBox(
                        width: 200,
                        height: 140,
                        child: _MiniHomeCard(
                          title: 'Suppliers',
                          subtitle: 'Supplier records',
                          icon: Icons.business,
                          onTap: () => openScreen(context, const SupplierScreen()),
                        ),
                      ),

                      SizedBox(
                        width: 200,
                        height: 140,
                        child: _MiniHomeCard(
                          title: 'Payable',
                          subtitle: 'AP dashboard',
                          icon: Icons.account_balance,
                          onTap: () => openScreen(context, const AccountsPayableDashboardScreen()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /*
            |--------------------------------------------------------------------------
            | Sales Group
            |--------------------------------------------------------------------------
            */
            Container(
              margin: const EdgeInsets.only(bottom: 20),

              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(28),

                border: Border.all(color: Colors.grey.shade200),

                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
              ),

              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    /*
                  |--------------------------------------------------------------------------
                  | Section Header
                  |--------------------------------------------------------------------------
                  */
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,

                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),

                          child: const Icon(Icons.shopping_cart_checkout, color: Colors.orange, size: 28),
                        ),

                        const SizedBox(width: 14),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text('Sales', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

                              SizedBox(height: 3),

                              Text('QuickSales, Customers and Sales History.', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    /*
                  |--------------------------------------------------------------------------
                  | Nested Cards
                  |--------------------------------------------------------------------------
                  */
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                      children: [
                        _MiniHomeCard(
                          title: 'Quick Sale',
                          subtitle: 'Create invoice-style sale quickly',
                          icon: Icons.flash_on,
                          onTap: () => openScreen(context, const QuickSaleScreen()),
                        ),

                        _MiniHomeCard(
                          title: 'Sales History',
                          subtitle: 'Quick Sale History',
                          icon: Icons.shopping_cart_checkout,
                          onTap: () => openScreen(context, const QuickSaleHistoryScreen()),
                        ),
                        _MiniHomeCard(
                          title: 'Customers',
                          subtitle: 'Manage customers and repayments',
                          icon: Icons.people,
                          onTap: () => openScreen(context, const CustomerManagementScreen()),
                        ),

                        _MiniHomeCard(
                          title: 'VAT Dashboard',
                          subtitle: 'Vat Collected and Paid',
                          icon: Icons.people,
                          onTap: () => openScreen(context, const VatDashboardScreen()),
                        ),
                      ],
                    ),
                  ],
                ),
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

  const _HomeCard({required this.title, required this.subtitle, required this.icon, required this.onTap});

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
              Icon(icon, size: 52, color: Colors.blueGrey),
              const SizedBox(height: 14),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
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

class _MiniHomeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MiniHomeCard({required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(20),

      child: Container(
        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),

          borderRadius: BorderRadius.circular(20),

          border: Border.all(color: Colors.grey.shade200),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(icon, size: 34, color: Colors.blueGrey),

            const SizedBox(height: 12),

            Text(
              title,
              textAlign: TextAlign.center,

              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Text(
              subtitle,
              textAlign: TextAlign.center,

              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
