import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/money.dart';

/*
|--------------------------------------------------------------------------
| Purchase Screen
|--------------------------------------------------------------------------
| Premium purchase management screen.
|
| Shows converted purchase transactions created from OCR-reviewed receipts.
|
| Features:
| - date range filter
| - supplier search
| - VAT highlighting
| - purchase summary cards
| - modern ERP-style listing
*/

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  /*
  |--------------------------------------------------------------------------
  | API Service
  |--------------------------------------------------------------------------
  */

  final ApiService apiService = ApiService();

  /*
  |--------------------------------------------------------------------------
  | State
  |--------------------------------------------------------------------------
  */

  List<dynamic> purchases = [];
  bool isLoading = true;

  /*
  |--------------------------------------------------------------------------
  | Filters
  |--------------------------------------------------------------------------
  */

  DateTime? fromDate;
  DateTime? toDate;

  final TextEditingController supplierController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadPurchases();
  }

  @override
  void dispose() {
    supplierController.dispose();
    super.dispose();
  }

  /*
  |--------------------------------------------------------------------------
  | Date Formatter
  |--------------------------------------------------------------------------
  */

  String formatDateParam(DateTime date) {
    return date.toIso8601String().split('T').first;
  }

  /*
  |--------------------------------------------------------------------------
  | Load Purchases
  |--------------------------------------------------------------------------
  */

  Future<void> loadPurchases() async {
    try {
      setState(() {
        isLoading = true;
      });

      final data = await apiService.getPurchases(
        from: fromDate == null ? null : formatDateParam(fromDate!),
        to: toDate == null ? null : formatDateParam(toDate!),
        supplier: supplierController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        purchases = data;
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
  | Pick Date
  |--------------------------------------------------------------------------
  */

  Future<void> pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());

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

    await loadPurchases();
  }

  /*
  |--------------------------------------------------------------------------
  | Clear Filters
  |--------------------------------------------------------------------------
  */

  Future<void> clearFilters() async {
    setState(() {
      fromDate = null;
      toDate = null;
      supplierController.clear();
    });

    await loadPurchases();
  }

  /*
  |--------------------------------------------------------------------------
  | Totals
  |--------------------------------------------------------------------------
  */

  double totalPurchases() {
    double total = 0;

    for (final purchase in purchases) {
      total += toMoneyDouble(purchase['total_incl_vat']);
    }

    return total;
  }

  double totalVat() {
    double total = 0;

    for (final purchase in purchases) {
      total += toMoneyDouble(purchase['vat_amount']);
    }

    return total;
  }

  double totalExclVat() {
    double total = 0;

    for (final purchase in purchases) {
      total += toMoneyDouble(purchase['subtotal_excl_vat']);
    }

    return total;
  }

  /*
  |--------------------------------------------------------------------------
  | KPI Card
  |--------------------------------------------------------------------------
  */

  Widget kpiCard({required String title, required String value, required IconData icon, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
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
                  const SizedBox(height: 3),
                  Text(title, style: TextStyle(color: Colors.grey.shade700)),
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
  | Filter Panel
  |--------------------------------------------------------------------------
  */

  Widget filterPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          /*
          |--------------------------------------------------------------------------
          | Supplier Search
          |--------------------------------------------------------------------------
          */
          Expanded(
            flex: 2,
            child: TextField(
              controller: supplierController,
              onSubmitted: (_) {
                loadPurchases();
              },
              decoration: InputDecoration(
                labelText: 'Search supplier',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          const SizedBox(width: 12),

          /*
          |--------------------------------------------------------------------------
          | From Date
          |--------------------------------------------------------------------------
          */
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                pickDate(isFrom: true);
              },
              icon: const Icon(Icons.date_range),
              label: Text(fromDate == null ? 'From Date' : formatDateParam(fromDate!)),
            ),
          ),

          const SizedBox(width: 12),

          /*
          |--------------------------------------------------------------------------
          | To Date
          |--------------------------------------------------------------------------
          */
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                pickDate(isFrom: false);
              },
              icon: const Icon(Icons.date_range),
              label: Text(toDate == null ? 'To Date' : formatDateParam(toDate!)),
            ),
          ),

          const SizedBox(width: 12),

          /*
          |--------------------------------------------------------------------------
          | Apply Filter
          |--------------------------------------------------------------------------
          */
          ElevatedButton.icon(onPressed: loadPurchases, icon: const Icon(Icons.filter_alt), label: const Text('Apply')),

          const SizedBox(width: 8),

          /*
          |--------------------------------------------------------------------------
          | Clear Filter
          |--------------------------------------------------------------------------
          */
          IconButton(tooltip: 'Clear filters', onPressed: clearFilters, icon: const Icon(Icons.clear)),
        ],
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Purchase Card
  |--------------------------------------------------------------------------
  */

  Widget purchaseCard(dynamic purchase) {
    final supplier = purchase['supplier'];
    final supplierName = supplier?['name'] ?? 'Unknown Supplier';

    final invoiceNumber = purchase['invoice_number'] ?? '-';
    final invoiceDate = purchase['invoice_date'] ?? '-';

    final total = toMoneyDouble(purchase['total_incl_vat']);
    final vat = toMoneyDouble(purchase['vat_amount']);
    final subtotal = toMoneyDouble(purchase['subtotal_excl_vat']);

    final paymentStatus = purchase['payment_status']?.toString().trim().toLowerCase() ?? 'paid';
    final paidAmount = toMoneyDouble(purchase['paid_amount']);
    final balanceAmount = toMoneyDouble(purchase['balance_amount']);

    Color paymentStatusColor;

    switch (paymentStatus) {
      case 'unpaid':
        paymentStatusColor = Colors.red;
        break;

      case 'partial':
        paymentStatusColor = Colors.orange;
        break;

      case 'paid':
        paymentStatusColor = Colors.green;
        break;

      default:
        paymentStatusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          /*
          |--------------------------------------------------------------------------
          | Icon
          |--------------------------------------------------------------------------
          */
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.12), borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.shopping_cart_checkout, color: Colors.green, size: 28),
          ),

          const SizedBox(width: 14),

          /*
          |--------------------------------------------------------------------------
          | Purchase Info
          |--------------------------------------------------------------------------
          */
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplierName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,

                  children: [
                    _InfoText(label: 'Invoice', value: invoiceNumber, icon: Icons.tag),

                    _InfoText(label: 'Date', value: invoiceDate, icon: Icons.calendar_month),

                    _InfoText(label: 'Status', value: purchase['status'] ?? '-', icon: Icons.verified),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

                      decoration: BoxDecoration(color: paymentStatusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),

                      child: Text(
                        paymentStatus.toUpperCase(),

                        style: TextStyle(color: paymentStatusColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /*
          |--------------------------------------------------------------------------
          | Amounts
          |--------------------------------------------------------------------------
          */
          _AmountBox(label: 'Excl VAT', value: formatMoney(subtotal)),
          const SizedBox(width: 8),
          _AmountBox(label: 'VAT', value: formatMoney(vat), highlight: true),
          const SizedBox(width: 8),
          _AmountBox(label: 'Total', value: formatMoney(total), strong: true),
          const SizedBox(width: 8),
          _AmountBox(label: 'Paid', value: formatMoney(paidAmount), highlight: paymentStatus == 'paid'),
          const SizedBox(width: 8),
          _AmountBox(label: 'Balance', value: formatMoney(balanceAmount), strong: balanceAmount > 0),
        ],
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Build
  |--------------------------------------------------------------------------
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: Column(
          children: [
            /*
            |--------------------------------------------------------------------------
            | Header
            |--------------------------------------------------------------------------
            */
            Container(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.shopping_cart_checkout, color: Colors.green, size: 32),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Purchases', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                        SizedBox(height: 3),
                        Text('Manage converted supplier purchases and VAT input.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(onPressed: loadPurchases, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
                ],
              ),
            ),

            /*
            |--------------------------------------------------------------------------
            | Content
            |--------------------------------------------------------------------------
            */
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    /*
                    |--------------------------------------------------------------------------
                    | KPI Summary
                    |--------------------------------------------------------------------------
                    */
                    Row(
                      children: [
                        kpiCard(title: 'Purchase Count', value: purchases.length.toString(), icon: Icons.receipt_long, color: Colors.blue),
                        const SizedBox(width: 14),
                        kpiCard(title: 'Total Excl VAT', value: formatMoney(totalExclVat()), icon: Icons.remove_circle_outline, color: Colors.indigo),
                        const SizedBox(width: 14),
                        kpiCard(title: 'VAT Input', value: formatMoney(totalVat()), icon: Icons.percent, color: Colors.orange),
                        const SizedBox(width: 14),
                        kpiCard(title: 'Total Purchases', value: formatMoney(totalPurchases()), icon: Icons.payments, color: Colors.green),
                      ],
                    ),

                    const SizedBox(height: 18),

                    /*
                    |--------------------------------------------------------------------------
                    | Filters
                    |--------------------------------------------------------------------------
                    */
                    filterPanel(),

                    const SizedBox(height: 18),

                    /*
                    |--------------------------------------------------------------------------
                    | Purchase List
                    |--------------------------------------------------------------------------
                    */
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : purchases.isEmpty
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(30),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.shopping_cart_checkout, size: 54, color: Colors.grey),
                                    SizedBox(height: 12),
                                    Text('No purchases found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 6),
                                    Text('Convert reviewed OCR receipts to purchases first.', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: purchases.length,
                              itemBuilder: (context, index) {
                                return purchaseCard(purchases[index]);
                              },
                            ),
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
| Info Text
|--------------------------------------------------------------------------
*/

class _InfoText extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoText({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 5),
        Text('$label: ', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}

/*
|--------------------------------------------------------------------------
| Amount Box
|--------------------------------------------------------------------------
*/

class _AmountBox extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool strong;

  const _AmountBox({required this.label, required this.value, this.highlight = false, this.strong = false});

  @override
  Widget build(BuildContext context) {
    final color = strong
        ? Colors.green
        : highlight
        ? Colors.orange
        : Colors.blueGrey;

    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: color.shade700, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color.shade800, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
