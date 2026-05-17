import 'package:flutter/material.dart';

import '../services/api_service.dart';

import '../utils/money.dart';
import '../utils/discount.dart';

import 'receipt_screen.dart';

/*
|--------------------------------------------------------------------------
| Counter POS Screen
|--------------------------------------------------------------------------
| Fast-food / KFC-style POS workflow.
|
| Workflow:
| Select Items
| → Immediate Payment
| → Kitchen Receives Order
| → Receipt Preview
|
| No table numbers required.
*/

class CounterPosScreen extends StatefulWidget {
  const CounterPosScreen({super.key});

  @override
  State<CounterPosScreen> createState() =>
      _CounterPosScreenState();
}

class _CounterPosScreenState
    extends State<CounterPosScreen> {
  /*
  |--------------------------------------------------------------------------
  | API Service
  |--------------------------------------------------------------------------
  */

  final ApiService apiService = ApiService();

  /*
  |--------------------------------------------------------------------------
  | Data Collections
  |--------------------------------------------------------------------------
  */

  List categories = [];
  List products = [];

  /*
  |--------------------------------------------------------------------------
  | Cart
  |--------------------------------------------------------------------------
  */

  List<Map<String, dynamic>> cart = [];

  /*
  |--------------------------------------------------------------------------
  | Selected Category
  |--------------------------------------------------------------------------
  */

  int? selectedCategoryId;

  /*
  |--------------------------------------------------------------------------
  | Payment Configuration
  |--------------------------------------------------------------------------
  */

  String paymentMethod = 'cash';

  double discountPercentage = 0;

  /*
  |--------------------------------------------------------------------------
  | Loading State
  |--------------------------------------------------------------------------
  */

  bool isLoading = true;

  /*
  |--------------------------------------------------------------------------
  | Available Discounts
  |--------------------------------------------------------------------------
  */

  final List<double> discountOptions = [
    0,
    5,
    10,
    15,
    50,
    100,
  ];

  /*
  |--------------------------------------------------------------------------
  | Payment Methods
  |--------------------------------------------------------------------------
  */

  final List<String> paymentMethods = [
    'cash',
    'card',
    'juice',
    'cheque',
    'complimentary',
  ];

  @override
  void initState() {
    super.initState();

    loadData();
  }

  /*
  |--------------------------------------------------------------------------
  | Load Categories And Products
  |--------------------------------------------------------------------------
  */

  Future<void> loadData() async {
    try {
      final loadedCategories =
          await apiService.getCategories();

      final loadedProducts =
          await apiService.getProducts();

      setState(() {
        categories = loadedCategories;
        products = loadedProducts;

        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      setState(() {
        isLoading = false;
      });
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Filtered Products
  |--------------------------------------------------------------------------
  */

  List get filteredProducts {
    if (selectedCategoryId == null) {
      return products;
    }

    return products.where((product) {
      return product['product_category_id'] ==
          selectedCategoryId;
    }).toList();
  }

  /*
  |--------------------------------------------------------------------------
  | Add Product To Cart
  |--------------------------------------------------------------------------
  */

  void addToCart(dynamic product) {
    setState(() {
      final existingIndex = cart.indexWhere(
        (item) => item['id'] == product['id'],
      );

      if (existingIndex >= 0) {
        cart[existingIndex]['quantity'] += 1;
      } else {
        cart.add({
          'id': product['id'],
          'name': product['name'],
          'price': toMoneyDouble(product['selling_price'] ?? product['price'],),
          'quantity': 1,
        });
      }
    });
  }

  /*
  |--------------------------------------------------------------------------
  | Remove Product From Cart
  |--------------------------------------------------------------------------
  */

  void removeFromCart(int productId) {
    setState(() {
      final existingIndex = cart.indexWhere(
        (item) => item['id'] == productId,
      );

      if (existingIndex >= 0) {
        if (cart[existingIndex]['quantity'] > 1) {
          cart[existingIndex]['quantity'] -= 1;
        } else {
          cart.removeAt(existingIndex);
        }
      }
    });
  }

  /*
  |--------------------------------------------------------------------------
  | Calculate Subtotal
  |--------------------------------------------------------------------------
  */

  double subtotal() {
    double total = 0;

    for (final item in cart) {
      total +=
          item['quantity'] * toMoneyDouble(item['price']);
    }

    return total;
  }

  /*
  |--------------------------------------------------------------------------
  | Process Counter Payment
  |--------------------------------------------------------------------------
  */

  Future<void> processCounterPayment({
    required double subtotalAmount,
    required double discountAmount,
    required double vatIncluded,
    required double finalTotal,
  }) async {
    try {
      final result =
          await apiService.processCounterOrderPayment(
        items: cart,
        paymentMethod: paymentMethod,
        subtotal: subtotalAmount,
        taxAmount: vatIncluded,
        discountAmount: discountAmount,
        discountPercentage: discountPercentage,
        totalAmount: finalTotal,
      );

      if (!mounted) return;

      final order = result['order'];

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptScreen(
            order: order,
            paymentMethod: paymentMethod,
            subtotal: subtotalAmount,
            taxAmount: vatIncluded,
            discountAmount: discountAmount,
            totalAmount: finalTotal,
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    final subtotalAmount = subtotal();

    final discountAmount =
        calculateDiscountAmount(
      subtotal: subtotalAmount,
      discountPercentage: discountPercentage,
    );

    final finalTotal =
        calculateFinalTotal(
      subtotal: subtotalAmount,
      discountPercentage: discountPercentage,
    );

    final vatIncluded =
        calculateVatIncluded(finalTotal);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter POS'),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Row(
              children: [
                /*
                |--------------------------------------------------------------------------
                | LEFT SIDE
                | Categories + Product Grid
                |--------------------------------------------------------------------------
                */

                Expanded(
                  flex: 2,

                  child: Column(
                    children: [
                      /*
                      |--------------------------------------------------------------------------
                      | Categories
                      |--------------------------------------------------------------------------
                      */

                      SizedBox(
                        height: 70,

                        child: ListView(
                          scrollDirection: Axis.horizontal,

                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.all(8),

                              child: ChoiceChip(
                                label:
                                    const Text('All'),
                                selected:
                                    selectedCategoryId ==
                                        null,
                                onSelected: (_) {
                                  setState(() {
                                    selectedCategoryId =
                                        null;
                                  });
                                },
                              ),
                            ),

                            ...categories.map((category) {
                              return Padding(
                                padding:
                                    const EdgeInsets.all(
                                        8),

                                child: ChoiceChip(
                                  label: Text(
                                    category['name'],
                                  ),
                                  selected:
                                      selectedCategoryId ==
                                          category['id'],
                                  onSelected: (_) {
                                    setState(() {
                                      selectedCategoryId =
                                          category['id'];
                                    });
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                      /*
                      |--------------------------------------------------------------------------
                      | Product Grid
                      |--------------------------------------------------------------------------
                      */

                      Expanded(
                        child: GridView.builder(
                          padding:
                              const EdgeInsets.all(16),

                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 1.1,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),

                          itemCount:
                              filteredProducts.length,

                          itemBuilder: (context, index) {
                            final product =
                                filteredProducts[index];

                            return InkWell(
                              onTap: () {
                                addToCart(product);
                              },

                              child: Card(
                                elevation: 4,

                                child: Padding(
                                  padding:
                                      const EdgeInsets.all(
                                          12),

                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .center,

                                    children: [
                                      Text(
                                        product['name'],
                                        textAlign:
                                            TextAlign.center,
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),

                                      const SizedBox(
                                          height: 10),

                                      Text(
                                        formatMoney(
                                        product['selling_price'] ?? product['price'],
                                        ),
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.green,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                /*
                |--------------------------------------------------------------------------
                | RIGHT SIDE
                | Cart + Payment
                |--------------------------------------------------------------------------
                */

                Container(
                  width: 420,
                  color: Colors.white,

                  child: Padding(
                    padding:
                        const EdgeInsets.all(20),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        const Text(
                          'Cart',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        /*
                        |--------------------------------------------------------------------------
                        | Cart Listing
                        |--------------------------------------------------------------------------
                        */

                        Expanded(
                          child: ListView.builder(
                            itemCount: cart.length,

                            itemBuilder:
                                (context, index) {
                              final item =
                                  cart[index];

                              final lineTotal =
                                  item['quantity'] *
                                      item['price'];

                              return Card(
                                child: ListTile(
                                  title: Text(
                                      item['name']),

                                  subtitle: Text(
                                    '${item['quantity']} × ${formatMoney(item['price'])}',
                                  ),

                                  trailing: Row(
                                    mainAxisSize:
                                        MainAxisSize.min,

                                    children: [
                                      Text(
                                        formatMoney(
                                            lineTotal),
                                      ),

                                      IconButton(
                                        icon: const Icon(
                                          Icons
                                              .remove_circle,
                                          color:
                                              Colors.red,
                                        ),
                                        onPressed: () {
                                          removeFromCart(
                                            item['id'],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        /*
                        |--------------------------------------------------------------------------
                        | Discount Buttons
                        |--------------------------------------------------------------------------
                        */

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,

                          children:
                              discountOptions.map(
                            (discount) {
                              return ChoiceChip(
                                label: Text(
                                  '${discount.toStringAsFixed(0)}%',
                                ),
                                selected:
                                    discountPercentage ==
                                        discount,
                                onSelected: (_) {
                                  setState(() {
                                    discountPercentage =
                                        discount;

                                    if (discount ==
                                        100) {
                                      paymentMethod =
                                          'complimentary';
                                    }
                                  });
                                },
                              );
                            },
                          ).toList(),
                        ),

                        const SizedBox(height: 16),

                        /*
                        |--------------------------------------------------------------------------
                        | Payment Methods
                        |--------------------------------------------------------------------------
                        */

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,

                          children:
                              paymentMethods.map(
                            (method) {
                              return ChoiceChip(
                                label: Text(
                                  method
                                      .toUpperCase(),
                                ),
                                selected:
                                    paymentMethod ==
                                        method,
                                onSelected: (_) {
                                  setState(() {
                                    paymentMethod =
                                        method;

                                    if (method ==
                                        'complimentary') {
                                      discountPercentage =
                                          100;
                                    }
                                  });
                                },
                              );
                            },
                          ).toList(),
                        ),

                        const Divider(height: 32),

                        /*
                        |--------------------------------------------------------------------------
                        | Totals
                        |--------------------------------------------------------------------------
                        */

                        _SummaryRow(
                          label: 'Subtotal',
                          value: formatMoney(
                              subtotalAmount),
                        ),

                        _SummaryRow(
                          label:
                              'Discount (${discountPercentage.toStringAsFixed(0)}%)',
                          value:
                              '- ${formatMoney(discountAmount)}',
                        ),

                        _SummaryRow(
                          label: 'VAT Included',
                          value:
                              formatMoney(vatIncluded),
                        ),

                        const Divider(),

                        _SummaryRow(
                          label: 'TOTAL',
                          value:
                              formatMoney(finalTotal),
                          isBold: true,
                        ),

                        const SizedBox(height: 20),

                        /*
                        |--------------------------------------------------------------------------
                        | Pay Button
                        |--------------------------------------------------------------------------
                        */

                        SizedBox(
                          width: double.infinity,
                          height: 56,

                          child: ElevatedButton.icon(
                            onPressed: cart.isEmpty
                                ? null
                                : () {
                                    processCounterPayment(
                                      subtotalAmount:
                                          subtotalAmount,
                                      discountAmount:
                                          discountAmount,
                                      vatIncluded:
                                          vatIncluded,
                                      finalTotal:
                                          finalTotal,
                                    );
                                  },

                            icon: const Icon(
                              Icons.payments,
                            ),

                            label: Text(
                              paymentMethod ==
                                      'complimentary'
                                  ? 'SETTLE COMPLIMENTARY'
                                  : 'PAY & SEND',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/*
|--------------------------------------------------------------------------
| Summary Row Widget
|--------------------------------------------------------------------------
*/

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: isBold ? 22 : 16,
      fontWeight:
          isBold ? FontWeight.bold : FontWeight.normal,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}