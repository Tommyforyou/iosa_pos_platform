import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import 'kiosk_success_screen.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';

import '../../widgets/kiosk_exit_dialog.dart';

/*
|--------------------------------------------------------------------------
| Kiosk Order Screen
|--------------------------------------------------------------------------
*/

class KioskOrderScreen extends StatefulWidget {
  final String orderType;

  const KioskOrderScreen({super.key, required this.orderType});

  @override
  State<KioskOrderScreen> createState() => _KioskOrderScreenState();
}

class _KioskOrderScreenState extends State<KioskOrderScreen> {
  /*
  |--------------------------------------------------------------------------
  | Services
  |--------------------------------------------------------------------------
  */

  final ApiService apiService = ApiService();

  /*
  |--------------------------------------------------------------------------
  | Data
  |--------------------------------------------------------------------------
  */

  List<dynamic> categories = [];
  List<dynamic> products = [];

  bool isLoading = true;

  int? selectedCategoryId;

  /*
|--------------------------------------------------------------------------
| Cart
|--------------------------------------------------------------------------
*/

  List<Map<String, dynamic>> cart = [];

  /*
  |--------------------------------------------------------------------------
  | Init State
  |--------------------------------------------------------------------------
  */

  @override
  void initState() {
    super.initState();

    loadData();
  }

  /*
|--------------------------------------------------------------------------
| Money Helper
|--------------------------------------------------------------------------
*/

  double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;

