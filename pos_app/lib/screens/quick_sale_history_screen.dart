import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:convert';

/*
|--------------------------------------------------------------------------
| Quick Sale History Screen
|--------------------------------------------------------------------------
| ERP-style screen for quick sale records, filters, KPIs and reprint actions.
*/

class QuickSaleHistoryScreen extends StatefulWidget {
  const QuickSaleHistoryScreen({super.key});

  @override
  State<QuickSaleHistoryScreen> createState() => _QuickSaleHistoryScreenState();
}

class _QuickSaleHistoryScreenState extends State<QuickSaleHistoryScreen> {
  /*
  |--------------------------------------------------------------------------
  | Services / Formatters
  |--------------------------------------------------------------------------
  */

  final ApiService apiService = ApiService();

  final money = NumberFormat('#,##0.00');

  /*
  |--------------------------------------------------------------------------
  | Controllers
  |--------------------------------------------------------------------------
  */

  final TextEditingController searchController = TextEditingController();

  final TextEditingController fromDateController = TextEditingController();

  final TextEditingController toDateController = TextEditingController();

  /*
  |--------------------------------------------------------------------------
  | State
  |--------------------------------------------------------------------------
  */

  bool isLoading = true;

  List<dynamic> sales = [];

  /*
  |--------------------------------------------------------------------------
  | Init / Dispose
  |--------------------------------------------------------------------------
  */

  @override
  void initState() {
    super.initState();

    loadSales();
  }

  @override
  void dispose() {
    searchController.dispose();
    fromDateController.dispose();
    toDateController.dispose();

    super.dispose();
  }

  /*
|--------------------------------------------------------------------------
| Load MRA QR Image
|--------------------------------------------------------------------------
*/

