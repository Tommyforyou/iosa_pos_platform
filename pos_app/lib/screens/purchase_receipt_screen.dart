import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/money.dart';
import 'purchase_receipt_review_screen.dart';

/*
|--------------------------------------------------------------------------
| Purchase Receipt Screen
|--------------------------------------------------------------------------
| Purchase OCR management screen.
|
| Features:
| - multi-upload purchase receipts/invoices
| - run OCR
| - review/edit extracted purchase data
| - delete uploaded receipts
| - compact premium listing cards
*/

class PurchaseReceiptScreen extends StatefulWidget {
  const PurchaseReceiptScreen({super.key});

  @override
  State<PurchaseReceiptScreen> createState() => _PurchaseReceiptScreenState();
}

class _PurchaseReceiptScreenState extends State<PurchaseReceiptScreen> {
  /*
  |--------------------------------------------------------------------------
  | API Service
  |--------------------------------------------------------------------------
  */

  final ApiService apiService = ApiService();

  /*
  |--------------------------------------------------------------------------
  | Receipts
  |--------------------------------------------------------------------------
  */

  List<dynamic> receipts = [];

  /*
  |--------------------------------------------------------------------------
  | Loading States
  |--------------------------------------------------------------------------
  */

  bool isLoading = true;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    loadReceipts();
  }

  /*
  |--------------------------------------------------------------------------
  | Load Receipts
  |--------------------------------------------------------------------------
  */

  Future<void> loadReceipts() async {
    try {
      final result = await apiService.getPurchaseReceipts();

      if (!mounted) return;

      setState(() {
        receipts = result;
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
  | Upload Multiple Receipts
  |--------------------------------------------------------------------------
  */

  Future<void> uploadReceipt() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      setState(() {
        isUploading = true;
      });

      int uploadedCount = 0;

      for (final file in result.files) {
        if (file.path == null) {
          continue;
        }

        await apiService.uploadPurchaseReceipt(filePath: file.path!);

        uploadedCount++;
      }

      await loadReceipts();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$uploadedCount receipt(s) uploaded successfully')));
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (!mounted) return;

      setState(() {
        isUploading = false;
      });
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Run OCR
  |--------------------------------------------------------------------------
  */

  Future<void> runOcr(dynamic receipt) async {
    try {
      await apiService.runPurchaseReceiptOcr(receiptId: receipt['id']);

      await loadReceipts();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OCR processing completed')));
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Delete Receipt
  |--------------------------------------------------------------------------
  */

  Future<void> deleteReceipt(dynamic receipt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete purchase receipt?'),
          content: const Text('This will remove the uploaded document and purchase receipt record.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.delete),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await apiService.deletePurchaseReceipt(receiptId: receipt['id']);

      await loadReceipts();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase receipt deleted')));
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Open Review Screen
  |--------------------------------------------------------------------------
  */

  Future<void> openReview(dynamic receipt) async {
    final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => PurchaseReceiptReviewScreen(receipt: receipt)));

    if (updated == true) {
      loadReceipts();
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Status Color
  |--------------------------------------------------------------------------
  */

  Color statusColor(String status) {
    switch (status) {
      case 'pending_ocr':
        return Colors.orange;

      case 'pending_review':
        return Colors.blue;

      case 'reviewed':
        return Colors.green;

      default:
        return Colors.grey;
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Status Label
  |--------------------------------------------------------------------------
  */

  String statusLabel(String status) {
    switch (status) {
      case 'pending_ocr':
        return 'Pending OCR';

      case 'pending_review':
        return 'Pending Review';

      case 'reviewed':
        return 'Reviewed';

      default:
        return status.toUpperCase();
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Summary Counts
  |--------------------------------------------------------------------------
  */

  int countByStatus(String status) {
    return receipts.where((receipt) {
      return receipt['status'] == status;
    }).length;
  }

  /*
  |--------------------------------------------------------------------------
  | Header Stat Card
  |--------------------------------------------------------------------------
  */

  Widget statCard({required String title, required String value, required IconData icon, required Color color}) {
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
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(title, style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Info Item
  |--------------------------------------------------------------------------
  */

  Widget infoItem({required String label, required String value, IconData? icon}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 16, color: Colors.grey.shade600), const SizedBox(width: 5)],
        Text('$label: ', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Convert Receipt To Purchase
  |--------------------------------------------------------------------------
  */

  Future<void> showConvertPurchaseDialog(Map<String, dynamic> receipt) async {
    String paymentStatus = 'paid';

    await showDialog(
      context: context,

      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Convert To Purchase'),

              content: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  const Text('Payment Type'),

                  const SizedBox(height: 12),

                  RadioListTile<String>(
                    title: const Text('Paid Purchase'),

                    value: 'paid',

                    groupValue: paymentStatus,

                    onChanged: (value) {
                      setDialogState(() {
                        paymentStatus = value!;
                      });
                    },
                  ),

                  RadioListTile<String>(
                    title: const Text('Credit Purchase'),

                    value: 'unpaid',

                    groupValue: paymentStatus,

                    onChanged: (value) {
                      setDialogState(() {
                        paymentStatus = value!;
                      });
                    },
                  ),
                ],
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
                      await apiService.convertPurchaseReceiptToPurchase(receiptId: receipt['id'], paymentStatus: paymentStatus);

                      if (!mounted) return;

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase converted successfully.')));

                      loadReceipts();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                    }
                  },

                  icon: const Icon(Icons.check),

                  label: const Text('Convert'),
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
  | Receipt Card
  |--------------------------------------------------------------------------
  */

  Widget receiptCard(dynamic receipt) {
    final status = receipt['status'] ?? 'unknown';

    final supplier = receipt['supplier_name'] ?? 'Unknown Supplier';

    final invoiceNumber = receipt['invoice_number'] ?? '-';

    final invoiceDate = receipt['invoice_date'] ?? '-';

    final brn = receipt['supplier_brn'] ?? '-';

    final vatNumber = receipt['supplier_vat_number'] ?? '-';

    final subtotal = toMoneyDouble(receipt['subtotal_excl_vat']);

    final vatAmount = toMoneyDouble(receipt['vat_amount']);

    final total = toMoneyDouble(receipt['total_incl_vat']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          | Document Icon
          |--------------------------------------------------------------------------
          */
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: statusColor(status).withOpacity(0.12), borderRadius: BorderRadius.circular(18)),
            child: Icon(Icons.receipt_long, color: statusColor(status), size: 28),
          ),

          const SizedBox(width: 14),

          /*
          |--------------------------------------------------------------------------
          | Main Receipt Information
          |--------------------------------------------------------------------------
          */
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /*
                |--------------------------------------------------------------------------
                | Supplier And Status
                |--------------------------------------------------------------------------
                */
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        supplier,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: statusColor(status).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        statusLabel(status),
                        style: TextStyle(color: statusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                /*
                |--------------------------------------------------------------------------
                | Meta Information
                |--------------------------------------------------------------------------
                */
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    infoItem(label: 'Invoice', value: invoiceNumber, icon: Icons.tag),
                    infoItem(label: 'Date', value: invoiceDate, icon: Icons.calendar_month),
                    infoItem(label: 'BRN', value: brn, icon: Icons.badge),
                    infoItem(label: 'VAT No', value: vatNumber, icon: Icons.confirmation_number),
                  ],
                ),

                const SizedBox(height: 10),

                /*
                |--------------------------------------------------------------------------
                | Financial Summary
                |--------------------------------------------------------------------------
                */
                Row(
                  children: [
                    _AmountChip(label: 'Subtotal', value: formatMoney(subtotal)),
                    const SizedBox(width: 8),
                    _AmountChip(label: 'VAT', value: formatMoney(vatAmount)),
                    const SizedBox(width: 8),
                    _AmountChip(label: 'Total', value: formatMoney(total), isStrong: true),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          /*
          |--------------------------------------------------------------------------
          | Actions
          |--------------------------------------------------------------------------
          */
          Column(
            children: [
              if (status == 'pending_ocr')
                ElevatedButton.icon(
                  onPressed: () {
                    runOcr(receipt);
                  },
                  icon: const Icon(Icons.document_scanner),
                  label: const Text('Run OCR'),
                ),

              if (status == 'pending_review' || status == 'reviewed')
                /*
                |--------------------------------------------------------------------------
                | Convert To Purchase
                |--------------------------------------------------------------------------
                */
                if (status == 'reviewed' && receipt['converted_purchase_id'] == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),

                      onPressed: () {
                        showConvertPurchaseDialog(receipt);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Convert To Purchase'),
                    ),
                  ),
              ElevatedButton.icon(
                onPressed: () {
                  openReview(receipt);
                },
                icon: Icon(status == 'reviewed' ? Icons.edit : Icons.fact_check),
                label: Text(status == 'reviewed' ? 'Edit' : 'Review'),
              ),

              const SizedBox(height: 6),

              TextButton.icon(
                onPressed: () {
                  deleteReceipt(receipt);
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
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
    final totalCount = receipts.length.toString();
    final pendingOcrCount = countByStatus('pending_ocr').toString();
    final pendingReviewCount = countByStatus('pending_review').toString();
    final reviewedCount = countByStatus('reviewed').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: Column(
          children: [
            /*
            |--------------------------------------------------------------------------
            | Top Header
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
                  const Icon(Icons.document_scanner, size: 32, color: Colors.blue),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Purchase Receipt OCR', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                        SizedBox(height: 3),
                        Text('Upload, OCR, review and manage supplier purchase receipts.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(onPressed: loadReceipts, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: isUploading ? null : uploadReceipt,
                    icon: isUploading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.upload_file),
                    label: Text(isUploading ? 'Uploading...' : 'Upload Receipts'),
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
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          /*
                          |--------------------------------------------------------------------------
                          | Summary Cards
                          |--------------------------------------------------------------------------
                          */
                          Row(
                            children: [
                              statCard(title: 'Total Receipts', value: totalCount, icon: Icons.receipt_long, color: Colors.blue),
                              const SizedBox(width: 14),
                              statCard(title: 'Pending OCR', value: pendingOcrCount, icon: Icons.document_scanner, color: Colors.orange),
                              const SizedBox(width: 14),
                              statCard(title: 'Pending Review', value: pendingReviewCount, icon: Icons.fact_check, color: Colors.purple),
                              const SizedBox(width: 14),
                              statCard(title: 'Reviewed', value: reviewedCount, icon: Icons.verified, color: Colors.green),
                            ],
                          ),

                          const SizedBox(height: 20),

                          /*
                          |--------------------------------------------------------------------------
                          | Receipt List
                          |--------------------------------------------------------------------------
                          */
                          Expanded(
                            child: receipts.isEmpty
                                ? Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(30),
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                                      child: const Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.upload_file, size: 54, color: Colors.grey),
                                          SizedBox(height: 12),
                                          Text('No purchase receipts uploaded yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                          SizedBox(height: 6),
                                          Text('Click Upload Receipts to start scanning supplier invoices.', style: TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: receipts.length,
                                    itemBuilder: (context, index) {
                                      final receipt = receipts[index];

                                      return receiptCard(receipt);
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
| Amount Chip
|--------------------------------------------------------------------------
*/

class _AmountChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isStrong;

  const _AmountChip({required this.label, required this.value, this.isStrong = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isStrong ? Colors.green.withOpacity(0.10) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isStrong ? Colors.green.withOpacity(0.25) : Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
            const SizedBox(height: 3),
            Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.bold, color: isStrong ? Colors.green.shade700 : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
