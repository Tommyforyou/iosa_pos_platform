import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';

class VatDashboardScreen extends StatefulWidget {
  const VatDashboardScreen({super.key});

  @override
  State<VatDashboardScreen> createState() => _VatDashboardScreenState();
}

class _VatDashboardScreenState extends State<VatDashboardScreen> {
  final ApiService apiService = ApiService();
  final money = NumberFormat('#,##0.00');
  String selectedPeriod = 'monthly';

  bool isLoading = false;
  Map<String, dynamic>? report;

  DateTime fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime toDate = DateTime.now();

  String formatDate(DateTime date) {
    return date.toIso8601String().split('T').first;
  }

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  Future<void> pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? fromDate : toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      if (isFrom) {
        fromDate = picked;
      } else {
        toDate = picked;
      }
    });

    await loadReport();
  }

  Future<void> loadReport() async {
    try {
      setState(() {
        isLoading = true;
      });

      final result = await apiService.getVatSummary(from: formatDate(fromDate), to: formatDate(toDate));

      if (!mounted) return;

      setState(() {
        report = result;
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
    return double.tryParse(report?[key]?.toString() ?? '0') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final netVat = value('net_vat_payable');
    final salesTransactions = report?['sales_transactions'] ?? [];
    final purchaseTransactions = report?['purchase_transactions'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('VAT Dashboard'),
        actions: [IconButton(onPressed: loadReport, icon: const Icon(Icons.refresh))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              title: 'VAT Period',
              child: Row(
                children: [
                  DropdownButton<String>(
                    value: selectedPeriod,
                    items: const [
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                      DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
                      DropdownMenuItem(value: 'custom', child: Text('Custom')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedPeriod = value ?? 'monthly';

                        final now = DateTime.now();

                        if (selectedPeriod == 'monthly') {
                          fromDate = DateTime(now.year, now.month, 1);
                          toDate = now;
                        }

                        if (selectedPeriod == 'quarterly') {
                          final quarterStartMonth = (((now.month - 1) ~/ 3) * 3) + 1;
                          fromDate = DateTime(now.year, quarterStartMonth, 1);
                          toDate = now;
                        }
                      });

                      loadReport();
                    },
                  ),

                  const SizedBox(width: 24),

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
              Row(
                children: [
                  _KpiCard(
                    title: 'Sales Excl VAT',
                    value: 'Rs ${money.format(value('sales_excl_vat'))}',
                    icon: Icons.point_of_sale,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 14),
                  _KpiCard(
                    title: 'VAT Collected',
                    value: 'Rs ${money.format(value('vat_collected'))}',
                    icon: Icons.receipt_long,
                    color: Colors.green,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  _KpiCard(
                    title: 'Purchases Excl VAT',
                    value: 'Rs ${money.format(value('purchases_excl_vat'))}',
                    icon: Icons.shopping_cart_checkout,
                    color: Colors.indigo,
                  ),
                  const SizedBox(width: 14),
                  _KpiCard(title: 'VAT Paid', value: 'Rs ${money.format(value('vat_paid'))}', icon: Icons.percent, color: Colors.orange),
                ],
              ),

              const SizedBox(height: 22),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: netVat >= 0 ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: netVat >= 0 ? Colors.red.shade200 : Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(netVat >= 0 ? Icons.warning_amber : Icons.verified, color: netVat >= 0 ? Colors.red : Colors.green, size: 42),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            netVat >= 0 ? 'Net VAT Payable' : 'VAT Credit / Refund Position',
                            style: TextStyle(color: netVat >= 0 ? Colors.red : Colors.green, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text('Rs ${money.format(netVat.abs())}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              _TransactionTable(title: 'Sales Transactions', rows: report?['sales_transactions'] ?? [], partyLabel: 'Customer'),
              _TransactionTable(title: 'Purchase Transactions', rows: report?['purchase_transactions'] ?? [], partyLabel: 'Supplier'),

              const SizedBox(height: 22),

              _SectionCard(
                title: 'VAT Formula',
                child: const Text('Net VAT Payable = VAT Collected on Sales - VAT Paid on Purchases', style: TextStyle(fontSize: 16)),
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
| Transaction Table
|--------------------------------------------------------------------------
*/

class _TransactionTable extends StatelessWidget {
  final String title;
  final List rows;
  final String partyLabel;

  const _TransactionTable({required this.title, required this.rows, required this.partyLabel});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,##0.00');

    return Container(
      margin: const EdgeInsets.only(top: 22),
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

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,

            child: DataTable(
              columns: [
                const DataColumn(label: Text('Date')),

                const DataColumn(label: Text('Invoice')),

                DataColumn(label: Text(partyLabel)),

                const DataColumn(numeric: true, label: Text('Excl VAT')),

                const DataColumn(numeric: true, label: Text('VAT')),

                const DataColumn(numeric: true, label: Text('Total')),
              ],

              rows: rows.map<DataRow>((row) {
                final subtotal = double.tryParse(row['subtotal'].toString()) ?? 0;

                final vat = double.tryParse(row['vat_amount'].toString()) ?? 0;

                final total = double.tryParse(row['total_amount'].toString()) ?? 0;

                return DataRow(
                  cells: [
                    DataCell(Text(row['date']?.toString().substring(0, 10) ?? '-')),

                    DataCell(Text(row['invoice_number'] ?? '-')),

                    DataCell(Text(row['customer'] ?? row['supplier'] ?? '-')),

                    DataCell(Align(alignment: Alignment.centerRight, child: Text(money.format(subtotal)))),

                    DataCell(Align(alignment: Alignment.centerRight, child: Text(money.format(vat)))),

                    DataCell(
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(money.format(total), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
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
