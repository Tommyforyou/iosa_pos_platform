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

  bool saveNewItemAsProduct = true;

  Map<String, dynamic>? selectedProduct;

  List<dynamic> productResults = [];

  final TextEditingController productSearchController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController priceController = TextEditingController();

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
        'product_id': selectedProduct?['id'],
        'description': description,
        'quantity': quantity,
        'unit_price_excl_vat': unitPrice,
        'vat_amount': vat,
        'line_total_incl_vat': totalInclVat,
        'save_as_product': selectedProduct == null && saveNewItemAsProduct,
      });

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

      await apiService.createQuickSale(
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
                                onPressed: () {},
                                icon: const Icon(Icons.person_add),
                                label: const Text('New Customer'),
                              ),
                            ],
                          ),

                          if (selectedCustomer != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                '${selectedCustomer!['name'] ?? ''} | BRN: ${selectedCustomer!['brn'] ?? '-'} | VAT: ${selectedCustomer!['vat_number'] ?? '-'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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
