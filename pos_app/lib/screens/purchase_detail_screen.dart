import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/money.dart';

/*
|--------------------------------------------------------------------------
| Purchase Detail Screen
|--------------------------------------------------------------------------
| Shows full purchase transaction details.
*/

class PurchaseDetailScreen extends StatefulWidget {
  final int purchaseId;

  const PurchaseDetailScreen({
    super.key,
    required this.purchaseId,
  });

  @override
  State<PurchaseDetailScreen> createState() =>
      _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState
    extends State<PurchaseDetailScreen> {
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

  bool isLoading = true;

  Map<String, dynamic>? purchase;

  @override
  void initState() {
    super.initState();

    loadPurchase();
  }

  /*
  |--------------------------------------------------------------------------
  | Load Purchase
  |--------------------------------------------------------------------------
  */

  Future<void> loadPurchase() async {
    try {
      final result =
          await apiService.getPurchaseDetail(
        purchaseId: widget.purchaseId,
      );

      if (!mounted) return;

      setState(() {
        purchase = result;
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
  | Info Tile
  |--------------------------------------------------------------------------
  */

  Widget infoTile({
    required String label,
    required String value,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: Colors.blueGrey,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
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
  | Amount Card
  |--------------------------------------------------------------------------
  */

  Widget amountCard({
    required String title,
    required double amount,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withOpacity(0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatMoney(amount),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
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
    final supplier =
        purchase?['supplier'];

    final items =
        purchase?['items'] ?? [];

    final receipt =
        purchase?['receipt'];

    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F6FA),

      appBar: AppBar(
        title: const Text(
          'Purchase Detail',
        ),
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )

          : purchase == null
              ? const Center(
                  child: Text(
                    'Purchase not found',
                  ),
                )

              : Padding(
                  padding:
                      const EdgeInsets.all(22),

                  child: Column(
                    children: [

                      /*
                      |--------------------------------------------------------------------------
                      | Top Summary
                      |--------------------------------------------------------------------------
                      */

                      Row(
                        children: [

                          /*
                          |--------------------------------------------------------------------------
                          | Supplier Card
                          |--------------------------------------------------------------------------
                          */

                          Expanded(
                            flex: 2,

                            child: Container(
                              padding:
                                  const EdgeInsets
                                      .all(22),

                              decoration:
                                  BoxDecoration(
                                color:
                                    Colors.white,

                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            24),

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors
                                        .black
                                        .withOpacity(
                                            0.04),

                                    blurRadius:
                                        12,

                                    offset:
                                        const Offset(
                                            0,
                                            4),
                                  ),
                                ],
                              ),

                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [

                                  Row(
                                    children: [
                                      Container(
                                        width:
                                            54,
                                        height:
                                            54,

                                        decoration:
                                            BoxDecoration(
                                          color: Colors
                                              .blue
                                              .withOpacity(
                                                  0.12),

                                          borderRadius:
                                              BorderRadius.circular(
                                                  18),
                                        ),

                                        child:
                                            const Icon(
                                          Icons
                                              .business,

                                          color:
                                              Colors
                                                  .blue,
                                        ),
                                      ),

                                      const SizedBox(
                                          width:
                                              14),

                                      Expanded(
                                        child:
                                            Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,

                                          children: [

                                            Text(
                                              supplier?[
                                                      'name'] ??
                                                  'Unknown Supplier',

                                              style:
                                                  const TextStyle(
                                                fontSize:
                                                    22,

                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),

                                            const SizedBox(
                                                height:
                                                    4),

                                            Text(
                                              'Supplier Information',

                                              style:
                                                  TextStyle(
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                      height:
                                          20),

                                  Row(
                                    children: [

                                      Expanded(
                                        child:
                                            infoTile(
                                          label:
                                              'BRN',

                                          value:
                                              supplier?['brn'] ??
                                                  '-',

                                          icon:
                                              Icons.badge,
                                        ),
                                      ),

                                      const SizedBox(
                                          width:
                                              12),

                                      Expanded(
                                        child:
                                            infoTile(
                                          label:
                                              'VAT No',

                                          value:
                                              supplier?['vat_number'] ??
                                                  '-',

                                          icon:
                                              Icons.confirmation_number,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                      height:
                                          12),

                                  Row(
                                    children: [

                                      Expanded(
                                        child:
                                            infoTile(
                                          label:
                                              'Invoice Number',

                                          value:
                                              purchase?['invoice_number'] ??
                                                  '-',

                                          icon:
                                              Icons.tag,
                                        ),
                                      ),

                                      const SizedBox(
                                          width:
                                              12),

                                      Expanded(
                                        child:
                                            infoTile(
                                          label:
                                              'Invoice Date',

                                          value:
                                              purchase?['invoice_date'] ??
                                                  '-',

                                          icon:
                                              Icons.calendar_month,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(
                              width: 18),

                          /*
                          |--------------------------------------------------------------------------
                          | OCR Receipt Preview
                          |--------------------------------------------------------------------------
                          */

                          Expanded(
                            child: Container(
                              padding:
                                  const EdgeInsets
                                      .all(18),

                              decoration:
                                  BoxDecoration(
                                color:
                                    Colors.white,

                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            24),

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors
                                        .black
                                        .withOpacity(
                                            0.04),

                                    blurRadius:
                                        12,

                                    offset:
                                        const Offset(
                                            0,
                                            4),
                                  ),
                                ],
                              ),

                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [

                                  const Text(
                                    'Source OCR Receipt',

                                    style:
                                        TextStyle(
                                      fontSize:
                                          18,

                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(
                                      height:
                                          16),

                                  Expanded(
                                    child:
                                        receipt?[
                                                    'document_url'] ==
                                                null

                                            ? const Center(
                                                child:
                                                    Text(
                                                  'No preview available',
                                                ),
                                              )

                                            : ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        18),

                                                child:
                                                    Image.network(
                                                  receipt[
                                                      'document_url'],

                                                  fit:
                                                      BoxFit.contain,
                                                ),
                                              ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                          height: 18),

                      /*
                      |--------------------------------------------------------------------------
                      | Financial Summary
                      |--------------------------------------------------------------------------
                      */

                      Row(
                        children: [

                          amountCard(
                            title:
                                'Subtotal Excl VAT',

                            amount:
                                toMoneyDouble(
                              purchase?[
                                  'subtotal_excl_vat'],
                            ),

                            color:
                                Colors.indigo,
                          ),

                          const SizedBox(
                              width: 14),

                          amountCard(
                            title:
                                'VAT Input',

                            amount:
                                toMoneyDouble(
                              purchase?[
                                  'vat_amount'],
                            ),

                            color:
                                Colors.orange,
                          ),

                          const SizedBox(
                              width: 14),

                          amountCard(
                            title:
                                'Total Purchase',

                            amount:
                                toMoneyDouble(
                              purchase?[
                                  'total_incl_vat'],
                            ),

                            color:
                                Colors.green,
                          ),
                        ],
                      ),

                      const SizedBox(
                          height: 18),

                      /*
                      |--------------------------------------------------------------------------
                      | Purchase Items
                      |--------------------------------------------------------------------------
                      */

                      Expanded(
                        child: Container(
                          padding:
                              const EdgeInsets
                                  .all(18),

                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white,

                            borderRadius:
                                BorderRadius
                                    .circular(
                                        24),

                            boxShadow: [
                              BoxShadow(
                                color: Colors
                                    .black
                                    .withOpacity(
                                        0.04),

                                blurRadius:
                                    12,

                                offset:
                                    const Offset(
                                        0,
                                        4),
                              ),
                            ],
                          ),

                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [

                              const Text(
                                'Purchase Items',

                                style:
                                    TextStyle(
                                  fontSize:
                                      20,

                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                  height:
                                      18),

                              Expanded(
                                child: items
                                        .isEmpty

                                    ? const Center(
                                        child:
                                            Text(
                                          'No purchase items found',
                                        ),
                                      )

                                    : ListView
                                        .builder(
                                        itemCount:
                                            items
                                                .length,

                                        itemBuilder:
                                            (
                                          context,
                                          index,
                                        ) {
                                          final item =
                                              items[
                                                  index];

                                          return Container(
                                            margin:
                                                const EdgeInsets.only(
                                              bottom:
                                                  10,
                                            ),

                                            padding:
                                                const EdgeInsets.all(
                                              14,
                                            ),

                                            decoration:
                                                BoxDecoration(
                                              color:
                                                  Colors.grey.shade100,

                                              borderRadius:
                                                  BorderRadius.circular(
                                                      18),
                                            ),

                                            child:
                                                Row(
                                              children: [

                                                Expanded(
                                                  child:
                                                      Text(
                                                    item['description'] ??
                                                        '-',

                                                    style:
                                                        const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),

                                                Text(
                                                  'Qty: ${item['quantity']}',
                                                ),

                                                const SizedBox(
                                                    width:
                                                        18),

                                                Text(
                                                  formatMoney(
                                                    toMoneyDouble(
                                                      item['line_total'],
                                                    ),
                                                  ),

                                                  style:
                                                      const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
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