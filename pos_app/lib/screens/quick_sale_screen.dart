import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/money.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:http/http.dart' as http;

/*
|--------------------------------------------------------------------------
| Quick Sale Screen
|--------------------------------------------------------------------------
| Invoice-style sale screen.
*/

class QuickSaleScreen extends StatefulWidget {
  const QuickSaleScreen({super.key});

  @override
  State<QuickSaleScreen> createState() => _QuickSaleScreenState();
}

class _QuickSaleScreenState extends State<QuickSaleScreen> {
  /*
  |--------------------------------------------------------------------------
  | Variables
  |--------------------------------------------------------------------------
  */

  final ApiService apiService = ApiService();

  String saleType = 'walk_in';
  String paymentMethod = 'cash';
  String printFormat = 'thermal';

  bool isSaving = false;

  bool saveNewItemAsProduct = true;

  Map<String, dynamic>? selectedProduct;

  List<dynamic> productResults = [];

  Map<String, dynamic>? businessSettings;

  /*
  |--------------------------------------------------------------------------
  | Controllers
  |--------------------------------------------------------------------------
  */

  final TextEditingController amountTenderedController =
      TextEditingController();

  final TextEditingController productSearchController = TextEditingController();
  final TextEditingController newItemBarcodeController =
      TextEditingController();

  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController priceController = TextEditingController();

  /*
  |--------------------------------------------------------------------------
  | Init State
  |--------------------------------------------------------------------------
  */

