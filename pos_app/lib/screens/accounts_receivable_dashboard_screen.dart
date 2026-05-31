import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';

class AccountsReceivableDashboardScreen extends StatefulWidget {
  const AccountsReceivableDashboardScreen({super.key});

  @override
  State<AccountsReceivableDashboardScreen> createState() => _AccountsReceivableDashboardScreenState();
}

class _AccountsReceivableDashboardScreenState extends State<AccountsReceivableDashboardScreen> {
  final ApiService apiService = ApiService();

  bool isLoading = true;
  Map<String, dynamic>? dashboard;

  final money = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      final result = await apiService.getAccountsReceivableDashboard();

      if (!mounted) return;

      setState(() {
        dashboard = result;
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

  double value(String key) {
    return double.tryParse(dashboard?[key]?.toString() ?? '0') ?? 0;
  }

  double agingValue(String key) {
    return double.tryParse(dashboard?['aging']?[key]?.toString() ?? '0') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final topCustomers = dashboard?['top_customers'] ?? [];
    final recentPayments = dashboard?['recent_payments'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Accounts Receivable Dashboard'),
        actions: [IconButton(onPressed: loadDashboard, icon: const Icon(Icons.refresh))],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _KpiCard(title: 'Customers', value: dashboard?['total_customers'].toString() ?? '0', icon: Icons.business, color: Colors.blue),
                      const SizedBox(width: 14),
                      _KpiCard(title: 'Sales', value: 'Rs ${money.format(value('total_sales'))}', icon: Icons.shopping_cart, color: Colors.indigo),
                      const SizedBox(width: 14),
                      _KpiCard(title: 'Received', value: 'Rs ${money.format(value('total_received'))}', icon: Icons.payments, color: Colors.green),
                      const SizedBox(width: 14),
                      _KpiCard(
                        title: 'Outstanding',
                        value: 'Rs ${money.format(value('outstanding_receivables'))}',
                        icon: Icons.warning_amber,
                        color: Colors.red,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _SectionCard(
                    title: 'Receivable Aging',
                    child: Row(
                      children: [
                        _AgingCard(title: 'Current', amount: agingValue('current'), color: Colors.green),
                        const SizedBox(width: 12),
                        _AgingCard(title: '31-60 Days', amount: agingValue('days_31_60'), color: Colors.amber),
                        const SizedBox(width: 12),
                        _AgingCard(title: '61-90 Days', amount: agingValue('days_61_90'), color: Colors.orange),
                        const SizedBox(width: 12),
                        _AgingCard(title: '90+ Days', amount: agingValue('days_90_plus'), color: Colors.red),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _SectionCard(
                          title: 'Top Customers Owing',
                          child: topCustomers.isEmpty
                              ? const Text('No outstanding Customers')
                              : Column(
                                  children: topCustomers.map<Widget>((customer) {
                                    final amount = double.tryParse(customer['outstanding_balance']?.toString() ?? '0') ?? 0;

                                    return ListTile(
                                      leading: const Icon(Icons.business),
                                      title: Text(customer['name'] ?? '-'),
                                      trailing: Text(
                                        'Rs ${money.format(amount)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _SectionCard(
                          title: 'Recent Customer Payments',
                          child: recentPayments.isEmpty
                              ? const Text('No recent payments')
                              : Column(
                                  children: recentPayments.map<Widget>((payment) {
                                    final amount = double.tryParse(payment['amount']?.toString() ?? '0') ?? 0;

                                    return ListTile(
                                      leading: const Icon(Icons.payments, color: Colors.green),
                                      title: Text(payment['reference'] ?? 'SPAY-${payment['id']}'),
                                      subtitle: Text(payment['customer']?['name'] ?? '-'),
                                      trailing: Text(
                                        'Rs ${money.format(amount)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(title, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgingCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _AgingCard({required this.title, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,##0.00');

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Rs ${money.format(amount)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
