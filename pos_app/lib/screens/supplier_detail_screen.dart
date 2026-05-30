import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../utils/date_helper.dart';
import '../utils/snackbar_helper.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../utils/money.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final ApiService apiService = ApiService();
  final money = NumberFormat('#,##0.00');

  bool isLoading = true;
  Map<String, dynamic>? balance;
  List<dynamic> transactions = [];
  List<dynamic> outstandingInvoices = [];

  Map<String, dynamic>? businessSettings;
  String printFormat = 'thermal';

  Map<String, dynamic>? agingData;

  @override
  void initState() {
    super.initState();
    loadCustomerData();
    loadBusinessSettings();
  }

  Future<void> loadCustomerData() async {
    try {
      final balanceData = await apiService.getCustomerBalance(widget.customer['id']);

      final transactionData = await apiService.getCustomerTransactions(widget.customer['id']);

      final outstandingData = await apiService.getOutstandingInvoices(widget.customer['id']);
      final agingResponse = await apiService.getCustomerAging(widget.customer['id']);

      setState(() {
        balance = balanceData;
        transactions = transactionData['transactions'] ?? [];
        isLoading = false;
        outstandingInvoices = outstandingData['invoices'] ?? [];
        agingData = agingResponse['aging'];
      });
    } catch (e) {
      setState(() => isLoading = false);
      SnackbarHelper.error(context, e.toString());
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Load Business Settings
  |--------------------------------------------------------------------------
  */

  Future<void> loadBusinessSettings() async {
    try {
      final settings = await apiService.getBusinessSettings();

      if (!mounted) return;

      setState(() {
        businessSettings = settings;

        printFormat = settings['default_print_format'] ?? 'thermal';
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  /*
|--------------------------------------------------------------------------
| Print Customer Statement
|--------------------------------------------------------------------------
*/

  Future<void> printCustomerStatement(Map<String, dynamic> statement) async {
    final pdf = pw.Document();

    final customer = statement['customer'];
    final transactions = statement['transactions'] ?? [];
    final outstandingInvoices = statement['outstanding_invoices'] ?? [];

    final totalSales = double.tryParse(statement['total_sales'].toString()) ?? 0;

    final totalPayments = double.tryParse(statement['total_payments'].toString()) ?? 0;

    final closingBalance = double.tryParse(statement['closing_balance'].toString()) ?? 0;

    String amount(double value) {
      return money.format(value);
    }

    String blankIfZero(dynamic value) {
      final parsed = double.tryParse(value.toString()) ?? 0;
      return parsed == 0 ? '' : money.format(parsed);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(color: PdfColors.blueGrey900, borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        businessSettings?['company_name'] ?? 'IOSA POS',
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 17, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(businessSettings?['address'] ?? '', style: const pw.TextStyle(color: PdfColors.white, fontSize: 7)),
                      pw.Text(
                        'Tel: ${businessSettings?['phone'] ?? '-'}   BRN: ${businessSettings?['brn'] ?? '-'}   VAT: ${businessSettings?['vat_number'] ?? '-'}',
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 7),
                      ),
                    ],
                  ),
                  pw.Text(
                    'CUSTOMER\nSTATEMENT',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 15, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'CUSTOMER DETAILS',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text('Name: ${customer['name'] ?? '-'}', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('Phone: ${customer['phone'] ?? '-'}', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('BRN: ${customer['brn'] ?? '-'}', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('VAT: ${customer['vat_number'] ?? '-'}', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ACCOUNT SUMMARY',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                        ),
                        pw.SizedBox(height: 6),
                        _statementSummaryRow('Total Sales', amount(totalSales)),
                        _statementSummaryRow('Total Payments', amount(totalPayments)),
                        _statementSummaryRow('Balance Due', amount(closingBalance), bold: true),
                        _statementSummaryRow('Statement Date', DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 12),

            pw.Row(
              children: [
                _statementKpiCard('SALES', amount(totalSales)),
                pw.SizedBox(width: 8),
                _statementKpiCard('PAYMENTS', amount(totalPayments)),
                pw.SizedBox(width: 8),
                _statementKpiCard('BALANCE', amount(closingBalance), highlight: true),
              ],
            ),

            pw.SizedBox(height: 14),

            pw.Text(
              'OUTSTANDING INVOICES',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
            ),
            pw.SizedBox(height: 6),

            if (outstandingInvoices.isEmpty)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(6)),
                child: pw.Text('No outstanding invoices.', style: const pw.TextStyle(fontSize: 8)),
              )
            else
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
                headerStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 7),
                cellPadding: const pw.EdgeInsets.all(3),
                cellAlignments: {2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight, 4: pw.Alignment.centerRight},
                headers: const ['Invoice', 'Date', 'Total', 'Paid', 'Balance'],
                data: outstandingInvoices.map<List<String>>((invoice) {
                  return [
                    invoice['invoice_number']?.toString() ?? '-',
                    DateHelper.formatDateTime(invoice['date']?.toString()),
                    amount(double.tryParse(invoice['total_amount'].toString()) ?? 0),
                    blankIfZero(invoice['paid_amount']),
                    amount(double.tryParse(invoice['outstanding_amount'].toString()) ?? 0),
                  ];
                }).toList(),
              ),

            pw.SizedBox(height: 14),

            pw.Text(
              'CUSTOMER LEDGER',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
            ),
            pw.SizedBox(height: 6),

            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
              headerStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellPadding: const pw.EdgeInsets.all(3),
              cellAlignments: {3: pw.Alignment.centerRight, 4: pw.Alignment.centerRight, 5: pw.Alignment.centerRight},
              headers: const ['Date', 'Type', 'Reference', 'Debit', 'Credit', 'Balance'],
              data: transactions.map<List<String>>((tx) {
                return [
                  DateHelper.formatDateTime(tx['date']?.toString()),
                  tx['type'].toString().toUpperCase(),
                  tx['reference']?.toString() ?? '-',
                  blankIfZero(tx['debit']),
                  blankIfZero(tx['credit']),
                  amount(double.tryParse(tx['balance'].toString()) ?? 0),
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 16),

            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.blueGrey200),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('BALANCE DUE', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    'Rs ${amount(closingBalance)}',
                    style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            pw.Center(
              child: pw.Text(
                'This statement is computer generated and does not require signature.',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(name: 'Customer-Statement-${customer['name'] ?? 'customer'}', onLayout: (_) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(title: Text(customer['name'] ?? 'Customer')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /*
            |--------------------------------------------------------------------------
            | Customer Profile Header
            |--------------------------------------------------------------------------
            */
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6))],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: Colors.blue.shade50,
                          child: Text(
                            (customer['name'] ?? 'C').toString().substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ),

                        const SizedBox(width: 18),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(customer['name'] ?? '-', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 18,
                                runSpacing: 6,
                                children: [
                                  Text('Phone: ${customer['phone'] ?? '-'}'),
                                  Text('BRN: ${customer['brn'] ?? '-'}'),
                                  Text('VAT: ${customer['vat_number'] ?? '-'}'),
                                ],
                              ),
                            ],
                          ),
                        ),

                        ElevatedButton.icon(onPressed: showEditCustomerDialog, icon: const Icon(Icons.edit), label: const Text('Edit Customer')),

                        const SizedBox(width: 10),

                        ElevatedButton.icon(
                          onPressed: showRecordPaymentDialog,
                          icon: const Icon(Icons.payments),
                          label: const Text('Record Payment'),
                        ),

                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final statement = await apiService.getCustomerStatement(widget.customer['id']);
                              await printCustomerStatement(statement);
                            } catch (e) {
                              SnackbarHelper.error(context, e.toString());
                            }
                          },
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Statement'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  /*
            |--------------------------------------------------------------------------
            | Balance Cards
            |--------------------------------------------------------------------------
            */
                  Row(
                    children: [
                      _KpiCard(
                        title: 'Total Sales',
                        value: 'Rs ${money.format(double.tryParse(balance?['total_sales'].toString() ?? '0') ?? 0)}',
                        icon: Icons.receipt_long,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 14),
                      _KpiCard(
                        title: 'Total Payments',
                        value: 'Rs ${money.format(double.tryParse(balance?['total_payments'].toString() ?? '0') ?? 0)}',
                        icon: Icons.payments,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 14),
                      _KpiCard(
                        title: 'Outstanding',
                        value: 'Rs ${money.format(double.tryParse(balance?['outstanding_balance'].toString() ?? '0') ?? 0)}',
                        icon: Icons.warning_amber,
                        color: Colors.orange,
                      ),
                    ],
                  ),

                  /*
|--------------------------------------------------------------------------
| Aging Analysis
|--------------------------------------------------------------------------
*/
                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(22),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),

                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6))],
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        const Text('Account Aging', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            _AgingCard(title: 'Current', amount: agingData?['current'] ?? 0, color: Colors.green),

                            const SizedBox(width: 12),

                            _AgingCard(title: '31-60 Days', amount: agingData?['days_31_60'] ?? 0, color: Colors.amber),

                            const SizedBox(width: 12),

                            _AgingCard(title: '61-90 Days', amount: agingData?['days_61_90'] ?? 0, color: Colors.orange),

                            const SizedBox(width: 12),

                            _AgingCard(title: '90+ Days', amount: agingData?['days_90_plus'] ?? 0, color: Colors.red),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  /*
                  |--------------------------------------------------------------------------
                  | Outstanding Invoices
                  |--------------------------------------------------------------------------
                  */
                  Container(
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
                        const Text('Outstanding Invoices', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

                        const SizedBox(height: 16),

                        if (outstandingInvoices.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: Text('No outstanding invoices')),
                          )
                        else
                          DataTable(
                            columns: const [
                              DataColumn(label: Text('Invoice')),

                              DataColumn(label: Text('Date')),

                              DataColumn(label: Text('Total')),

                              DataColumn(label: Text('Paid')),

                              DataColumn(label: Text('Outstanding')),

                              DataColumn(label: Text('Status')),
                            ],

                            rows: outstandingInvoices.map((invoice) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(invoice['invoice_number'] ?? '-')),

                                  DataCell(Text(DateHelper.formatDateTime(invoice['date']?.toString()))),

                                  DataCell(Text('Rs ${money.format(double.tryParse(invoice['total_amount'].toString()) ?? 0)}')),

                                  DataCell(
                                    Text(
                                      'Rs ${money.format(double.tryParse(invoice['paid_amount'].toString()) ?? 0)}',
                                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                    ),
                                  ),

                                  DataCell(
                                    Text(
                                      'Rs ${money.format(double.tryParse(invoice['outstanding_amount'].toString()) ?? 0)}',
                                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                    ),
                                  ),

                                  DataCell(
                                    Chip(
                                      label: Text(invoice['payment_status'].toString().toUpperCase()),

                                      backgroundColor: invoice['payment_status'] == 'paid'
                                          ? Colors.green.shade50
                                          : invoice['payment_status'] == 'partial'
                                          ? Colors.orange.shade50
                                          : Colors.red.shade50,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  /*
                  |--------------------------------------------------------------------------
                  | Transactions
                  |--------------------------------------------------------------------------
                  */
                  Container(
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
                        const Text('Customer Ledger', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

                        const SizedBox(height: 16),

                        if (transactions.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: Text('No transactions found')),
                          )
                        else
                          DataTable(
                            columns: const [
                              DataColumn(label: Text('Date')),
                              DataColumn(label: Text('Type')),
                              DataColumn(label: Text('Reference')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Amount')),
                            ],
                            rows: transactions.map((tx) {
                              final isPayment = tx['type'] == 'payment';

                              return DataRow(
                                cells: [
                                  DataCell(Text(DateHelper.formatDateTime(tx['date']?.toString()))),
                                  DataCell(
                                    Chip(
                                      label: Text(isPayment ? 'PAYMENT' : 'SALE'),
                                      backgroundColor: isPayment ? Colors.green.shade50 : Colors.blue.shade50,
                                    ),
                                  ),
                                  DataCell(Text(tx['reference'] ?? '-')),
                                  DataCell(Text(tx['status'] ?? '-')),
                                  DataCell(
                                    Text(
                                      'Rs ${money.format(double.tryParse(tx['amount'].toString()) ?? 0)}',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: isPayment ? Colors.green : Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
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
| Record Customer Payment Dialog
|--------------------------------------------------------------------------
*/

  Future<void> showRecordPaymentDialog() async {
    final amountController = TextEditingController();
    final referenceController = TextEditingController();
    final notesController = TextEditingController();

    String paymentMethod = 'cash';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Record Payment'),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: paymentMethod,
                      decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'card', child: Text('Card')),
                        DropdownMenuItem(value: 'juice', child: Text('Juice')),
                        DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                        DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          paymentMethod = value ?? 'cash';
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: referenceController,
                      decoration: const InputDecoration(labelText: 'Reference', border: OutlineInputBorder()),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),

                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final amount = double.tryParse(amountController.text.trim()) ?? 0;

                      if (amount <= 0) {
                        SnackbarHelper.warning(context, 'Please enter a valid payment amount.');
                        return;
                      }

                      final result = await apiService.recordCustomerPayment(
                        customerId: widget.customer['id'],
                        amount: amount,
                        paymentMethod: paymentMethod,
                        reference: referenceController.text.trim(),
                        notes: notesController.text.trim(),
                        paymentDate: DateTime.now().toIso8601String().substring(0, 10),
                      );

                      if (!mounted) return;

                      Navigator.pop(context);

                      await printPaymentReceipt(Map<String, dynamic>.from(result['payment']));

                      SnackbarHelper.success(context, 'Payment recorded successfully.');

                      loadCustomerData();
                    } catch (e) {
                      SnackbarHelper.error(context, e.toString());
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Payment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /*
|--------------------------------------------------------------------------
| Print Customer Payment Receipt
|--------------------------------------------------------------------------
*/

  Future<void> printPaymentReceipt(Map<String, dynamic> payment) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Payment Receipt', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),

              pw.SizedBox(height: 14),

              pw.Text('Customer: ${widget.customer['name'] ?? '-'}'),
              pw.Text('Receipt No: PAY-${payment['id'] ?? '-'}'),
              pw.Text('Date: ${DateHelper.formatDateTime(payment['payment_date']?.toString())}'),
              pw.Text('Method: ${payment['payment_method'] ?? '-'}'),

              if (payment['reference'] != null) pw.Text('Reference: ${payment['reference']}'),

              pw.Divider(),

              pw.Text(
                'Amount Paid: Rs ${money.format(double.tryParse(payment['amount'].toString()) ?? 0)}',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),

              if (payment['notes'] != null) ...[pw.SizedBox(height: 12), pw.Text('Notes: ${payment['notes']}')],

              pw.SizedBox(height: 30),

              pw.Text('Thank you.'),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(name: 'Payment-Receipt-${payment['id'] ?? 'receipt'}', onLayout: (_) async => pdf.save());
  }

  pw.Widget _statementSummaryRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  pw.Widget _statementKpiCard(String title, String value, {bool highlight = false}) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(9),
        decoration: pw.BoxDecoration(
          color: highlight ? PdfColors.orange50 : PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: highlight ? PdfColors.orange300 : PdfColors.grey300),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Rs $value',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: highlight ? PdfColors.orange900 : PdfColors.blueGrey900),
            ),
          ],
        ),
      ),
    );
  }

  /*
|--------------------------------------------------------------------------
| Edit Customer Dialog
|--------------------------------------------------------------------------
*/

  Future<void> showEditCustomerDialog() async {
    final nameController = TextEditingController(text: widget.customer['name'] ?? '');

    final phoneController = TextEditingController(text: widget.customer['phone'] ?? '');

    final emailController = TextEditingController(text: widget.customer['email'] ?? '');

    final addressController = TextEditingController(text: widget.customer['address'] ?? '');

    final brnController = TextEditingController(text: widget.customer['brn'] ?? '');

    final vatController = TextEditingController(text: widget.customer['vat_number'] ?? '');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Customer'),

          content: SizedBox(
            width: 500,

            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),

                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),

                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),

                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),

                  TextField(
                    controller: brnController,
                    decoration: const InputDecoration(labelText: 'BRN'),
                  ),

                  TextField(
                    controller: vatController,
                    decoration: const InputDecoration(labelText: 'VAT Number'),
                  ),
                ],
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await apiService.updateCustomer(
                    customerId: widget.customer['id'],

                    name: nameController.text.trim(),

                    phone: phoneController.text.trim(),

                    email: emailController.text.trim(),

                    address: addressController.text.trim(),

                    brn: brnController.text.trim(),

                    vatNumber: vatController.text.trim(),
                  );

                  if (!mounted) return;

                  Navigator.pop(context);

                  SnackbarHelper.success(context, 'Customer updated successfully');

                  loadCustomerData();
                } catch (e) {
                  SnackbarHelper.error(context, e.toString());
                }
              },

              icon: const Icon(Icons.save),

              label: const Text('Update'),
            ),
          ],
        );
      },
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
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final String title;
  final String value;

  const _BalanceItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(title),
      ],
    );
  }
}

class _AgingCard extends StatelessWidget {
  final String title;
  final dynamic amount;
  final Color color;

  const _AgingCard({required this.title, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    final value = double.tryParse(amount.toString()) ?? 0;
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

            Text('Rs ${money.format(value)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
