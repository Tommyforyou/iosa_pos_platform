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
