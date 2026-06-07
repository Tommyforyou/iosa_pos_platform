import 'package:flutter/material.dart';

import '../services/api_service.dart';

/*
|--------------------------------------------------------------------------
| Purchase Receipt Review Screen
|--------------------------------------------------------------------------
| Enterprise-style OCR review screen.
|
| Layout:
| - Left side: invoice/receipt preview
| - Right side: editable OCR review form
|
| Purpose:
| - compare scanned document with extracted data
| - correct OCR mistakes
| - save reviewed purchase receipt
*/

class PurchaseReceiptReviewScreen extends StatefulWidget {
  final Map<String, dynamic> receipt;

  const PurchaseReceiptReviewScreen({super.key, required this.receipt});

  @override
  State<PurchaseReceiptReviewScreen> createState() =>
      _PurchaseReceiptReviewScreenState();
}

class _PurchaseReceiptReviewScreenState
    extends State<PurchaseReceiptReviewScreen> {
  /*
  |--------------------------------------------------------------------------
  | API Service
  |--------------------------------------------------------------------------
  */

  final ApiService apiService = ApiService();
  List<dynamic> receiptLines = [];

  /*
  |--------------------------------------------------------------------------
  | Controllers
  |--------------------------------------------------------------------------
  */

  late final TextEditingController supplierNameController;
  late final TextEditingController brnController;
  late final TextEditingController vatNumberController;
  late final TextEditingController invoiceNumberController;
  late final TextEditingController invoiceDateController;
  late final TextEditingController subtotalController;
  late final TextEditingController vatAmountController;
  late final TextEditingController totalController;

  /*
  |--------------------------------------------------------------------------
  | State
  |--------------------------------------------------------------------------
  */

  bool isSaving = false;

  /*
  |--------------------------------------------------------------------------
  | Init
  |--------------------------------------------------------------------------
  */

  @override
  void initState() {
    super.initState();

    supplierNameController = TextEditingController(
      text: widget.receipt['supplier_name'] ?? '',
    );

    brnController = TextEditingController(
      text: widget.receipt['supplier_brn'] ?? '',
    );

    vatNumberController = TextEditingController(
      text: widget.receipt['supplier_vat_number'] ?? '',
    );

    invoiceNumberController = TextEditingController(
      text: widget.receipt['invoice_number'] ?? '',
    );

    invoiceDateController = TextEditingController(
      text: widget.receipt['invoice_date'] ?? '',
    );

    subtotalController = TextEditingController(
      text: widget.receipt['subtotal_excl_vat']?.toString() ?? '0',
    );

    vatAmountController = TextEditingController(
      text: widget.receipt['vat_amount']?.toString() ?? '0',
    );

    totalController = TextEditingController(
      text: widget.receipt['total_incl_vat']?.toString() ?? '0',
    );
    loadReceiptLines();
  }

  Future<void> loadReceiptLines() async {
    try {
      final lines = widget.receipt['lines'];

      if (lines != null) {
        setState(() {
          receiptLines = lines;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Dispose
  |--------------------------------------------------------------------------
  */

  @override
  void dispose() {
    supplierNameController.dispose();
    brnController.dispose();
    vatNumberController.dispose();
    invoiceNumberController.dispose();
    invoiceDateController.dispose();
    subtotalController.dispose();
    vatAmountController.dispose();
    totalController.dispose();

    super.dispose();
  }

  /*
  |--------------------------------------------------------------------------
  | OCR Difference
  |--------------------------------------------------------------------------
  */

  double get ocrDifference {
    final subtotal = double.tryParse(subtotalController.text.trim()) ?? 0;

    return subtotal - ocrLinesTotal;
  }

  /*
  |--------------------------------------------------------------------------
  | OCR Line Total
  |--------------------------------------------------------------------------
  */

  double get ocrLinesTotal {
    double total = 0;

    for (final line in receiptLines) {
      total += double.tryParse(line['line_total'].toString()) ?? 0;
    }

    return total;
  }

  /*
  |--------------------------------------------------------------------------
  | Save Review
  |--------------------------------------------------------------------------
  */

  Future<void> saveReview() async {
    try {
      setState(() {
        isSaving = true;
      });

      await apiService.updatePurchaseReceipt(
        receiptId: widget.receipt['id'],
        supplierName: supplierNameController.text.trim(),
        supplierBrn: brnController.text.trim(),
        supplierVatNumber: vatNumberController.text.trim(),
        invoiceNumber: invoiceNumberController.text.trim(),
        invoiceDate: invoiceDateController.text.trim(),
        subtotalExclVat: double.tryParse(subtotalController.text.trim()) ?? 0,
        vatAmount: double.tryParse(vatAmountController.text.trim()) ?? 0,
        totalInclVat: double.tryParse(totalController.text.trim()) ?? 0,
        status: 'reviewed',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase receipt reviewed successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Input Field Helper
  |--------------------------------------------------------------------------
  */

  Widget inputField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon == null ? null : Icon(icon),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Section Header
  |--------------------------------------------------------------------------
  */

  Widget sectionHeader({required String title, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Invoice Preview
  |--------------------------------------------------------------------------
  */

  Widget invoicePreview() {
    final documentUrl = widget.receipt['document_url'];

    return Container(
      color: const Color(0xFF111827),
      child: Column(
        children: [
          /*
          |--------------------------------------------------------------------------
          | Preview Header
          |--------------------------------------------------------------------------
          */
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: const BoxDecoration(color: Color(0xFF1F2937)),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.white),
                const SizedBox(width: 10),
                const Text(
                  'Invoice Preview',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  widget.receipt['document_path'] ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          /*
          |--------------------------------------------------------------------------
          | Preview Body
          |--------------------------------------------------------------------------
          */
          Expanded(
            child: documentUrl == null || documentUrl.toString().isEmpty
                ? const Center(
                    child: Text(
                      'No invoice preview available',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4,
                    child: Center(
                      child: Image.network(
                        documentUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text(
                              'Unable to preview invoice.\nPDF preview will be added later.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /*
|--------------------------------------------------------------------------
| Show Line Dialog
|--------------------------------------------------------------------------
*/

  Future<void> showLineDialog({Map<String, dynamic>? line}) async {
    final descriptionController = TextEditingController(
      text: line?['description'] ?? '',
    );

    final quantityController = TextEditingController(
      text: line?['quantity']?.toString() ?? '1',
    );

    final unitPriceController = TextEditingController(
      text: line?['unit_price']?.toString() ?? '0',
    );

    final lineTotalController = TextEditingController();
    /*
    |--------------------------------------------------------------------------
    | Auto Calculate Line Total
    |--------------------------------------------------------------------------
    */
    void recalculateTotal() {
      final qty = double.tryParse(quantityController.text.trim()) ?? 0;

      final unitPrice = double.tryParse(unitPriceController.text.trim()) ?? 0;

      lineTotalController.text = (qty * unitPrice).toStringAsFixed(2);
    }

    quantityController.addListener(recalculateTotal);
    unitPriceController.addListener(recalculateTotal);

    recalculateTotal();

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(line == null ? 'Add OCR Line' : 'Edit OCR Line'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                inputField(
                  label: 'Description',
                  controller: descriptionController,
                ),
                Row(
                  children: [
                    Expanded(
                      child: inputField(
                        label: 'Quantity',
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: inputField(
                        label: 'Unit Price',
                        controller: unitPriceController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: lineTotalController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Line Total',
                    prefixIcon: const Icon(Icons.calculate),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final description = descriptionController.text.trim();

                final quantity =
                    double.tryParse(quantityController.text.trim()) ?? 0;

                final unitPrice =
                    double.tryParse(unitPriceController.text.trim()) ?? 0;

                final lineTotal =
                    double.tryParse(lineTotalController.text.trim()) ?? 0;

                if (description.isEmpty || quantity <= 0) {
                  return;
                }

                if (line == null) {
                  final result = await apiService.addPurchaseReceiptLine(
                    receiptId: widget.receipt['id'],
                    description: description,
                    quantity: quantity,
                    unitPrice: unitPrice,
                    lineTotal: lineTotal,
                  );

                  setState(() {
                    receiptLines.add(result['line']);
                  });
                } else {
                  final result = await apiService.updatePurchaseReceiptLine(
                    lineId: line['id'],
                    description: description,
                    quantity: quantity,
                    unitPrice: unitPrice,
                    lineTotal: lineTotal,
                  );

                  setState(() {
                    final index = receiptLines.indexWhere(
                      (item) => item['id'] == line['id'],
                    );

                    if (index >= 0) {
                      receiptLines[index] = result['line'];
                    }
                  });
                }

                if (!mounted) return;

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  /*
|--------------------------------------------------------------------------
| Delete Receipt Line
|--------------------------------------------------------------------------
*/

  Future<void> deleteReceiptLine(Map<String, dynamic> line) async {
    await apiService.deletePurchaseReceiptLine(line['id']);

    setState(() {
      receiptLines.removeWhere((item) => item['id'] == line['id']);
    });
  }
  /*
  |--------------------------------------------------------------------------
  | Review Form
  |--------------------------------------------------------------------------
  */

  Widget reviewForm() {
    return Container(
      width: 540,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          /*
          |--------------------------------------------------------------------------
          | Form Header
          |--------------------------------------------------------------------------
          */
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Icon(Icons.fact_check, size: 30, color: Colors.blue),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OCR Review',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Verify extracted invoice fields before saving.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /*
          |--------------------------------------------------------------------------
          | Form Body
          |--------------------------------------------------------------------------
          */
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /*
                  |--------------------------------------------------------------------------
                  | Supplier Information
                  |--------------------------------------------------------------------------
                  */
                  sectionHeader(
                    title: 'Supplier Information',
                    icon: Icons.store,
                  ),

                  inputField(
                    label: 'Supplier Name',
                    controller: supplierNameController,
                    icon: Icons.business,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: inputField(
                          label: 'Supplier BRN',
                          controller: brnController,
                          icon: Icons.badge,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: inputField(
                          label: 'Supplier VAT Number',
                          controller: vatNumberController,
                          icon: Icons.confirmation_number,
                        ),
                      ),
                    ],
                  ),

                  /*
                  |--------------------------------------------------------------------------
                  | Invoice Information
                  |--------------------------------------------------------------------------
                  */
                  sectionHeader(
                    title: 'Invoice Information',
                    icon: Icons.description,
                  ),

                  inputField(
                    label: 'Invoice Number',
                    controller: invoiceNumberController,
                    icon: Icons.numbers,
                  ),

                  inputField(
                    label: 'Invoice Date YYYY-MM-DD',
                    controller: invoiceDateController,
                    icon: Icons.calendar_month,
                  ),

                  /*
                  |--------------------------------------------------------------------------
                  | Amount Information
                  |--------------------------------------------------------------------------
                  */
                  sectionHeader(
                    title: 'Amount Information',
                    icon: Icons.payments,
                  ),

                  inputField(
                    label: 'Subtotal Excl VAT',
                    controller: subtotalController,
                    keyboardType: TextInputType.number,
                    icon: Icons.remove_circle_outline,
                  ),

                  inputField(
                    label: 'VAT Amount',
                    controller: vatAmountController,
                    keyboardType: TextInputType.number,
                    icon: Icons.percent,
                  ),

                  inputField(
                    label: 'Total Incl VAT',
                    controller: totalController,
                    keyboardType: TextInputType.number,
                    icon: Icons.add_circle_outline,
                  ),

                  /*
                  |--------------------------------------------------------------------------
                  | OCR Detected Items
                  |--------------------------------------------------------------------------
                  */
                  sectionHeader(
                    title: 'OCR Detected Items',
                    icon: Icons.inventory_2,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: sectionHeader(
                          title: 'OCR Detected Items',
                          icon: Icons.inventory_2,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Line'),
                        onPressed: () => showLineDialog(),
                      ),
                    ],
                  ),

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: receiptLines.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No line items detected.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : Column(
                            children: [
                              for (final line in receiptLines)
                                ListTile(
                                  leading: const Icon(Icons.shopping_cart),
                                  title: Text(
                                    line['description'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Qty: ${line['quantity']} × Rs ${line['unit_price']}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Rs ${line['line_total']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () =>
                                            showLineDialog(line: line),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            deleteReceiptLine(line),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  ),

                  /*
|--------------------------------------------------------------------------
| OCR Validation
|--------------------------------------------------------------------------
*/
                  const SizedBox(height: 16),

                  sectionHeader(title: 'OCR Validation', icon: Icons.verified),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ocrDifference.abs() < 0.01
                          ? Colors.green.shade50
                          : Colors.orange.shade50,

                      border: Border.all(
                        color: ocrDifference.abs() < 0.01
                            ? Colors.green
                            : Colors.orange,
                      ),

                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OCR Lines Total: Rs ${ocrLinesTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 6),

                        Text('Invoice Subtotal: Rs ${subtotalController.text}'),

                        const SizedBox(height: 6),

                        Text(
                          'Difference: Rs ${ocrDifference.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: ocrDifference.abs() < 0.01
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          /*
          |--------------------------------------------------------------------------
          | Footer Actions
          |--------------------------------------------------------------------------
          */
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : saveReview,
                    icon: const Icon(Icons.save),
                    label: Text(
                      isSaving ? 'Saving...' : 'Save & Mark Reviewed',
                    ),
                  ),
                ),
              ],
            ),
          ),
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

      /*
      |--------------------------------------------------------------------------
      | App Bar
      |--------------------------------------------------------------------------
      */
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Review Purchase Receipt'),
            Text(
              widget.receipt['supplier_name'] ??
                  'Verify and correct extracted data',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),

      /*
      |--------------------------------------------------------------------------
      | Main Layout
      |--------------------------------------------------------------------------
      */
      body: Row(
        children: [
          Expanded(flex: 2, child: invoicePreview()),
          reviewForm(),
        ],
      ),
    );
  }
}
