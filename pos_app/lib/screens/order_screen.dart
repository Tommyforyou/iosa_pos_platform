import 'package:flutter/material.dart';
import '../services/api_service.dart';

/*
|--------------------------------------------------------------------------
| Restaurant Order Screen
|--------------------------------------------------------------------------
| Responsive waiter/cashier order screen.
|
| Desktop:
| - Products on left
| - Cart on right
|
| Mobile:
| - Products on top
| - Compact cart at bottom
*/

class OrderScreen extends StatefulWidget {
  final Map<String, dynamic>? table;
  final String orderType;

  const OrderScreen({super.key, this.table, this.orderType = 'dine_in'});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final ApiService apiService = ApiService();

  bool isLoading = true;

  int? activeOrderId;
  int? selectedCategoryId;

  List<dynamic> categories = [];
  List<dynamic> products = [];

  List<Map<String, dynamic>> cart = [];
  List<Map<String, dynamic>> newItems = [];

  /*
  |--------------------------------------------------------------------------
  | Initial Load
  |--------------------------------------------------------------------------
  */

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  /*
  |--------------------------------------------------------------------------
  | Screen Title
  |--------------------------------------------------------------------------
  */

  String screenTitle() {
    if (widget.orderType == 'dine_in' && widget.table != null) {
      return widget.table!['table_name'] ?? 'Table Order';
    }

    if (widget.orderType == 'takeaway') {
      return 'Takeaway Order';
    }

    if (widget.orderType == 'delivery') {
      return 'Delivery Order';
    }

    return 'Restaurant Order';
  }

  /*
  |--------------------------------------------------------------------------
  | Money Helpers
  |--------------------------------------------------------------------------
  */

