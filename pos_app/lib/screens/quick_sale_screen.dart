import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/money.dart';

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
  final ApiService apiService = ApiService();

  String saleType = 'walk_in';
  String paymentMethod = 'cash';

  bool isSaving = false;

  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(text: '1');
  final TextEditingController priceController = TextEditingController();

  List<Map<String, dynamic>> items = [];

  @override
  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    priceController.dispose();
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
      items.add({
        'product_id': null,
        'description': description,
        'quantity': quantity,
        'unit_price_excl_vat': unitPrice,
        'vat_amount': vat,
        'line_total_incl_vat': totalInclVat,
      });

      descriptionController.clear();
      quantityController.text = '1';
      priceController.clear();
    });
  }

  Future<void> saveSale() async {
    if (items.isEmpty) {
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      await apiService.createQuickSale(
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

      setState(() {
        items.clear();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Quick Sale'),
      ),
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
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Add Item',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
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
                          ? const Center(
                              child: Text('No items added'),
                            )
                          : ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];

                                return ListTile(
                                  title: Text(item['description']),
                                  subtitle: Text(
                                    '${item['quantity']} × ${formatMoney(toMoneyDouble(item['unit_price_excl_vat']))}',
                                  ),
                                  trailing: Text(
                                    formatMoney(
                                      toMoneyDouble(item['line_total_incl_vat']),
                                    ),
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

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : saveSale,
                        icon: const Icon(Icons.save),
                        label: Text(
                          isSaving ? 'Saving...' : 'Save Sale',
                        ),
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