  @override
  void initState() {
    super.initState();
    loadBusinessSettings();
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
| Load Business Logo For Printing
|--------------------------------------------------------------------------
*/

  Future<pw.MemoryImage?> loadBusinessLogoForPrint() async {
    try {
      final logoPath = businessSettings?['logo_path'];

      if (logoPath == null) {
        return null;
      }

      final logoUrl = '${ApiService.publicBaseUrl}/storage/$logoPath';

      final response = await http.get(Uri.parse(logoUrl));

      if (response.statusCode != 200) {
        return null;
      }

      return pw.MemoryImage(response.bodyBytes);
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Amount Tendered
  |--------------------------------------------------------------------------
  */

  double amountTendered() {
    return toMoneyDouble(amountTenderedController.text);
  }

  /*
  |--------------------------------------------------------------------------
  | Payment Rules
  |--------------------------------------------------------------------------
  */

  bool canEditAmountTendered() {
    return paymentMethod == 'cash';
  }

  void syncTenderedWithPaymentMethod() {
    if (paymentMethod == 'cash') {
      return;
    }

    if (paymentMethod == 'credit') {
      amountTenderedController.clear();

      return;
    }

    amountTenderedController.text = grandTotal().toStringAsFixed(2);
  }

  double changeDue() {
    return amountTendered() - grandTotal();
  }

  List<Map<String, dynamic>> items = [];

  Map<String, dynamic>? selectedCustomer;

  final TextEditingController customerSearchController =
      TextEditingController();

  List<dynamic> customerResults = [];

  @override
  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    priceController.dispose();
    customerSearchController.dispose();
    productSearchController.dispose();
    amountTenderedController.dispose();
    newItemBarcodeController.dispose();
    super.dispose();
  }

  double subtotal() {
    return items.fold(0, (sum, item) {
      return sum + toMoneyDouble(item['unit_price_excl_vat']);
    });
  }

  double vatTotal() {
    return items.fold(0, (sum, item) {
      return sum + toMoneyDouble(item['vat_amount']);
    });
  }

  double grandTotal() {
    return items.fold(0, (sum, item) {
      return sum + toMoneyDouble(item['line_total_incl_vat']);
    });
  }

  void appendTendered(String value) {
    setState(() {
      amountTenderedController.text = amountTenderedController.text + value;
    });
  }

  void clearTendered() {
    setState(() {
      amountTenderedController.clear();
    });
  }
  /*
|--------------------------------------------------------------------------
| Print Thermal Receipt
|--------------------------------------------------------------------------
*/

  Future<void> printThermalReceipt(Map<String, dynamic> sale) async {
    final pdf = pw.Document();
    final logoImage = await loadBusinessLogoForPrint();
    final money = NumberFormat('#,##0.00');

    final saleItems = sale['items'] ?? [];

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
              if (logoImage != null)
                pw.Center(
                  child: pw.Image(
                    logoImage,
                    width: 80,
                    height: 80,
                    fit: pw.BoxFit.contain,
                  ),
                ),

              pw.SizedBox(height: 6),

              pw.Center(
                child: pw.Text(
                  businessSettings?['company_name'] ?? 'IOSA POS',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              if (businessSettings?['address'] != null)
                pw.Center(
                  child: pw.Text(
                    businessSettings!['address'],
                    style: const pw.TextStyle(fontSize: 8),
                    textAlign: pw.TextAlign.center,
                  ),
                ),

              if (businessSettings?['phone'] != null)
                pw.Center(
                  child: pw.Text(
                    'Tel: ${businessSettings!['phone']}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),

              if (businessSettings?['vat_number'] != null)
                pw.Center(
                  child: pw.Text(
                    'VAT: ${businessSettings!['vat_number']}',
                    style: const pw.TextStyle(fontSize: 8),
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

              pw.SizedBox(height: 8),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,

                children: [
                  pw.Text('Tendered', style: const pw.TextStyle(fontSize: 9)),

                  pw.Text(
                    money.format(amountTendered()),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,

                children: [
                  pw.Text(
                    'Change',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),

                  pw.Text(
                    money.format(changeDue()),

                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              pw.Center(
                child: pw.Text(
                  businessSettings?['receipt_footer'] ?? 'Thank you',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
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
    final logoImage = await loadBusinessLogoForPrint();
    final money = NumberFormat('#,##0.00');
    final saleItems = sale['items'] ?? [];

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoImage != null)
                pw.Center(
                  child: pw.Image(
                    logoImage,
                    width: 120,
                    height: 120,
                    fit: pw.BoxFit.contain,
                  ),
                ),

              pw.SizedBox(height: 10),

              pw.Text(
                businessSettings?['company_name'] ?? 'IOSA POS',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              if (businessSettings?['address'] != null)
                pw.Center(
                  child: pw.Text(
                    businessSettings!['address'],
                    style: const pw.TextStyle(fontSize: 8),
                    textAlign: pw.TextAlign.center,
                  ),
                ),

              if (businessSettings?['phone'] != null)
                pw.Center(
                  child: pw.Text(
                    'Tel: ${businessSettings!['phone']}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),

              if (businessSettings?['vat_number'] != null)
                pw.Center(
                  child: pw.Text(
                    'VAT: ${businessSettings!['vat_number']}',
                    style: const pw.TextStyle(fontSize: 8),
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

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Amount Tendered'),
                  pw.Text(money.format(amountTendered())),
                ],
              ),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Change Due',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),

                  pw.Text(
                    money.format(changeDue()),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              pw.Text(businessSettings?['receipt_footer'] ?? 'Thank you'),
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
  | Show New Customer Dialog
  |--------------------------------------------------------------------------
  */

  Future<void> showNewCustomerDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final brnController = TextEditingController();
    final vatController = TextEditingController();
    final addressController = TextEditingController();
    final emailController = TextEditingController();

    await showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text('New Customer'),

          content: SizedBox(
            width: 500,

            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name',
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: brnController,
                    decoration: const InputDecoration(labelText: 'BRN'),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: vatController,
                    decoration: const InputDecoration(labelText: 'VAT Number'),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
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

            ElevatedButton(
              onPressed: () async {
                try {
                  final result = await apiService.createCustomer(
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    brn: brnController.text.trim(),
                    vatNumber: vatController.text.trim(),
                    address: addressController.text.trim(),
                    email: emailController.text.trim(),
                  );

                  if (!mounted) return;

                  setState(() {
                    selectedCustomer = result['customer'];
                  });

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Customer created successfully'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },

              child: const Text('Save Customer'),
            ),
          ],
        );
      },
    );
  }

  void addItem() {
    final description = descriptionController.text.trim();
    final quantity = toMoneyDouble(quantityController.text);
    final unitPrice = toMoneyDouble(priceController.text);

    if (description.isEmpty || quantity <= 0 || unitPrice <= 0) {
      return;
    }

    final lineExclVat = quantity * unitPrice;
    final vat = lineExclVat * 15 / 100;
    final totalInclVat = lineExclVat + vat;

    setState(() {
      final existingIndex = items.indexWhere((item) {
        return item['product_id'] != null &&
            item['product_id'] == selectedProduct?['id'];
      });

      if (existingIndex >= 0) {
        final oldItem = items[existingIndex];

        final newQuantity = toMoneyDouble(oldItem['quantity']) + quantity;

        final newLineExclVat = newQuantity * unitPrice;

        final newVat = newLineExclVat * 15 / 100;

        final newTotalInclVat = newLineExclVat + newVat;

        setState(() {
          items[existingIndex]['quantity'] = newQuantity;
          items[existingIndex]['vat_amount'] = newVat;
          items[existingIndex]['line_total_incl_vat'] = newTotalInclVat;

          selectedProduct = null;
          productResults = [];
          productSearchController.clear();
          descriptionController.clear();
          quantityController.text = '1';
          priceController.clear();
        });

        return;
      }

      items.add({
        'product_id': selectedProduct?['id'],
        'description': description,
        'quantity': quantity,
        'unit_price_excl_vat': unitPrice,
        'vat_amount': vat,
        'line_total_incl_vat': totalInclVat,
        'save_as_product': selectedProduct == null && saveNewItemAsProduct,
        'barcode': newItemBarcodeController.text.trim(),
      });

      newItemBarcodeController.clear();
      selectedProduct = null;
      productResults = [];
      productSearchController.clear();

      descriptionController.clear();
      quantityController.text = '1';
      priceController.clear();
    });
  }

  /*
  |--------------------------------------------------------------------------
  | Select Product
  |--------------------------------------------------------------------------
  */

  void selectProduct(dynamic product) {
    setState(() {
      selectedProduct = Map<String, dynamic>.from(product);

      descriptionController.text = product['name'] ?? '';

      priceController.text = product['selling_price']?.toString() ?? '0';

      productSearchController.text = product['name'] ?? '';

      productResults = [];
    });
  }

  /*
  |--------------------------------------------------------------------------
  | Search Products
  |--------------------------------------------------------------------------
  */

  Future<void> searchProducts() async {
    try {
      final data = await apiService.getProducts(
        search: productSearchController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        productResults = data;
        debugPrint('Products found: ${data.length}');
      });

      /*
      |--------------------------------------------------------------------------
      | Auto Select Exact Barcode Match
      |--------------------------------------------------------------------------
      | if only 1 records if found product is selected instantly otherwise a drop down is shown
      */

      if (data.length == 1) {
        final product = data.first;

        if ((product['barcode'] ?? '').toString().trim() ==
            productSearchController.text.trim()) {
          selectProduct(product);

          /*
          |--------------------------------------------------------------------------
          | Auto Add Barcode Product
          |--------------------------------------------------------------------------
          */

          Future.delayed(const Duration(milliseconds: 150), () {
            addItem();

            productSearchController.clear();
          });
        }
      }
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
  /*
  |--------------------------------------------------------------------------
  | Search Customers
  |--------------------------------------------------------------------------
  */

  Future<void> searchCustomers() async {
    try {
      final data = await apiService.getCustomers(
        search: customerSearchController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        customerResults = data;
      });
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }
  /*
  |--------------------------------------------------------------------------
  | Select Customer
  |--------------------------------------------------------------------------
  */

  void selectCustomer(dynamic customer) {
    setState(() {
      selectedCustomer = Map<String, dynamic>.from(customer);
      customerResults = [];
      customerSearchController.text = customer['name'] ?? '';
    });
  }

  /*
  |--------------------------------------------------------------------------
  | Save Quick Sale
  |--------------------------------------------------------------------------
  */

  Future<void> saveSale() async {
    /*
    |--------------------------------------------------------------------------
    | Customer Required Validation
    |--------------------------------------------------------------------------
    */

    if ((saleType == 'vat_invoice' || saleType == 'credit') &&
        selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Customer is required for VAT invoices and credit sales.',
          ),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    if (items.isEmpty) {
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      final result = await apiService.createQuickSale(
        customerId: selectedCustomer?['id'],
        saleType: saleType,
        paymentMethod: paymentMethod,
        items: items,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quick sale created successfully'),
          backgroundColor: Colors.green,
        ),
      );

      /*
      |--------------------------------------------------------------------------
      | Printing Receipt
      |--------------------------------------------------------------------------
      */

      final saleData = result['sale'];

      if (saleData != null) {
        if (printFormat == 'thermal') {
          await printThermalReceipt(Map<String, dynamic>.from(saleData as Map));
        } else {
          await printA4Invoice(Map<String, dynamic>.from(saleData as Map));
        }
      }

      setState(() {
        items.clear();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowedPaymentMethods = ['cash', 'card', 'juice', 'cheque', 'credit'];

    if (!allowedPaymentMethods.contains(paymentMethod)) {
      paymentMethod = 'cash';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(title: const Text('Quick Sale')),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sale Entry',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: saleType,
                            decoration: const InputDecoration(
                              labelText: 'Sale Type',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'walk_in',
                                child: Text('Walk-in'),
                              ),
                              DropdownMenuItem(
                                value: 'vat_invoice',
                                child: Text('VAT Invoice'),
                              ),
                              DropdownMenuItem(
                                value: 'credit',
                                child: Text('Credit Sale'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                saleType = value ?? 'walk_in';
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: paymentMethod,
                            decoration: const InputDecoration(
                              labelText: 'Payment',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'cash',
                                child: Text('Cash'),
                              ),
                              DropdownMenuItem(
                                value: 'card',
                                child: Text('Card'),
                              ),
                              DropdownMenuItem(
                                value: 'juice',
                                child: Text('Juice'),
                              ),
                              DropdownMenuItem(
                                value: 'cheque',
                                child: Text('Cheque'),
                              ),
                              DropdownMenuItem(
                                value: 'credit',
                                child: Text('Credit'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                paymentMethod = value ?? 'cash';
                                syncTenderedWithPaymentMethod();
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /*
                    |--------------------------------------------------------------------------
                    | Customer Section
                    |--------------------------------------------------------------------------
                    */
                    const Text(
                      'Customer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (saleType == 'vat_invoice' || saleType == 'credit')
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Customer information is required for VAT invoices and credit sales.',
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: customerSearchController,
                                  onChanged: (_) => searchCustomers(),
                                  decoration: InputDecoration(
                                    labelText:
                                        'Customer name / phone / BRN / VAT',
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  showNewCustomerDialog();
                                },
                                icon: const Icon(Icons.person_add),
                                label: const Text('New Customer'),
                              ),
                            ],
                          ),

                          /*
                          |--------------------------------------------------------------------------
                          | Selected Customer Card
                          |--------------------------------------------------------------------------
                          */
                          if (selectedCustomer != null) ...[
                            const SizedBox(height: 12),

                            Container(
                              width: double.infinity,

                              padding: const EdgeInsets.all(14),

                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.10),

                                borderRadius: BorderRadius.circular(14),
                              ),

                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  /*
                                  |--------------------------------------------------------------------------
                                  | Customer Header
                                  |--------------------------------------------------------------------------
                                  */
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,

                                    children: [
                                      Expanded(
                                        child: Text(
                                          selectedCustomer!['name'] ?? '',

                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),

                                      /*
                                      |--------------------------------------------------------------------------
                                      | Clear Customer
                                      |--------------------------------------------------------------------------
                                      */
                                      TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            selectedCustomer = null;

                                            customerSearchController.clear();

                                            customerResults = [];
                                          });
                                        },

                                        icon: const Icon(
                                          Icons.clear,
                                          color: Colors.red,
                                        ),

                                        label: const Text(
                                          'Clear',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),

                                  /*
                                  |--------------------------------------------------------------------------
                                  | Customer Details
                                  |--------------------------------------------------------------------------
                                  */
                                  if (selectedCustomer!['phone'] != null)
                                    Text(
                                      'Phone: ${selectedCustomer!['phone']}',
                                    ),

                                  if (selectedCustomer!['brn'] != null)
                                    Text('BRN: ${selectedCustomer!['brn']}'),

                                  if (selectedCustomer!['vat_number'] != null)
                                    Text(
                                      'VAT: ${selectedCustomer!['vat_number']}',
                                    ),
                                ],
                              ),
                            ),
                          ],

                          if (customerResults.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 180,
                              child: ListView.separated(
                                itemCount: customerResults.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: Colors.grey.shade200,
                                ),
                                itemBuilder: (context, index) {
                                  final customer = customerResults[index];

                                  return ListTile(
                                    leading: const CircleAvatar(
                                      child: Icon(Icons.person),
                                    ),
                                    title: Text(customer['name'] ?? ''),
                                    subtitle: Text(
                                      '${customer['phone'] ?? ''} | BRN: ${customer['brn'] ?? '-'} | VAT: ${customer['vat_number'] ?? '-'}',
                                    ),
                                    onTap: () {
                                      selectCustomer(customer);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const Text(
                      'Add Item',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: productSearchController,

                          onChanged: (_) {
                            searchProducts();
                          },

                          decoration: InputDecoration(
                            labelText: 'Search product',

                            prefixIcon: const Icon(Icons.search),

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),

                        if (productResults.isNotEmpty) ...[
                          const SizedBox(height: 10),

                          Container(
                            height: 180,

                            decoration: BoxDecoration(
                              color: Colors.white,

                              borderRadius: BorderRadius.circular(14),

                              border: Border.all(color: Colors.grey.shade300),
                            ),

                            child: ListView.separated(
                              itemCount: productResults.length,

                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: Colors.grey.shade200,
                              ),

                              itemBuilder: (context, index) {
                                final product = productResults[index];

                                return ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.inventory_2),
                                  ),

                                  title: Text(product['name'] ?? ''),

                                  subtitle: Text(
                                    'Stock: ${product['stock_quantity'] ?? 0}',
                                  ),

                                  trailing: Text(
                                    formatMoney(
                                      toMoneyDouble(product['selling_price']),
                                    ),
                                  ),

                                  onTap: () {
                                    selectProduct(product);
                                  },
                                );
                              },
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        TextField(
                          controller: descriptionController,

                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: newItemBarcodeController,
                          decoration: const InputDecoration(
                            labelText: 'Barcode for new item',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        CheckboxListTile(
                          value: saveNewItemAsProduct,
                          title: const Text(
                            'Save this item as product for next time',
                          ),
                          onChanged: (value) {
                            setState(() {
                              saveNewItemAsProduct = value ?? true;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Unit Price Excl VAT',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: addItem,
                            icon: const Icon(Icons.add),
                            label: const Text('Add'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Invoice Summary',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Expanded(
                      child: items.isEmpty
                          ? const Center(child: Text('No items added'))
                          : ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];

                                return ListTile(
                                  title: Text(item['description']),

                                  subtitle: Text(
                                    '${item['quantity']} × ${formatMoney(toMoneyDouble(item['unit_price_excl_vat']))}',
                                  ),

                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        formatMoney(
                                          toMoneyDouble(
                                            item['line_total_incl_vat'],
                                          ),
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),

                                        onPressed: () {
                                          setState(() {
                                            items.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    const Divider(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal Excl VAT'),
                        Text(formatMoney(subtotal())),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('VAT'),
                        Text(formatMoney(vatTotal())),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          formatMoney(grandTotal()),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: amountTenderedController,
                      enabled: canEditAmountTendered(),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Amount Tendered',
                        border: const OutlineInputBorder(),
                        filled: !canEditAmountTendered(),
                        fillColor: Colors.grey.shade100,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Change Due'),
                        Text(
                          formatMoney(changeDue()),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      children: [
                        for (final key in [
                          '1',
                          '2',
                          '3',
                          '4',
                          '5',
                          '6',
                          '7',
                          '8',
                          '9',
                          '0',
                          '.',
                          'C',
                        ])
                          ElevatedButton(
                            onPressed: canEditAmountTendered()
                                ? () {
                                    if (key == 'C') {
                                      clearTendered();
                                    } else {
                                      appendTendered(key);
                                    }
                                  }
                                : null,
                            child: Text(key),
                          ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    const SizedBox(height: 18),

                    /*
                    |--------------------------------------------------------------------------
                    | Print Format
                    |--------------------------------------------------------------------------
                    */
                    DropdownButtonFormField<String>(
                      value: printFormat,

                      decoration: const InputDecoration(
                        labelText: 'Print Format',
                        border: OutlineInputBorder(),
                      ),

                      items: const [
                        DropdownMenuItem(
                          value: 'thermal',
                          child: Text('Thermal Receipt'),
                        ),

                        DropdownMenuItem(
                          value: 'a4',
                          child: Text('A4 Invoice'),
                        ),
                      ],

                      onChanged: (value) {
                        setState(() {
                          printFormat = value ?? 'thermal';
                        });
                      },
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : saveSale,
                        icon: const Icon(Icons.save),
                        label: Text(isSaving ? 'Saving...' : 'Save Sale'),
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
