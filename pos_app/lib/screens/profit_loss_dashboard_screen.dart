import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';

class ProfitLossDashboardScreen extends StatefulWidget {
  const ProfitLossDashboardScreen({super.key});

  @override
  State<ProfitLossDashboardScreen> createState() => _ProfitLossDashboardScreenState();
}

class _ProfitLossDashboardScreenState extends State<ProfitLossDashboardScreen> {
  /*
  |--------------------------------------------------------------------------
  | Services
  |--------------------------------------------------------------------------
  */

  final ApiService apiService = ApiService();

  /*
  |--------------------------------------------------------------------------
  | Formatters
  |--------------------------------------------------------------------------
  */

  final money = NumberFormat('#,##0.00');

  /*
  |--------------------------------------------------------------------------
  | State
  |--------------------------------------------------------------------------
  */

  bool isLoading = false;

  Map<String, dynamic>? report;

  DateTime fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);

  DateTime toDate = DateTime.now();

  /*
  |--------------------------------------------------------------------------
  | Format Date
  |--------------------------------------------------------------------------
  */

  String formatDate(DateTime date) {
    return date.toIso8601String().split('T').first;
  }

  /*
  |--------------------------------------------------------------------------
  | Init
  |--------------------------------------------------------------------------
  */

  @override
  void initState() {
    super.initState();

    loadReport();
  }

  /*
  |--------------------------------------------------------------------------
  | Pick Date
  |--------------------------------------------------------------------------
  */

  Future<void> pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? fromDate : toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      if (isFrom) {
        fromDate = picked;
      } else {
        toDate = picked;
      }
    });

    await loadReport();
  }

  /*
  |--------------------------------------------------------------------------
  | Load Report
  |--------------------------------------------------------------------------
  */

  Future<void> loadReport() async {
    try {
      setState(() {
        isLoading = true;
      });

      final result = await apiService.getProfitLoss(from: formatDate(fromDate), to: formatDate(toDate));

      if (!mounted) {
        return;
      }

      setState(() {
        report = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Value Helper
  |--------------------------------------------------------------------------
  */

  double value(String key) {
    return double.tryParse(report?[key]?.toString() ?? '0') ?? 0;
  }

  /*
  |--------------------------------------------------------------------------
  | Build
  |--------------------------------------------------------------------------
  */

  @override
  Widget build(BuildContext context) {
    final salesExclVat = value('sales_excl_vat');
    final purchasesExclVat = value('purchases_excl_vat');
    final grossProfit = value('gross_profit');

    final profitMargin = salesExclVat > 0 ? (grossProfit / salesExclVat) * 100 : 0;

    final isProfit = grossProfit >= 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Profit & Loss Dashboard'),
        actions: [IconButton(onPressed: loadReport, icon: const Icon(Icons.refresh))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /*
            |--------------------------------------------------------------------------
            | Period Filter
            |--------------------------------------------------------------------------
            */
            _SectionCard(
              title: 'Reporting Period',
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => pickDate(isFrom: true),
                    icon: const Icon(Icons.date_range),
                    label: Text('From: ${formatDate(fromDate)}'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => pickDate(isFrom: false),
                    icon: const Icon(Icons.date_range),
                    label: Text('To: ${formatDate(toDate)}'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(onPressed: loadReport, icon: const Icon(Icons.calculate), label: const Text('Calculate')),
                ],
              ),
            ),

            const SizedBox(height: 22),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              /*
              |--------------------------------------------------------------------------
              | KPI Cards
              |--------------------------------------------------------------------------
              */
              Row(
                children: [
                  _KpiCard(title: 'Sales Excl VAT', value: 'Rs ${money.format(salesExclVat)}', icon: Icons.point_of_sale, color: Colors.blue),
                  const SizedBox(width: 14),
                  _KpiCard(
                    title: 'Purchases Excl VAT',
                    value: 'Rs ${money.format(purchasesExclVat)}',
                    icon: Icons.shopping_cart_checkout,
                    color: Colors.indigo,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  _KpiCard(
                    title: 'Gross Profit',
                    value: 'Rs ${money.format(grossProfit)}',
                    icon: Icons.trending_up,
                    color: isProfit ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 14),
                  _KpiCard(
                    title: 'Profit Margin',
                    value: '${money.format(profitMargin)}%',
                    icon: Icons.percent,
                    color: profitMargin >= 0 ? Colors.orange : Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 22),

              /*
              |--------------------------------------------------------------------------
              | Profit Highlight
              |--------------------------------------------------------------------------
              */
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: isProfit ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: isProfit ? Colors.green.shade200 : Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(isProfit ? Icons.verified : Icons.warning_amber, color: isProfit ? Colors.green : Colors.red, size: 42),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isProfit ? 'Gross Profit Position' : 'Gross Loss Position',
                            style: TextStyle(color: isProfit ? Colors.green : Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text('Rs ${money.format(grossProfit.abs())}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              /*
              |--------------------------------------------------------------------------
              | Report Breakdown
              |--------------------------------------------------------------------------
              */
              _SectionCard(
                title: 'Profit & Loss Breakdown',
                child: Column(
                  children: [
                    _BreakdownRow(label: 'Sales Excluding VAT', value: salesExclVat, positive: true),
                    const Divider(),
                    _BreakdownRow(label: 'Less: Purchases Excluding VAT', value: purchasesExclVat, positive: false),
                    const Divider(thickness: 1.2),
                    _BreakdownRow(label: 'Gross Profit', value: grossProfit, positive: isProfit, bold: true),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              /*
              |--------------------------------------------------------------------------
              | VAT Note
              |--------------------------------------------------------------------------
              */
              _SectionCard(
                title: 'Accounting Note',
                child: Text(
                  report?['vat_note'] ?? 'VAT is excluded from Profit & Loss calculation.',
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/*
|--------------------------------------------------------------------------
| KPI Card
|--------------------------------------------------------------------------
*/

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
        padding: const EdgeInsets.all(22),
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
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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

/*
|--------------------------------------------------------------------------
| Section Card
|--------------------------------------------------------------------------
*/

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

/*
|--------------------------------------------------------------------------
| Breakdown Row
|--------------------------------------------------------------------------
*/

class _BreakdownRow extends StatelessWidget {
  final String label;
  final double value;
  final bool positive;
  final bool bold;

  const _BreakdownRow({required this.label, required this.value, required this.positive, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,##0.00');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 17 : 15),
            ),
          ),
          Text(
            'Rs ${money.format(value)}',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: positive ? Colors.green : Colors.red,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontSize: bold ? 17 : 15,
            ),
          ),
        ],
      ),
    );
  }
}
