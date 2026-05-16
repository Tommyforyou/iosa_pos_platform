import 'package:flutter/material.dart';
import '../services/api_service.dart';

/*
|--------------------------------------------------------------------------
| Order Screen
|--------------------------------------------------------------------------
| This screen is used for taking restaurant orders.
|
| Current use:
| - Dine-in table orders
|
| Main responsibilities:
| - Load products from Laravel
| - Reload existing active table order
| - Add products to cart
| - Track newly added items separately
| - Send only new items to kitchen
*/

class OrderScreen extends StatefulWidget {

/*
|--------------------------------------------------------------------------
| Order Context
|--------------------------------------------------------------------------
| table is required only for dine-in orders.
| takeaway and delivery orders do not use restaurant tables.
*/

final Map<String, dynamic>? table;
final String orderType;

const OrderScreen({
  super.key,
  this.table,
  required this.orderType,
});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  /*
  |--------------------------------------------------------------------------
  | API Service
  |--------------------------------------------------------------------------
  | Handles all communication with Laravel backend.
  */
  final ApiService apiService = ApiService();

  /*
  |--------------------------------------------------------------------------
  | Screen State
  |--------------------------------------------------------------------------
  | products: menu items loaded from backend
  | cart: all visible order items, including existing saved items
  | newItems: only newly added items to send to kitchen
  */
  List<dynamic> products = [];
  List<Map<String, dynamic>> cart = [];
  List<Map<String, dynamic>> newItems = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    /*
    |--------------------------------------------------------------------------
    | Initial Data Load
    |--------------------------------------------------------------------------
    | When screen opens, load products and any active order for this table.
    */
    loadInitialData();
  }

  /*
  |--------------------------------------------------------------------------
  | Load Initial Data
  |--------------------------------------------------------------------------
  | Loads two important things:
  | 1. Product/menu list
  | 2. Existing active order for occupied table
  |
  | This allows a waiter to reopen a table and continue adding items.
  */
  Future<void> loadInitialData() async {
    try {
      final productData = await apiService.getProducts();

      /*
      |--------------------------------------------------------------------------
      | Load Existing Active Table Order
      |--------------------------------------------------------------------------
      | Only dine-in table orders can have existing active table bills.
      | Takeaway and delivery always start as new orders.
      */

      Map<String, dynamic> activeOrderData = {
        'success': false,
        'order': null,
      };

      if (widget.orderType == 'dine_in' && widget.table != null) {
        activeOrderData = await apiService.getActiveOrderByTable(
          widget.table?['id'],
        );
      }

      final List<Map<String, dynamic>> existingCart = [];

      /*
      |--------------------------------------------------------------------------
      | Convert Existing Backend Items Into Cart Format
      |--------------------------------------------------------------------------
      | These items are already saved in PostgreSQL.
      | They are shown in the cart but NOT added to newItems.
      */
      if (activeOrderData['success'] == true &&
          activeOrderData['order'] != null &&
          activeOrderData['order']['items'] != null) {
        for (final item in activeOrderData['order']['items']) {
          existingCart.add({
            'id': item['product_id'],
            'name': item['product_name'],
            'price': double.parse(item['unit_price'].toString()),
            'quantity': int.parse(
              item['quantity'].toString().split('.').first,
            ),
          });
        }
      }

      setState(() {
        products = productData;
        cart = existingCart;
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
  | Add Product To Cart
  |--------------------------------------------------------------------------
  | Adds selected product to:
  | - cart: visible order summary
  | - newItems: only items that must be sent to kitchen now
  |
  | This prevents duplicate kitchen orders when reopening occupied tables.
  */
  void addToCart(dynamic product) {
    final existingIndex = cart.indexWhere(
      (item) => item['id'] == product['id'],
    );

    setState(() {
      if (existingIndex >= 0) {
        cart[existingIndex]['quantity'] += 1;
      } else {
        cart.add({
          'id': product['id'],
          'name': product['name'],
          'price': double.parse(product['selling_price'].toString()),
          'quantity': 1,
        });
      }

      final newIndex = newItems.indexWhere(
        (item) => item['id'] == product['id'],
      );

      if (newIndex >= 0) {
        newItems[newIndex]['quantity'] += 1;
      } else {
        newItems.add({
          'id': product['id'],
          'name': product['name'],
          'price': double.parse(product['selling_price'].toString()),
          'quantity': 1,
        });
      }
    });
  }

  /*
  |--------------------------------------------------------------------------
  | Calculate Total Amount
  |--------------------------------------------------------------------------
  | Calculates the visible total for all cart items.
  */
  double get totalAmount {
    double total = 0;

    for (final item in cart) {
      total += item['price'] * item['quantity'];
    }

    return total;
  }

  /*
  |--------------------------------------------------------------------------
  | Send Order To Kitchen
  |--------------------------------------------------------------------------
  | Sends only newly added items.
  |
  | Existing items were already saved earlier, so resending full cart would
  | duplicate order items in the database.
  */
  Future<void> sendOrderToKitchen() async {
    try {
      final result = await apiService.saveRestaurantOrder(
        restaurantTableId: widget.table?['id'],
        orderType: widget.orderType,
        items: newItems,
        notes: null,
      );

      /*
      |--------------------------------------------------------------------------
      | Clear New Items After Successful Save
      |--------------------------------------------------------------------------
      | Prevents accidental duplicate send if user remains on the screen.
      */
      newItems.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'Order sent to kitchen',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
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
    return Scaffold(
      /*
      |--------------------------------------------------------------------------
      | Screen Header
      |--------------------------------------------------------------------------
      */
      appBar: AppBar(
              title: Text(
                widget.orderType == 'dine_in'
                    ? 'Order - ${widget.table?['table_name']}'
                    : widget.orderType == 'takeaway'
                        ? 'Takeaway Order'
                        : 'Delivery Order',
              ),
      ),

      /*
      |--------------------------------------------------------------------------
      | Main Layout
      |--------------------------------------------------------------------------
      | Left side: product grid
      | Right side: current order/cart
      */
      body: Row(
        children: [
          /*
          |--------------------------------------------------------------------------
          | Product Grid
          |--------------------------------------------------------------------------
          */
          Expanded(
            flex: 2,
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: products.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                    itemBuilder: (context, index) {
                      final product = products[index];

                      return Card(
                        elevation: 3,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => addToCart(product),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.fastfood,
                                  size: 42,
                                  color: Colors.blueGrey,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  product['name'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Rs ${product['selling_price']}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
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

          /*
          |--------------------------------------------------------------------------
          | Cart Panel
          |--------------------------------------------------------------------------
          */
          Container(
            width: 320,
            color: Colors.grey.shade100,
            child: Column(
              children: [
                /*
                |--------------------------------------------------------------------------
                | Cart Header
                |--------------------------------------------------------------------------
                */
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  color: Colors.blueGrey,
                  child: Text(
                    'Current Order',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),

                /*
                |--------------------------------------------------------------------------
                | Cart Item List
                |--------------------------------------------------------------------------
                */
                Expanded(
                  child: cart.isEmpty
                      ? const Center(
                          child: Text('No items added'),
                        )
                      : ListView.builder(
                          itemCount: cart.length,
                          itemBuilder: (context, index) {
                            final item = cart[index];

                            return ListTile(
                              title: Text(item['name']),
                              subtitle: Text(
                                '${item['quantity']} × Rs ${item['price']}',
                              ),
                              trailing: Text(
                                'Rs ${(item['quantity'] * item['price']).toStringAsFixed(2)}',
                              ),
                            );
                          },
                        ),
                ),

                /*
                |--------------------------------------------------------------------------
                | Total And Send Button
                |--------------------------------------------------------------------------
                */
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
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
                            'Rs ${totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      /*
                      |--------------------------------------------------------------------------
                      | Send To Kitchen Button
                      |--------------------------------------------------------------------------
                      | Disabled unless there are newly added items.
                      */
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: newItems.isEmpty
                              ? null
                              : sendOrderToKitchen,
                          icon: const Icon(Icons.send),
                          label: const Text('Send to Kitchen'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}