    return double.tryParse(value.toString()) ?? 0.0;
  }

  /*
|--------------------------------------------------------------------------
| Cart Total
|--------------------------------------------------------------------------
*/

  double get cartTotal {
    double total = 0.0;

    for (final item in cart) {
      total += toDouble(item['price']) * toDouble(item['quantity']);
    }

    return total;
  }

  /*
|--------------------------------------------------------------------------
| Exit Kiosk Mode
|--------------------------------------------------------------------------
*/

  Future<void> exitKioskMode() async {
    final allowExit =
        await showDialog<bool>(
          context: context,
          builder: (_) => const KioskExitDialog(),
        ) ??
        false;

    if (!allowExit) {
      return;
    }

    if (Platform.isWindows) {
      await windowManager.setFullScreen(false);
      await windowManager.unmaximize();
      await windowManager.setSize(const Size(1600, 950));
      await windowManager.center();
    }

    if (!mounted) return;

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  /*
  |--------------------------------------------------------------------------
  | Build Screen
  |--------------------------------------------------------------------------
  */

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        title: Text(
          widget.orderType == 'dine_in' ? 'Dine In Order' : 'Takeaway Order',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Exit Kiosk',
            onPressed: exitKioskMode,
          ),
        ],
      ),

      body: Row(
        children: [
          /*
          |--------------------------------------------------------------------------
          | Products Area
          |--------------------------------------------------------------------------
          */
          Expanded(
            flex: 7,
            child: Column(
              children: [
                /*
                |--------------------------------------------------------------------------
                | Categories
                |--------------------------------------------------------------------------
                */
                Container(
                  height: 90,
                  padding: const EdgeInsets.all(10),

                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,

                    itemBuilder: (context, index) {
                      final category = categories[index];

                      final selected = selectedCategoryId == category['id'];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategoryId = category['id'];
                          });
                        },

                        child: Container(
                          width: 170,
                          margin: const EdgeInsets.only(right: 12),

                          decoration: BoxDecoration(
                            color: selected ? Colors.orange : Colors.white,

                            borderRadius: BorderRadius.circular(20),

                            border: Border.all(color: Colors.orange),
                          ),

                          child: Center(
                            child: Text(
                              category['name'],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,

                                color: selected ? Colors.white : Colors.orange,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                /*
                |--------------------------------------------------------------------------
                | Products Grid
                |--------------------------------------------------------------------------
                */
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),

                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),

                    itemCount: filteredProducts.length,

                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => addToCart(product),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,

                            borderRadius: BorderRadius.circular(20),

                            border: Border.all(color: Colors.grey.shade300),
                          ),

                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [
                              product['image_url'] != null &&
                                      product['image_url'].toString().isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        product['image_url'],
                                        height: 120,
                                        width: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.fastfood,
                                                size: 80,
                                                color: Colors.orange,
                                              );
                                            },
                                      ),
                                    )
                                  : const Icon(
                                      Icons.fastfood,
                                      size: 80,
                                      color: Colors.orange,
                                    ),

                              const SizedBox(height: 12),

                              Text(
                                product['name'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                'Rs ${product['selling_price']}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              const Text(
                                'Tap to add',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
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
          | Cart Panel
          |--------------------------------------------------------------------------
          */
          Container(
            width: 400,
            decoration: BoxDecoration(
              color: Colors.white,

              border: Border(left: BorderSide(color: Colors.grey.shade300)),
            ),

            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),

                  child: const Text(
                    'YOUR ORDER',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ),

                const Divider(),

                Expanded(
                  child: cart.isEmpty
                      ? const Center(
                          child: Text(
                            'No items added',
                            style: TextStyle(color: Colors.grey, fontSize: 18),
                          ),
                        )
                      : ListView.builder(
                          itemCount: cart.length,

                          itemBuilder: (context, index) {
                            final item = cart[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),

                              child: Padding(
                                padding: const EdgeInsets.all(10),

                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),

                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () => removeItem(index),
                                        ),
                                      ],
                                    ),

                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle),
                                          onPressed: () =>
                                              decreaseQuantity(index),
                                        ),

                                        Text(
                                          item['quantity'].toString(),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle,
                                            color: Colors.green,
                                          ),
                                          onPressed: () =>
                                              increaseQuantity(index),
                                        ),

                                        const Spacer(),

                                        Text(
                                          'Rs ${(toDouble(item['price']) * item['quantity']).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                const Divider(),

                Padding(
                  padding: EdgeInsets.all(20),

                  child: Row(
                    children: [
                      Text(
                        'TOTAL',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Spacer(),

                      Text(
                        'Rs ${cartTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),

                  child: SizedBox(
                    width: double.infinity,
                    height: 60,

                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_sweep),

                      label: const Text(
                        'CLEAR CART',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      onPressed: cart.isEmpty ? null : clearCart,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.all(20),

                  child: SizedBox(
                    width: double.infinity,
                    height: 70,

                    child: ElevatedButton(
                      onPressed: confirmOrder,

                      child: const Text(
                        'CONFIRM ORDER',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
| Load Data
|--------------------------------------------------------------------------
*/

  Future<void> loadData() async {
    try {
      final categoryData = await apiService.getActiveCategories();
      final productData = await apiService.getProducts();

      if (!mounted) return;

      setState(() {
        categories = categoryData;
        products = productData;

        selectedCategoryId = categories.isNotEmpty
            ? categories.first['id']
            : null;

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
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
      return product['product_category_id'] == selectedCategoryId ||
          product['category_id'] == selectedCategoryId;
    }).toList();
  }

  /*
|--------------------------------------------------------------------------
| Add Product To Cart
|--------------------------------------------------------------------------
*/

  void addToCart(dynamic product) {
    final productId = product['id'];
    final price = toDouble(product['selling_price'] ?? product['price']);

    setState(() {
      final existingIndex = cart.indexWhere((item) => item['id'] == productId);

      if (existingIndex >= 0) {
        cart[existingIndex]['quantity'] += 1;
      } else {
        cart.add({
          'id': productId,
          'name': product['name'] ?? 'Product',
          'price': price,
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

  void increaseQuantity(int index) {
    setState(() {
      cart[index]['quantity']++;
    });
  }

  /*
|--------------------------------------------------------------------------
| Decrease Quantity
|--------------------------------------------------------------------------
*/

  void decreaseQuantity(int index) {
    setState(() {
      if (cart[index]['quantity'] > 1) {
        cart[index]['quantity']--;
      } else {
        cart.removeAt(index);
      }
    });
  }

  /*
|--------------------------------------------------------------------------
| Remove Item
|--------------------------------------------------------------------------
*/

  void removeItem(int index) {
    setState(() {
      cart.removeAt(index);
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
| Confirm Order
|--------------------------------------------------------------------------
*/

  Future<void> confirmOrder() async {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    try {
      final result = await apiService.createKioskOrder(
        orderType: widget.orderType,
        items: cart,
        notes: 'Kiosk Order',
      );
      print('KIOSK ORDER RESULT: $result');

      if (!mounted) return;

      final orderId =
          result['daily_order_number'] ??
          result['order']?['daily_order_number'] ??
          result['id'] ??
          result['order_id'];

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => KioskSuccessScreen(orderId: orderId)),
      );

      setState(() {
        cart.clear();
      });

      if (!mounted) return;
    } catch (e, stackTrace) {
      print('====================================');
      print('KIOSK ORDER ERROR');
      print(e.toString());
      print(stackTrace);
      print('====================================');

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Order Error'),
          content: SingleChildScrollView(child: Text(e.toString())),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
