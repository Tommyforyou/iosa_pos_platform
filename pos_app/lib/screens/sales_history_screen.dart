import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../services/api_service.dart';
import '../utils/money.dart';
import '../utils/receipt_pdf.dart';

/*
|--------------------------------------------------------------------------
| Sales History Screen
|--------------------------------------------------------------------------
*/

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
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

  List<dynamic> orders = [];
  bool isLoading = true;

  /*
  |--------------------------------------------------------------------------
  | Date Filters
  |--------------------------------------------------------------------------
  */

  DateTime? fromDate;
  DateTime? toDate;

  @override
  void initState() {
    super.initState();
    loadSalesHistory();
  }

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
  | Load Sales History
  |--------------------------------------------------------------------------
  */

  Future<void> loadSalesHistory() async {
    try {
      setState(() {
        isLoading = true;
      });

      final data = await apiService.getSalesHistory(
        from: fromDate == null ? null : formatDate(fromDate!),
        to: toDate == null ? null : formatDate(toDate!),
      );

      if (!mounted) return;

      setState(() {
        orders = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Pick Date
  |--------------------------------------------------------------------------
  */

  Future<void> pickDate({
    required bool isFrom,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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

    await loadSalesHistory();
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
    });

    await loadSalesHistory();
  }

  /*
  |--------------------------------------------------------------------------
  | Reprint Receipt
  |--------------------------------------------------------------------------
  */

  Future<void> reprintReceipt(dynamic order) async {
    try {
      final subtotal = toMoneyDouble(order['subtotal']);
      final taxAmount = toMoneyDouble(order['tax_amount']);
      final discountAmount = toMoneyDouble(order['discount_amount']);
      final totalAmount = toMoneyDouble(order['total_amount']);

      final pdfBytes = await generateReceiptPdf(
        order: order,
        paymentMethod: order['payment_method'] ?? 'cash',
        subtotal: subtotal,
        taxAmount: taxAmount,
        discountAmount: discountAmount,
        totalAmount: totalAmount,
      );

      await Printing.layoutPdf(
        name: 'Receipt-${order['order_number']}',
        onLayout: (_) async => pdfBytes,
      );
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Totals
  |--------------------------------------------------------------------------
  */

  double totalSales() {
    double total = 0;

    for (final order in orders) {
      total += toMoneyDouble(order['total_amount']);
    }

    return total;
  }

  double totalVat() {
    double total = 0;

    for (final order in orders) {
      total += toMoneyDouble(order['tax_amount']);
    }

    return total;
  }

  double totalDiscount() {
    double total = 0;

    for (final order in orders) {
      total += toMoneyDouble(order['discount_amount']);
    }

    return total;
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
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                  ),
                ),
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
                  const Icon(
                    Icons.receipt_long,
                    color: Colors.blue,
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sales History',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'View sales transactions, VAT and receipt history.',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: loadSalesHistory,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
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
                    | KPI Cards
                    |--------------------------------------------------------------------------
                    */

                    Row(
                      children: [
                        _SalesKpiCard(
                          title: 'Sales Count',
                          value: orders.length.toString(),
                          icon: Icons.receipt_long,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 14),
                        _SalesKpiCard(
                          title: 'VAT Collected',
                          value: formatMoney(totalVat()),
                          icon: Icons.percent,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 14),
                        _SalesKpiCard(
                          title: 'Discounts',
                          value: formatMoney(totalDiscount()),
                          icon: Icons.discount,
                          color: Colors.purple,
                        ),
                        const SizedBox(width: 14),
                        _SalesKpiCard(
                          title: 'Total Revenue',
                          value: formatMoney(totalSales()),
                          icon: Icons.payments,
                          color: Colors.green,
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    /*
                    |--------------------------------------------------------------------------
                    | Filters
                    |--------------------------------------------------------------------------
                    */

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.grey.shade200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                pickDate(isFrom: true);
                              },
                              icon: const Icon(Icons.date_range),
                              label: Text(
                                fromDate == null
                                    ? 'From Date'
                                    : formatDate(fromDate!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                pickDate(isFrom: false);
                              },
                              icon: const Icon(Icons.date_range),
                              label: Text(
                                toDate == null
                                    ? 'To Date'
                                    : formatDate(toDate!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: loadSalesHistory,
                            icon: const Icon(Icons.filter_alt),
                            label: const Text('Apply'),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Clear filters',
                            onPressed: clearFilters,
                            icon: const Icon(Icons.clear),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    /*
                    |--------------------------------------------------------------------------
                    | Sales List
                    |--------------------------------------------------------------------------
                    */

                    Expanded(
                      child: isLoading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : orders.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No sales found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: orders.length,
                                  itemBuilder: (context, index) {
                                    final order = orders[index];

                                    final total =
                                        toMoneyDouble(order['total_amount']);

                                    final vat =
                                        toMoneyDouble(order['tax_amount']);

                                    final discount =
                                        toMoneyDouble(order['discount_amount']);

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.03),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 54,
                                            height: 54,
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.green.withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                            child: const Icon(
                                              Icons.point_of_sale,
                                              color: Colors.green,
                                              size: 28,
                                            ),
                                          ),

                                          const SizedBox(width: 14),

                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        order['order_number'] ??
                                                            '-',
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 10,
                                                        vertical: 5,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue
                                                            .withOpacity(0.12),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: Text(
                                                        (order['payment_method'] ??
                                                                'cash')
                                                            .toString()
                                                            .toUpperCase(),
                                                        style: const TextStyle(
                                                          color: Colors.blue,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(height: 8),

                                                Wrap(
                                                  spacing: 16,
                                                  runSpacing: 6,
                                                  children: [
                                                    _SalesInfo(
                                                      label: 'Type',
                                                      value:
                                                          order['order_type'] ??
                                                              '-',
                                                      icon: Icons.category,
                                                    ),
                                                    _SalesInfo(
                                                      label: 'Customer',
                                                      value: order['customer'] !=
                                                              null
                                                          ? order['customer']
                                                                  ['name'] ??
                                                              '-'
                                                          : '-',
                                                      icon: Icons.person,
                                                    ),
                                                    _SalesInfo(
                                                      label: 'Buzzer',
                                                      value: order['buzzer_number']
                                                                  ?.toString()
                                                                  .isNotEmpty ==
                                                              true
                                                          ? order[
                                                                  'buzzer_number']
                                                              .toString()
                                                          : '-',
                                                      icon: Icons
                                                          .notifications_active,
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(height: 10),

                                                Row(
                                                  children: [
                                                    _SalesAmount(
                                                      label: 'VAT',
                                                      value: formatMoney(vat),
                                                      color: Colors.orange,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    _SalesAmount(
                                                      label: 'Discount',
                                                      value:
                                                          formatMoney(discount),
                                                      color: Colors.purple,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    _SalesAmount(
                                                      label: 'Total',
                                                      value: formatMoney(total),
                                                      color: Colors.green,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          const SizedBox(width: 12),

                                          ElevatedButton.icon(
                                            onPressed: () {
                                              reprintReceipt(order);
                                            },
                                            icon: const Icon(Icons.print),
                                            label: const Text('Reprint'),
                                          ),
                                        ],
                                      ),
                                    );
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
| KPI Card
|--------------------------------------------------------------------------
*/

class _SalesKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SalesKpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade700,
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
}

/*
|--------------------------------------------------------------------------
| Sales Info
|--------------------------------------------------------------------------
*/

class _SalesInfo extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SalesInfo({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/*
|--------------------------------------------------------------------------
| Sales Amount
|--------------------------------------------------------------------------
*/

class _SalesAmount extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SalesAmount({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.85),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}