  Future<pw.MemoryImage?> loadMraQrImage(String? base64Qr) async {
    try {
      if (base64Qr == null || base64Qr.isEmpty) {
        return null;
      }

      final bytes = base64Decode(base64Qr);

      return pw.MemoryImage(bytes);
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  /*
|--------------------------------------------------------------------------
| View Sale Detail
|--------------------------------------------------------------------------
*/

  void showSaleDetail(dynamic sale) {
    showDialog(
      context: context,
      builder: (context) {
        final items = sale['items'] ?? [];

        return AlertDialog(
          title: Text(sale['invoice_number'] ?? 'Invoice Detail'),
          content: SizedBox(
            width: 650,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer: ${sale['customer']?['name'] ?? 'Walk-in'}'),
                  Text('Type: ${sale['sale_type'] ?? '-'}'),
                  Text('Payment: ${sale['payment_method'] ?? '-'}'),
                  Text('Date: ${sale['created_at'] ?? '-'}'),

                  if (sale['sale_status'] == 'voided' && sale['notes'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),

                      child: Text(
                        'Reason: ${sale['notes']}',

                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  const Text(
                    'Items',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const Divider(),

                  for (final item in items)
                    ListTile(
                      title: Text(item['product_name'] ?? '-'),
                      subtitle: Text(
                        '${item['quantity']} x Rs ${item['unit_price']}',
                      ),
                      trailing: Text(
                        'Rs ${item['line_total']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),

                  const Divider(),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Subtotal: Rs ${sale['subtotal']}'),
                        Text('VAT: Rs ${sale['vat_amount']}'),
                        Text(
                          'Total: Rs ${sale['total_amount']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /*
|--------------------------------------------------------------------------
| Confirm Void Sale
|--------------------------------------------------------------------------
*/

  Future<void> confirmVoidSale(dynamic sale) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: Text('Void ${sale['invoice_number'] ?? 'Sale'}'),

          content: SizedBox(
            width: 450,
            child: TextField(
              controller: reasonController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Reason for void',
                border: OutlineInputBorder(),
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton.icon(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  return;
                }

                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.block),
              label: const Text('Void Sale'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await apiService.voidQuickSale(
        saleId: sale['id'],
        reason: reasonController.text.trim(),
      );

      await loadSales();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sale voided successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Load Sales
  |--------------------------------------------------------------------------
  */

  Future<void> loadSales() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await apiService.getQuickSalesHistory(
        search: searchController.text.trim(),
        from: fromDateController.text.trim().isEmpty
            ? null
            : fromDateController.text.trim(),
        to: toDateController.text.trim().isEmpty
            ? null
            : toDateController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        sales = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Date Picker
  |--------------------------------------------------------------------------
  */

  Future<void> pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (picked == null) return;

    controller.text = DateFormat('yyyy-MM-dd').format(picked);
  }

  /*
  |--------------------------------------------------------------------------
  | Totals
  |--------------------------------------------------------------------------
  */

  double totalSales() {
    return sales.fold(0, (sum, sale) {
      return sum + (double.tryParse(sale['total_amount'].toString()) ?? 0);
    });
  }

  double totalVat() {
    return sales.fold(0, (sum, sale) {
      return sum + (double.tryParse(sale['vat_amount'].toString()) ?? 0);
    });
  }

  int creditSalesCount() {
    return sales.where((sale) => sale['sale_type'] == 'credit').length;
  }

  /*
  |--------------------------------------------------------------------------
  | Clear Filters
  |--------------------------------------------------------------------------
  */

  void clearFilters() {
    searchController.clear();
    fromDateController.clear();
    toDateController.clear();

    loadSales();
  }

  /*
|--------------------------------------------------------------------------
| Print Thermal Receipt
|--------------------------------------------------------------------------
*/

  Future<void> printThermalReceipt(Map<String, dynamic> sale) async {
    final pdf = pw.Document();

    final money = NumberFormat('#,##0.00');

    final saleItems = sale['items'] ?? [];

    final mraQrImage = await loadMraQrImage(sale['mra_qr_code']);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,

          marginAll: 4 * PdfPageFormat.mm,
        ),

        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,

            children: [
              /*
            |--------------------------------------------------------------------------
            | Header
            |--------------------------------------------------------------------------
            */
              pw.Center(
                child: pw.Text(
                  'IOSA POS',

                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.Center(
                child: pw.Text(
                  'Quick Sale Receipt',

                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),

              pw.SizedBox(height: 6),

              pw.Divider(),

              pw.Text(
                'Invoice: ${sale['invoice_number'] ?? '-'}',
                style: const pw.TextStyle(fontSize: 9),
              ),

              pw.Text(
                'Payment: ${sale['payment_method'] ?? '-'}',
                style: const pw.TextStyle(fontSize: 9),
              ),

              if (sale['customer'] != null)
                pw.Text(
                  'Customer: ${sale['customer']['name']}',
                  style: const pw.TextStyle(fontSize: 9),
                ),

              pw.Divider(),

              /*
            |--------------------------------------------------------------------------
            | Items
            |--------------------------------------------------------------------------
            */
              for (final item in saleItems)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,

                  children: [
                    pw.Text(
                      item['product_name'] ?? '-',

                      style: const pw.TextStyle(fontSize: 10),
                    ),

                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,

                      children: [
                        pw.Text(
                          '${item['quantity']} x '
                          '${money.format(double.tryParse(item['unit_price'].toString()) ?? 0)}',

                          style: const pw.TextStyle(fontSize: 9),
                        ),

                        pw.Text(
                          money.format(
                            double.tryParse(item['line_total'].toString()) ?? 0,
                          ),

                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 4),
                  ],
                ),

              pw.Divider(),

              /*
            |--------------------------------------------------------------------------
            | Totals
            |--------------------------------------------------------------------------
            */
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,

                children: [
                  pw.Text(
                    'TOTAL',

                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),

                  pw.Text(
                    money.format(
                      double.tryParse(sale['total_amount'].toString()) ?? 0,
                    ),

                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              pw.Center(
                child: pw.Text(
                  'Thank you',

                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),

              if (sale['mra_submitted'] == true) ...[
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.Center(
                  child: pw.Text(
                    'MRA FISCALISED',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    'IRN: ${sale['mra_irn'] ?? ''}',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.SizedBox(height: 8),
                if (mraQrImage != null)
                  pw.Center(
                    child: pw.Image(
                      mraQrImage,
                      width: 120,
                      height: 120,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      name: 'Thermal-${sale['invoice_number']}',

      onLayout: (_) async => pdf.save(),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Print Quick Sale Invoice
  |--------------------------------------------------------------------------
  */

  Future<void> printA4Invoice(Map<String, dynamic> sale) async {
    final pdf = pw.Document();
    final money = NumberFormat('#,##0.00');
    final saleItems = sale['items'] ?? [];
    final mraQrImage = await loadMraQrImage(sale['mra_qr_code']);

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'IOSA POS',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 6),

              pw.Text('Quick Sale Invoice'),

              pw.Divider(),

              pw.Text('Invoice: ${sale['invoice_number'] ?? '-'}'),
              pw.Text('Sale Type: ${sale['sale_type'] ?? '-'}'),
              pw.Text('Payment: ${sale['payment_method'] ?? '-'}'),

              if (sale['customer'] != null) ...[
                pw.SizedBox(height: 8),
                pw.Text('Customer: ${sale['customer']['name'] ?? '-'}'),
                pw.Text('BRN: ${sale['customer']['brn'] ?? '-'}'),
                pw.Text('VAT: ${sale['customer']['vat_number'] ?? '-'}'),
              ],

              pw.SizedBox(height: 12),

              pw.Text(
                'Items',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),

              pw.Divider(),

              for (final item in saleItems)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          item['product_name'] ?? item['description'] ?? '-',
                        ),
                      ),
                      pw.Text('${item['quantity']}'),
                      pw.SizedBox(width: 12),
                      pw.Text(
                        money.format(
                          double.tryParse(item['line_total'].toString()) ?? 0,
                        ),
                      ),
                    ],
                  ),
                ),
              pw.Divider(),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal'),
                  pw.Text(
                    money.format(
                      double.tryParse(sale['subtotal'].toString()) ?? 0,
                    ),
                  ),
                ],
              ),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('VAT'),
                  pw.Text(
                    money.format(
                      double.tryParse(sale['vat_amount'].toString()) ?? 0,
                    ),
                  ),
                ],
              ),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    money.format(
                      double.tryParse(sale['total_amount'].toString()) ?? 0,
                    ),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text('Thank you.'),

              if (sale['mra_submitted'] == true) ...[
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.Center(
                  child: pw.Text(
                    'MRA FISCALISED INVOICE',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Center(
                  child: pw.Text(
                    'IRN: ${sale['mra_irn'] ?? ''}',
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 10),
                if (mraQrImage != null)
                  pw.Center(
                    child: pw.Image(
                      mraQrImage,
                      width: 130,
                      height: 130,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      name: 'Quick-Sale-${sale['invoice_number'] ?? 'invoice'}',
      onLayout: (_) async => pdf.save(),
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
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
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

                  const Icon(Icons.receipt_long, color: Colors.green, size: 34),

                  const SizedBox(width: 14),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Sales History',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Review invoice sales, VAT totals and reprint receipts.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  OutlinedButton.icon(
                    onPressed: loadSales,
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    /*
                    |--------------------------------------------------------------------------
                    | KPI Cards
                    |--------------------------------------------------------------------------
                    */
                    Row(
                      children: [
                        _StatCard(
                          title: 'Sales Count',
                          value: sales.length.toString(),
                          icon: Icons.receipt,
                          color: Colors.blue,
                        ),

                        const SizedBox(width: 16),

                        _StatCard(
                          title: 'Total Sales',
                          value: 'Rs ${money.format(totalSales())}',
                          icon: Icons.payments,
                          color: Colors.green,
                        ),

                        const SizedBox(width: 16),

                        _StatCard(
                          title: 'VAT Collected',
                          value: 'Rs ${money.format(totalVat())}',
                          icon: Icons.percent,
                          color: Colors.orange,
                        ),

                        const SizedBox(width: 16),

                        _StatCard(
                          title: 'Credit Sales',
                          value: creditSalesCount().toString(),
                          icon: Icons.account_balance_wallet,
                          color: Colors.purple,
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: searchController,
                              onSubmitted: (_) => loadSales(),
                              decoration: InputDecoration(
                                labelText: 'Search invoice/customer',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: TextField(
                              controller: fromDateController,
                              readOnly: true,
                              onTap: () => pickDate(fromDateController),
                              decoration: InputDecoration(
                                labelText: 'From Date',
                                prefixIcon: const Icon(Icons.calendar_month),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: TextField(
                              controller: toDateController,
                              readOnly: true,
                              onTap: () => pickDate(toDateController),
                              decoration: InputDecoration(
                                labelText: 'To Date',
                                prefixIcon: const Icon(Icons.calendar_month),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          ElevatedButton.icon(
                            onPressed: loadSales,
                            icon: const Icon(Icons.filter_alt),
                            label: const Text('Apply'),
                          ),

                          IconButton(
                            onPressed: clearFilters,
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    /*
                    |--------------------------------------------------------------------------
                    | Sales List
                    |--------------------------------------------------------------------------
                    */
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 120),
                        child: CircularProgressIndicator(),
                      )
                    else if (sales.isEmpty)
                      const _EmptyState()
                    else
                      Column(
                        children: sales.map((sale) {
                          return _SaleCard(
                            sale: sale,
                            money: money,
                            onRetrySuccess: loadSales,

                            // Show Sales
                            onView: () {
                              showSaleDetail(sale);
                            },

                            // Void Sales
                            onVoid: () {
                              confirmVoidSale(sale);
                            },

                            // Print Sales
                            onPrint: () async {
                              final format = await showDialog<String>(
                                context: context,

                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Select Print Format'),

                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, 'thermal');
                                        },

                                        child: const Text('Thermal'),
                                      ),

                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, 'a4');
                                        },

                                        child: const Text('A4 Invoice'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (format == 'thermal') {
                                await printThermalReceipt(sale);
                              } else if (format == 'a4') {
                                await printA4Invoice(sale);
                              }
                            },
                          );
                        }).toList(),
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
| Stat Card
|--------------------------------------------------------------------------
*/

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 92,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
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
| Sale Card
|--------------------------------------------------------------------------
*/

class _SaleCard extends StatelessWidget {
  final dynamic sale;
  final NumberFormat money;
  final VoidCallback onPrint;
  final VoidCallback onView;
  final VoidCallback onVoid;
  final VoidCallback onRetrySuccess;

  final ApiService apiService = ApiService();

  _SaleCard({
    required this.sale,
    required this.money,
    required this.onPrint,
    required this.onView,
    required this.onVoid,
    required this.onRetrySuccess,
  });

  @override
  Widget build(BuildContext context) {
    final customerName = sale['customer']?['name'] ?? 'Walk-in';

    final total = double.tryParse(sale['total_amount'].toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: sale['sale_status'] == 'voided'
            ? Colors.red.shade50
            : Colors.white,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(
          color: sale['sale_status'] == 'voided'
              ? Colors.red.shade300
              : Colors.grey.shade200,

          width: sale['sale_status'] == 'voided' ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.withOpacity(0.12),
            child: const Icon(Icons.receipt_long, color: Colors.green),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale['invoice_number'] ?? '-',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                /*
                |--------------------------------------------------------------------------
                | MRA Status Badge
                |--------------------------------------------------------------------------
                */
                if (sale['mra_submitted'] == true)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'MRA FISCALISED',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  )
                else if (sale['mra_status'] == 'ERROR')
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'MRA FAILED',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  )
                else if (sale['mra_submitted'] == false &&
                    sale['sale_type'] != 'walk_in')
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'MRA PENDING',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),

                /*
                |--------------------------------------------------------------------------
                | Retry MRA Submission
                |--------------------------------------------------------------------------
                */
                if (sale['mra_submitted'] != true)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final response = await apiService.retryMraSubmission(
                            sale['id'],
                          );

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                response['success'] == true
                                    ? 'MRA retry successful'
                                    : 'MRA retry failed',
                              ),
                            ),
                          );

                          onRetrySuccess();
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      },

                      icon: const Icon(Icons.refresh),

                      label: const Text('Retry MRA'),
                    ),
                  ),

                /*
                |--------------------------------------------------------------------------
                | VOID Badge
                |--------------------------------------------------------------------------
                */
                if (sale['sale_status'] == 'voided')
                  Container(
                    margin: const EdgeInsets.only(top: 6),

                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(30),
                    ),

                    child: const Text(
                      'VOIDED',

                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),

                const SizedBox(height: 5),

                Wrap(
                  spacing: 18,
                  runSpacing: 6,
                  children: [
                    if (sale['sale_status'] == 'voided' &&
                        sale['notes'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),

                        child: Text(
                          'Reason: ${sale['notes']}',

                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    Text('Customer: $customerName'),
                    Text('Type: ${sale['sale_type'] ?? '-'}'),
                    Text('Payment: ${sale['payment_method'] ?? '-'}'),
                    Text('Date: ${sale['created_at'] ?? '-'}'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs ${money.format(total)}',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /*
                  |--------------------------------------------------------------------------
                  | View Invoice
                  |--------------------------------------------------------------------------
                  */
                  OutlinedButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View'),
                  ),

                  const SizedBox(width: 8),

                  /*
                  |--------------------------------------------------------------------------
                  | Reprint
                  |--------------------------------------------------------------------------
                  */
                  OutlinedButton.icon(
                    onPressed: sale['sale_status'] == 'voided' ? null : onPrint,
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Reprint'),
                  ),

                  const SizedBox(width: 8),

                  /*
                  |--------------------------------------------------------------------------
                  | Void Sale
                  |--------------------------------------------------------------------------
                  */
                  OutlinedButton.icon(
                    onPressed: sale['sale_status'] == 'voided' ? null : onVoid,

                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),

                    icon: const Icon(Icons.block, size: 16),

                    label: Text(
                      sale['sale_status'] == 'voided' ? 'Voided' : 'Void',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/*
|--------------------------------------------------------------------------
| Empty State
|--------------------------------------------------------------------------
*/

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 160),
      child: Center(
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(34),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
          ),
          child: const Column(
            children: [
              Icon(Icons.receipt_long, size: 54, color: Colors.grey),
              SizedBox(height: 14),
              Text(
                'No quick sales found',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
              ),
              SizedBox(height: 8),
              Text(
                'Create a quick sale first, then it will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
