import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../services/api_service.dart';
import '../utils/money.dart';
import '../utils/receipt_pdf.dart';

/*
|--------------------------------------------------------------------------
| Sales History Screen
|--------------------------------------------------------------------------
| Used for:
| - sales lookup
| - receipt reprint
| - cashier review
| - audit trail
*/

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() =>
      _SalesHistoryScreenState();
}

class _SalesHistoryScreenState
    extends State<SalesHistoryScreen> {
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
  | Load Sales History
  |--------------------------------------------------------------------------
  */

  Future<void> loadSalesHistory() async {
    try {
            final data = await apiService.getSalesHistory(
        from: fromDate != null
            ? fromDate!
                .toIso8601String()
                .split('T')
                .first
            : null,

        to: toDate != null
            ? toDate!
                .toIso8601String()
                .split('T')
                .first
            : null,
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
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Reprint Receipt
  |--------------------------------------------------------------------------
  */

  Future<void> reprintReceipt(
    dynamic order,
  ) async {
    try {
      /*
      |--------------------------------------------------------------------------
      | Totals
      |--------------------------------------------------------------------------
      */

      final subtotal =
          toMoneyDouble(order['subtotal']);

      final taxAmount =
          toMoneyDouble(order['tax_amount']);

      final discountAmount =
          toMoneyDouble(order['discount_amount']);

      final totalAmount =
          toMoneyDouble(order['total_amount']);

      /*
      |--------------------------------------------------------------------------
      | Generate Thermal PDF
      |--------------------------------------------------------------------------
      */

      final pdfBytes = await generateReceiptPdf(
        order: order,
        paymentMethod:
            order['payment_method'] ?? 'cash',
        subtotal: subtotal,
        taxAmount: taxAmount,
        discountAmount: discountAmount,
        totalAmount: totalAmount,
      );

      /*
      |--------------------------------------------------------------------------
      | Print
      |--------------------------------------------------------------------------
      */

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
  | Build
  |--------------------------------------------------------------------------
  */
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        title: const Text(
          'Sales History',
        ),
      ),

body: isLoading
    ? const Center(
        child: CircularProgressIndicator(),
      )
    : Column(
        children: [
          /*
          |--------------------------------------------------------------------------
          | Date Filters
          |--------------------------------------------------------------------------
          */

          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      pickDate(isFrom: true);
                    },
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      fromDate == null
                          ? 'From Date'
                          : fromDate!
                              .toIso8601String()
                              .split('T')
                              .first,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      pickDate(isFrom: false);
                    },
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      toDate == null
                          ? 'To Date'
                          : toDate!
                              .toIso8601String()
                              .split('T')
                              .first,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                IconButton(
                  onPressed: () async {
                    setState(() {
                      fromDate = null;
                      toDate = null;
                    });

                    await loadSalesHistory();
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),

          /*
          |--------------------------------------------------------------------------
          | Sales List
          |--------------------------------------------------------------------------
          */

          Expanded(
            child: orders.isEmpty
                ? const Center(
                    child: Text(
                      'No sales found',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];

                      final total = toMoneyDouble(
                        order['total_amount'],
                      );

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    order['order_number'] ?? '-',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    formatMoney(total),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              Text('Type: ${order['order_type']}'),
                              Text(
                                'Payment: ${order['payment_method'] ?? 'cash'}',
                              ),

                              if (order['customer'] != null)
                                Text(
                                  'Customer: ${order['customer']['name']}',
                                ),

                              if (order['buzzer_number'] != null &&
                                  order['buzzer_number']
                                      .toString()
                                      .isNotEmpty)
                                Text(
                                  'Buzzer: ${order['buzzer_number']}',
                                ),

                              const SizedBox(height: 14),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    reprintReceipt(order);
                                  },
                                  icon: const Icon(Icons.print),
                                  label: const Text('Preview Receipt'),
                                ),
                              ),
                            ],
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