  double toMoneyDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is int) return value.toDouble();

    if (value is double) return value;

    return double.tryParse(value.toString()) ?? 0.0;
  }

  String formatMoney(dynamic value) {
    return 'Rs ${toMoneyDouble(value).toStringAsFixed(2)}';
  }

  /*
  |--------------------------------------------------------------------------
  | Total Amount
  |--------------------------------------------------------------------------
  */

  double get totalAmount {
    double total = 0.0;

    for (final item in cart) {
      final qty = toMoneyDouble(item['quantity']);
      final price = toMoneyDouble(item['price']);

      total += qty * price;
    }

    return total;
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
  | Load Initial Data
  |--------------------------------------------------------------------------
  */

  Future<void> loadInitialData() async {
    try {
      final categoryData = await apiService.getActiveCategories();
      final productData = await apiService.getProducts();

      Map<String, dynamic> activeOrderData = {'success': false, 'order': null};

      /*
      |--------------------------------------------------------------------------
      | Load Existing Table Order
      |--------------------------------------------------------------------------
      */

      if (widget.orderType == 'dine_in' && widget.table != null) {
        activeOrderData = await apiService.getActiveOrderByTable(widget.table!['id']);
      }

      final List<Map<String, dynamic>> existingCart = [];

      if (activeOrderData['success'] == true && activeOrderData['order'] != null && activeOrderData['order']['items'] != null) {
        activeOrderId = activeOrderData['order']['id'];

        for (final item in activeOrderData['order']['items']) {
          if (item['is_voided'] == true) {
            continue;
          }

          existingCart.add({
            'id': item['product_id'],
            'name': item['product_name'],
            'price': toMoneyDouble(item['unit_price']),
            'quantity': int.parse(item['quantity'].toString().split('.').first),
            'kitchen_status': item['kitchen_status'],
            'notes': item['notes'] ?? '',
          });
        }
      }

      setState(() {
        categories = categoryData;
        products = productData;
        cart = existingCart;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Add Product To Cart
  |--------------------------------------------------------------------------
  */

  void addToCart(dynamic product) {
    final price = toMoneyDouble(product['selling_price'] ?? product['price']);

    setState(() {
      final existingIndex = cart.indexWhere((item) => item['id'] == product['id']);

      if (existingIndex >= 0) {
        cart[existingIndex]['quantity'] += 1;
      } else {
        cart.add({'id': product['id'], 'name': product['name'], 'price': price, 'quantity': 1, 'kitchen_status': 'draft', 'notes': ''});
      }

      final newIndex = newItems.indexWhere((item) => item['id'] == product['id']);

      if (newIndex >= 0) {
        newItems[newIndex]['quantity'] += 1;
      } else {
        newItems.add({'id': product['id'], 'name': product['name'], 'price': price, 'quantity': 1, 'notes': ''});
      }
    });

    saveDraft();
  }

  /*
  |--------------------------------------------------------------------------
  | Remove From Cart
  |--------------------------------------------------------------------------
  */

  void removeFromCart(int productId) {
    setState(() {
      cart.removeWhere((item) => item['id'] == productId);
      newItems.removeWhere((item) => item['id'] == productId);
    });

    saveDraft();
  }

  /*
  |--------------------------------------------------------------------------
  | Save Draft Order
  |--------------------------------------------------------------------------
  */

  Future<void> saveDraft() async {
    if (cart.isEmpty) return;

    try {
      final result = await apiService.saveDraftRestaurantOrder(
        restaurantTableId: widget.table?['id'],
        orderType: widget.orderType,
        items: cart,
        notes: null,
      );

      if (result['success'] == true && result['order'] != null) {
        activeOrderId = result['order']['id'];
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Send Order To Kitchen
  |--------------------------------------------------------------------------
  */

  Future<void> sendOrderToKitchen() async {
    if (activeOrderId == null) {
      await saveDraft();
    }

    if (activeOrderId == null) {
      return;
    }

    try {
      /*
      |--------------------------------------------------------------------------
      | Send Draft Items To Kitchen
      |--------------------------------------------------------------------------
      | If your ApiService method name is different, rename this call only.
      */

      await apiService.sendDraftItemsToKitchen(orderId: activeOrderId!);

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Order Sent'),
          content: const Text('The order has been sent to the kitchen.'),
          actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );

      setState(() {
        newItems.clear();

        for (final item in cart) {
          if (item['kitchen_status'] == 'draft') {
            item['kitchen_status'] = 'pending';
          }
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Request Bill
  |--------------------------------------------------------------------------
  */

  Future<void> requestBill() async {
    if (activeOrderId == null) {
      return;
    }

    try {
      await apiService.requestBill(orderId: activeOrderId!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill requested successfully')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Category Card
  |--------------------------------------------------------------------------
  */

  Widget categoryCard(dynamic category) {
    final isSelected = selectedCategoryId == category['id'];

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategoryId = category['id'];
        });
      },
      child: Container(
        height: 60,
        width: 70,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.orange : Colors.grey.shade300, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fastfood, size: 18, color: Colors.orange),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                category['name'] ?? 'Category',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              ),
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
    final price = product['selling_price'] ?? product['price'];

    return Card(
      elevation: 3,
      child: InkWell(
        onTap: () => addToCart(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.restaurant, size: 14, color: Colors.blueGrey),
              const SizedBox(height: 4),
              Text(
                product['name'] ?? 'Product',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                formatMoney(price),
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Product Area
  |--------------------------------------------------------------------------
  */

  Widget productArea(bool isMobile) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        /*
        |--------------------------------------------------------------------------
        | Category Bar
        |--------------------------------------------------------------------------
        */
        SizedBox(
          height: isMobile ? 70 : 125,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedCategoryId = null;
                  });
                },
                child: Container(
                  height: 100,
                  width: 100,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: selectedCategoryId == null ? Colors.orange.shade100 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: selectedCategoryId == null ? Colors.orange : Colors.grey.shade300, width: 1.5),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu, size: 30, color: Colors.orange),
                      SizedBox(height: 5),
                      Text('All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
          child: GridView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: filteredProducts.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 2 : 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: isMobile ? 1.25 : 1.2,
            ),
            itemBuilder: (context, index) {
              return productCard(filteredProducts[index]);
            },
          ),
        ),
      ],
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Cart Item Card
  |--------------------------------------------------------------------------
  */

  Widget cartItemCard(Map<String, dynamic> item) {
    final isNewItem = newItems.any((newItem) => newItem['id'] == item['id']);

    final lineTotal = toMoneyDouble(item['quantity']) * toMoneyDouble(item['price']);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /*
            |--------------------------------------------------------------------------
            | Item Name
            |--------------------------------------------------------------------------
            */
            Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 4),

            Text('${item['quantity']} × ${formatMoney(item['price'])}'),

            if ((item['notes'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Note: ${item['notes']}',
                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.orange),
                ),
              ),

            const SizedBox(height: 6),

            Row(
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final controller = TextEditingController(text: item['notes'] ?? '');

                    final result = await showDialog<String>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Kitchen Instructions'),
                        content: TextField(
                          controller: controller,
                          maxLines: 3,
                          decoration: const InputDecoration(hintText: 'No chilli, extra cheese, less salt...'),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, controller.text);
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    );

                    if (result != null) {
                      setState(() {
                        item['notes'] = result;

                        final newItemIndex = newItems.indexWhere((newItem) => newItem['id'] == item['id']);

                        if (newItemIndex >= 0) {
                          newItems[newItemIndex]['notes'] = result;
                        }
                      });

                      saveDraft();
                    }
                  },
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Notes'),
                ),

                const Spacer(),

                Text(formatMoney(lineTotal), style: const TextStyle(fontWeight: FontWeight.bold)),

                const SizedBox(width: 8),

                if (isNewItem)
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () {
                      removeFromCart(item['id']);
                    },
                  )
                else
                  const Icon(Icons.lock, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Cart Area
  |--------------------------------------------------------------------------
  */

  Widget cartArea(bool isMobile) {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        children: [
          /*
          |--------------------------------------------------------------------------
          | Cart Header
          |--------------------------------------------------------------------------
          */
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : 16),
            width: double.infinity,
            color: Colors.blueGrey,
            child: Text(
              'Current Order (${cart.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),

          /*
          |--------------------------------------------------------------------------
          | Cart Items
          |--------------------------------------------------------------------------
          */
          Expanded(
            child: cart.isEmpty
                ? const Center(child: Text('No items added'))
                : ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      return cartItemCard(cart[index]);
                    },
                  ),
          ),

          /*
          |--------------------------------------------------------------------------
          | Cart Footer
          |--------------------------------------------------------------------------
          */
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      formatMoney(totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: cart.isEmpty ? null : sendOrderToKitchen,
                    icon: const Icon(Icons.send),
                    label: const Text('Send'),
                  ),
                ),

                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: activeOrderId == null ? null : requestBill,
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Request Bill'),
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
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: Text(screenTitle())),
      body: isMobile
          ? Column(
              children: [
                Expanded(flex: 45, child: productArea(true)),
                Expanded(flex: 55, child: cartArea(true)),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 2, child: productArea(false)),
                SizedBox(width: 330, child: cartArea(false)),
              ],
            ),
    );
  }
}
