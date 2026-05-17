import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/money.dart';

/*
|--------------------------------------------------------------------------
| Daily Sales Report Screen
|--------------------------------------------------------------------------
| Displays today's POS sales report.
|
| Current report includes:
| - total sales
| - completed orders
| - cash sales
| - card sales
| - dine-in / takeaway / delivery counts
| - paid order listing
|
| Future improvements:
| - date filter
| - PDF export
| - Excel export
| - VAT summary
| - cashier shift closing
*/

class DailySalesReportScreen extends StatefulWidget {
  const DailySalesReportScreen({super.key});

  @override
  State<DailySalesReportScreen> createState() =>
      _DailySalesReportScreenState();
}

class _DailySalesReportScreenState extends State<DailySalesReportScreen> {
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

  Map<String, dynamic>? report;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  /*
  |--------------------------------------------------------------------------
  | Load Daily Report
  |--------------------------------------------------------------------------
  */

  Future<void> loadReport() async {
    try {
      final data = await apiService.getDailySalesReport();

      setState(() {
        report = data;
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
  | Order Label Helper
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

  @override
  Widget build(BuildContext context) {
    final summary = report?['summary'] ?? {};
    final orders = report?['orders'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        title: const Text('Daily Sales Report'),

        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isLoading = true;
              });

              loadReport();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : report == null
              ? const Center(
                  child: Text('Unable to load report'),
                )
              : Column(
                  children: [
                    /*
                    |--------------------------------------------------------------------------
                    | Summary Cards
                    |--------------------------------------------------------------------------
                    */

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 4,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.5,
                        children: [
                          _ReportCard(
                            title: 'Total Sales',
                            value: formatMoney(summary['total_sales']),
                            icon: Icons.attach_money,
                          ),
                          _ReportCard(
                            title: 'Completed Orders',
                            value:
                                '${summary['completed_orders'] ?? 0}',
                            icon: Icons.receipt_long,
                          ),
                          _ReportCard(
                            title: 'Cash Sales',
                            value: formatMoney(summary['cash_sales']),
                            icon: Icons.payments,
                          ),
                          _ReportCard(
                            title: 'Card Sales',
                            value: formatMoney(summary['card_sales']),
                            icon: Icons.credit_card,
                          ),
                          _ReportCard(
                            title: 'Dine-In',
                            value:
                                '${summary['dine_in_orders'] ?? 0}',
                            icon: Icons.table_restaurant,
                          ),
                          _ReportCard(
                            title: 'Takeaway',
                            value:
                                '${summary['takeaway_orders'] ?? 0}',
                            icon: Icons.shopping_bag,
                          ),
                          _ReportCard(
                            title: 'Delivery',
                            value:
                                '${summary['delivery_orders'] ?? 0}',
                            icon: Icons.delivery_dining,
                          ),
                          _ReportCard(
                            title: 'Report Date',
                            value:
                                '${summary['date'] ?? '-'}',
                            icon: Icons.calendar_today,
                          ),
                        ],
                      ),
                    ),

                    /*
                    |--------------------------------------------------------------------------
                    | Order Listing Header
                    |--------------------------------------------------------------------------
                    */

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Paid Orders',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    /*
                    |--------------------------------------------------------------------------
                    | Paid Order Listing
                    |--------------------------------------------------------------------------
                    */

                    Expanded(
                      child: orders.isEmpty
                          ? const Center(
                              child: Text('No paid orders today'),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: orders.length,
                              itemBuilder: (context, index) {
                                final order = orders[index];

                                return Card(
                                  margin:
                                      const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      child: Icon(Icons.receipt),
                                    ),
                                    title: Text(
                                      orderLabel(order),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${order['order_number']} • ${order['payment_method']}',
                                    ),
                                    trailing: Text(
                                      formatMoney(order['total_amount']),
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}

/*
|--------------------------------------------------------------------------
| Report Card Widget
|--------------------------------------------------------------------------
*/

class _ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ReportCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(
              icon,
              size: 36,
              color: Colors.blueGrey,
            ),

            const SizedBox(height: 10),

            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}