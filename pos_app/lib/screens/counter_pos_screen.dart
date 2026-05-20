import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/money.dart';
import '../widgets/counter_payment_dialog.dart';

import 'receipt_screen.dart';

/*
|--------------------------------------------------------------------------
| Counter POS Screen
|--------------------------------------------------------------------------
| Premium touchscreen counter POS.
|
| Main screen:
| - category navigation
| - product grid
| - scrollable cart
| - total
| - large PAY button
|
| Payment details are handled by CounterPaymentDialog.
*/

class CounterPosScreen extends StatefulWidget {
  const CounterPosScreen({super.key});

  @override
  State<CounterPosScreen> createState() => _CounterPosScreenState();
}

class _CounterPosScreenState extends State<CounterPosScreen> {
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

  List<dynamic> categories = [];
  List<dynamic> products = [];

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
  | Loading State
  |--------------------------------------------------------------------------
  */

  bool isLoading = true;

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
      final loadedCategories = await apiService.getActiveCategories();
      final loadedProducts = await apiService.getProducts();

      if (!mounted) return;

      setState(() {
        categories = loadedCategories;
        products = loadedProducts;
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
  | Product Price Helper
  |--------------------------------------------------------------------------
  */

  double productPrice(dynamic product) {
    return toMoneyDouble(product['selling_price'] ?? product['price']);
  }

  /*
  |--------------------------------------------------------------------------
  | Filtered Products
  |--------------------------------------------------------------------------
  */

  List<dynamic> get filteredProducts {
    if (selectedCategoryId == null) {
      return products;
    }

    return products.where((product) {
      return product['product_category_id'] == selectedCategoryId;
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
          'price': productPrice(product),
          'quantity': 1,
        });
      }
    });
  }

  /*
  |--------------------------------------------------------------------------
  | Increase Quantity
  |--------------------------------------------------------------------------
  */

  void increaseQuantity(int productId) {
    setState(() {
      final index = cart.indexWhere((item) => item['id'] == productId);

      if (index >= 0) {
        cart[index]['quantity'] += 1;
      }
    });
  }

  /*
  |--------------------------------------------------------------------------
  | Decrease Quantity
  |--------------------------------------------------------------------------
  */

  void decreaseQuantity(int productId) {
    setState(() {
      final index = cart.indexWhere((item) => item['id'] == productId);

      if (index >= 0) {
        if (cart[index]['quantity'] > 1) {
          cart[index]['quantity'] -= 1;
        } else {
          cart.removeAt(index);
        }
      }
    });
  }

  /*
  |--------------------------------------------------------------------------
  | Clear Cart
  |--------------------------------------------------------------------------
  */

  void clearCart() {
    setState(() {
      cart.clear();
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
      total += toMoneyDouble(item['quantity']) * toMoneyDouble(item['price']);
    }

    return total;
  }

  /*
  |--------------------------------------------------------------------------
  | Process Counter Payment
  |--------------------------------------------------------------------------
  */

  Future<void> processCounterPayment({
    required Map<String, dynamic> paymentData,
  }) async {
    try {
      final result = await apiService.processCounterOrderPayment(
        items: cart,
        paymentMethod: paymentData['payment_method'],
        subtotal: toMoneyDouble(paymentData['subtotal']),
        taxAmount: toMoneyDouble(paymentData['tax_amount']),
        discountAmount: toMoneyDouble(paymentData['discount_amount']),
        discountPercentage: toMoneyDouble(paymentData['discount_percentage']),
        totalAmount: toMoneyDouble(paymentData['total_amount']),
        buzzerNumber: paymentData['buzzer_number'],
      );

      if (!mounted) return;

      final order = result['order'];

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptScreen(
            order: order,
            paymentMethod: paymentData['payment_method'],
            subtotal: toMoneyDouble(paymentData['subtotal']),
            taxAmount: toMoneyDouble(paymentData['tax_amount']),
            discountAmount: toMoneyDouble(paymentData['discount_amount']),
            totalAmount: toMoneyDouble(paymentData['total_amount']),
          ),
        ),
      );

      if (!mounted) return;

      setState(() {
        cart.clear();
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
  | Open Payment Dialog
  |--------------------------------------------------------------------------
  */

  Future<void> openPaymentDialog() async {
    final subtotalAmount = subtotal();

    final paymentData = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return CounterPaymentDialog(subtotalAmount: subtotalAmount);
      },
    );

    if (paymentData == null) {
      return;
    }

    await processCounterPayment(paymentData: paymentData);
  }

  /*
  |--------------------------------------------------------------------------
  | Category Card
  |--------------------------------------------------------------------------
  */

  Widget categoryCard(dynamic category) {
    final selected = selectedCategoryId == category['id'];

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategoryId = category['id'];
        });
      },
      child: Container(
        width: 145,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? Colors.orange.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.orange : Colors.grey.shade300,
            width: selected ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (category['image_url'] != null &&
                category['image_url'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  category['image_url'],
                  height: 52,
                  width: 82,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.broken_image,
                      size: 46,
                      color: Colors.red,
                    );
                  },
                ),
              )
            else
              const Icon(Icons.fastfood, size: 46, color: Colors.orange),

            const SizedBox(height: 4),

            Text(
              category['name'],
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Product Card
  |--------------------------------------------------------------------------
  */

  Widget productCard(dynamic product) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        addToCart(product);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (product['image_url'] != null &&
                  product['image_url'].toString().isNotEmpty)
                SizedBox(
                  height: 95,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      product['image_url'],
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image,
                          size: 52,
                          color: Colors.red,
                        );
                      },
                    ),
                  ),
                )
              else
                const Icon(Icons.fastfood, size: 56, color: Colors.blueGrey),

              const SizedBox(height: 12),

              Text(
                product['name'],
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                formatMoney(productPrice(product)),
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Cart Item Row
  |--------------------------------------------------------------------------
  */

  Widget cartItemRow(Map<String, dynamic> item) {
    final lineTotal =
        toMoneyDouble(item['quantity']) * toMoneyDouble(item['price']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          /*
          |--------------------------------------------------------------------------
          | Item Name And Price
          |--------------------------------------------------------------------------
          */
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatMoney(item['price'])} each',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ],
            ),
          ),

          /*
          |--------------------------------------------------------------------------
          | Quantity Controls
          |--------------------------------------------------------------------------
          */
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.remove_circle,
                  color: Colors.red,
                  size: 30,
                ),
                onPressed: () {
                  decreaseQuantity(item['id']);
                },
              ),

              Container(
                width: 38,
                alignment: Alignment.center,
                child: Text(
                  item['quantity'].toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),

              IconButton(
                icon: const Icon(
                  Icons.add_circle,
                  color: Colors.green,
                  size: 30,
                ),
                onPressed: () {
                  increaseQuantity(item['id']);
                },
              ),
            ],
          ),

          /*
          |--------------------------------------------------------------------------
          | Line Total
          |--------------------------------------------------------------------------
          */
          SizedBox(
            width: 78,
            child: Text(
              formatMoney(lineTotal),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
    final subtotalAmount = subtotal();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text('Counter POS'),

        elevation: 0,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                /*
                |--------------------------------------------------------------------------
                | LEFT SIDE: CATEGORIES + PRODUCTS
                |--------------------------------------------------------------------------
                */
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      /*
                      |--------------------------------------------------------------------------
                      | Visual Category Bar
                      |--------------------------------------------------------------------------
                      */
                      SizedBox(
                        height: 145,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedCategoryId = null;
                                });
                              },
                              child: Container(
                                width: 135,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: selectedCategoryId == null
                                      ? Colors.orange.shade100
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selectedCategoryId == null
                                        ? Colors.orange
                                        : Colors.grey.shade300,
                                    width: selectedCategoryId == null ? 2 : 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.restaurant_menu,
                                      size: 46,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'All',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            ...categories.map(categoryCard),
                          ],
                        ),
                      ),

                      /*
                      |--------------------------------------------------------------------------
                      | Product Grid
                      |--------------------------------------------------------------------------
                      */
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;

                            int crossAxisCount = 4;

                            if (width > 1200) {
                              crossAxisCount = 5;
                            }

                            if (width > 1500) {
                              crossAxisCount = 6;
                            }

                            return GridView.builder(
                              padding: const EdgeInsets.all(18),
                              itemCount: filteredProducts.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio: 0.82,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];

                                return productCard(product);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                /*
                |--------------------------------------------------------------------------
                | RIGHT SIDE: CART + TOTAL + PAY
                |--------------------------------------------------------------------------
                */
                Container(
                  width: 440,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(-4, 0),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /*
                        |--------------------------------------------------------------------------
                        | Cart Header
                        |--------------------------------------------------------------------------
                        */
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Cart',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: cart.isEmpty ? null : clearCart,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Clear'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        /*
                        |--------------------------------------------------------------------------
                        | Scrollable Cart Listing
                        |--------------------------------------------------------------------------
                        */
                        Expanded(
                          child: cart.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No items selected',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: cart.length,
                                  itemBuilder: (context, index) {
                                    final item = cart[index];

                                    return cartItemRow(item);
                                  },
                                ),
                        ),

                        const Divider(height: 32),

                        /*
                        |--------------------------------------------------------------------------
                        | Total Summary
                        |--------------------------------------------------------------------------
                        */
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              formatMoney(subtotalAmount),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        /*
                        |--------------------------------------------------------------------------
                        | Pay Button
                        |--------------------------------------------------------------------------
                        */
                        SizedBox(
                          width: double.infinity,
                          height: 78,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: cart.isEmpty ? null : openPaymentDialog,
                            icon: const Icon(Icons.payments),
                            label: const Text(
                              'PAY',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
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
