import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/money.dart';

/*
|--------------------------------------------------------------------------
| Order Screen
|--------------------------------------------------------------------------
| Used for:
| - dine-in table orders
| - takeaway orders
| - delivery orders
|
| Responsibilities:
| - load active categories
| - load products
| - show visual category cards
| - show product image cards
| - manage order cart
| - save draft orders
| - reopen existing table draft/order
| - send draft items to kitchen
| - capture customer details for takeaway/delivery
*/

class OrderScreen extends StatefulWidget {
  /*
  |--------------------------------------------------------------------------
  | Order Context
  |--------------------------------------------------------------------------
  | table is used only for dine-in orders.
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
  | Cart State
  |--------------------------------------------------------------------------
  */

  List<Map<String, dynamic>> cart = [];
  List<Map<String, dynamic>> newItems = [];

  /*
  |--------------------------------------------------------------------------
  | Active Order
  |--------------------------------------------------------------------------
  */

  int? activeOrderId;

  /*
  |--------------------------------------------------------------------------
  | UI State
  |--------------------------------------------------------------------------
  */

  bool isLoading = true;
  int? selectedCategoryId;

  /*
  |--------------------------------------------------------------------------
  | Customer Information
  |--------------------------------------------------------------------------
  | Used for takeaway and delivery orders.
  */

  Map<String, dynamic>? selectedCustomer;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController customerNameController =
      TextEditingController();
  final TextEditingController addressController = TextEditingController();

  @override
  void initState() {
    super.initState();

    loadInitialData();
  }

  @override
  void dispose() {
    phoneController.dispose();
    customerNameController.dispose();
    addressController.dispose();

    super.dispose();
  }

  /*
  |--------------------------------------------------------------------------
  | Screen Title
  |--------------------------------------------------------------------------
  */

  String screenTitle() {
    if (widget.orderType == 'dine_in') {
      return 'Order - ${widget.table!['table_name']}';
    }

    if (widget.orderType == 'takeaway') {
      return 'Takeaway Order';
    }

    return 'Delivery Order';
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

      Map<String, dynamic> activeOrderData = {
        'success': false,
        'order': null,
      };

      /*
      |--------------------------------------------------------------------------
      | Load Existing Dine-In Order
      |--------------------------------------------------------------------------
      */

      if (widget.orderType == 'dine_in' && widget.table != null) {
        activeOrderData = await apiService.getActiveOrderByTable(
          widget.table!['id'],
        );
      }

      final List<Map<String, dynamic>> existingCart = [];

      if (activeOrderData['success'] == true &&
          activeOrderData['order'] != null &&
          activeOrderData['order']['items'] != null) {
        activeOrderId = activeOrderData['order']['id'];

        /*
        |--------------------------------------------------------------------------
        | Existing Customer
        |--------------------------------------------------------------------------
        */

        if (activeOrderData['order']['customer'] != null) {
          selectedCustomer = activeOrderData['order']['customer'];

          phoneController.text = selectedCustomer?['phone'] ?? '';
          customerNameController.text = selectedCustomer?['name'] ?? '';
          addressController.text = selectedCustomer?['address'] ?? '';
        }

        /*
        |--------------------------------------------------------------------------
        | Existing Order Items
        |--------------------------------------------------------------------------
        */

        for (final item in activeOrderData['order']['items']) {
          if (item['is_voided'] == true) {
            continue;
          }

          existingCart.add({
            'id': item['product_id'],
            'name': item['product_name'],
            'price': toMoneyDouble(item['unit_price']),
            'quantity': int.parse(
              item['quantity'].toString().split('.').first,
            ),
            'kitchen_status': item['kitchen_status'],
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

      setState(() {
        isLoading = false;
      });
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Search Customer By Phone
  |--------------------------------------------------------------------------
  */

  Future<void> searchCustomer() async {
    if (phoneController.text.trim().isEmpty) {
      return;
    }

    try {
      final customer = await apiService.searchCustomerByPhone(
        phoneController.text.trim(),
      );

      if (customer != null) {
        setState(() {
          selectedCustomer = customer;

          customerNameController.text = customer['name'] ?? '';
          addressController.text = customer['address'] ?? '';
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Existing customer found'),
          ),
        );
      } else {
        setState(() {
          selectedCustomer = null;
          customerNameController.clear();
          addressController.clear();
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No customer found. Enter details to create new.'),
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Create Customer If Needed
  |--------------------------------------------------------------------------
  */

  Future<int?> ensureCustomerExists() async {
    if (widget.orderType == 'dine_in') {
      return null;
    }

    if (selectedCustomer != null) {
      return selectedCustomer!['id'];
    }

    if (phoneController.text.trim().isEmpty ||
        customerNameController.text.trim().isEmpty) {
      return null;
    }

    final result = await apiService.createCustomer(
      name: customerNameController.text.trim(),
      phone: phoneController.text.trim(),
      address: addressController.text.trim(),
    );

    final customer = result['customer'];

    setState(() {
      selectedCustomer = customer;
    });

    return customer['id'];
  }

  /*
  |--------------------------------------------------------------------------
  | Add Product To Cart
  |--------------------------------------------------------------------------
  */

  void addToCart(dynamic product) {
    final price = toMoneyDouble(
      product['selling_price'] ?? product['price'],
    );

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
          'price': price,
          'quantity': 1,
          'kitchen_status': 'draft',
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
          'price': price,
          'quantity': 1,
        });
      }
    });

    saveDraft();
  }

  /*
  |--------------------------------------------------------------------------
  | Remove Item From Cart
  |--------------------------------------------------------------------------
  */

  void removeFromCart(int productId) {
    setState(() {
      final cartIndex = cart.indexWhere(
        (item) => item['id'] == productId,
      );

      if (cartIndex >= 0) {
        if (cart[cartIndex]['quantity'] > 1) {
          cart[cartIndex]['quantity'] -= 1;
        } else {
          cart.removeAt(cartIndex);
        }
      }

      final newItemIndex = newItems.indexWhere(
        (item) => item['id'] == productId,
      );

      if (newItemIndex >= 0) {
        if (newItems[newItemIndex]['quantity'] > 1) {
          newItems[newItemIndex]['quantity'] -= 1;
        } else {
          newItems.removeAt(newItemIndex);
        }
      }
    });

    saveDraft();
  }

  /*
  |--------------------------------------------------------------------------
  | Total Amount
  |--------------------------------------------------------------------------
  */

  double get totalAmount {
    double total = 0;

    for (final item in cart) {
      total += toMoneyDouble(item['price']) * toMoneyDouble(item['quantity']);
    }

    return total;
  }

  /*
  |--------------------------------------------------------------------------
  | Save Draft Order
  |--------------------------------------------------------------------------
  */

  Future<void> saveDraft() async {
    if (cart.isEmpty) {
      return;
    }

    try {
      final customerId = await ensureCustomerExists();

      final result = await apiService.saveDraftRestaurantOrder(
        restaurantTableId: widget.table?['id'],
        customerId: customerId,
        orderType: widget.orderType,
        items: cart,
        notes: null,
      );

      activeOrderId = result['order_id'];
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

  /*
  |--------------------------------------------------------------------------
  | Send Order To Kitchen
  |--------------------------------------------------------------------------
  */

  Future<void> sendOrderToKitchen() async {
    try {
      await saveDraft();

      if (activeOrderId == null) {
        throw Exception('No active order found to send to kitchen.');
      }

      final result = await apiService.sendDraftItemsToKitchen(
        orderId: activeOrderId!,
      );

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
        height: 120,
        width: 125,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? Colors.orange.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.orange : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 45,
              width: 70,
              color: Colors.grey.shade200,
              child: category['image_url'] != null &&
                      category['image_url'].toString().isNotEmpty
                  ? Image.network(
                      category['image_url'],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image,
                          color: Colors.red,
                          size: 36,
                        );
                      },
                    )
                  : const Icon(
                      Icons.fastfood,
                      size: 36,
                      color: Colors.orange,
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              category['name'],
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
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
        borderRadius: BorderRadius.circular(12),
        onTap: () => addToCart(product),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (product['image_url'] != null &&
                  product['image_url'].toString().isNotEmpty)
                SizedBox(
                  height: 90,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      product['image_url'],
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image,
                          size: 42,
                          color: Colors.red,
                        );
                      },
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.fastfood,
                  size: 42,
                  color: Colors.blueGrey,
                ),
              const SizedBox(height: 12),
              Text(
                product['name'],
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatMoney(price),
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
  }

  /*
  |--------------------------------------------------------------------------
  | Customer Panel
  |--------------------------------------------------------------------------
  */

  Widget customerPanel() {
    if (widget.orderType == 'dine_in') {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Phone',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: searchCustomer,
                icon: const Icon(Icons.search),
                label: const Text('Search'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: customerNameController,
            decoration: const InputDecoration(
              labelText: 'Customer Name',
              border: OutlineInputBorder(),
            ),
          ),
          if (widget.orderType == 'delivery') ...[
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Delivery Address',
                border: OutlineInputBorder(),
              ),
            ),
          ],
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(screenTitle()),
      ),
      body: Row(
        children: [
          /*
          |--------------------------------------------------------------------------
          | Product Area
          |--------------------------------------------------------------------------
          */

          Expanded(
            flex: 2,
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Column(
                    children: [
                      customerPanel(),

                      /*
                      |--------------------------------------------------------------------------
                      | Category Bar
                      |--------------------------------------------------------------------------
                      */

                      SizedBox(
                        height: 135,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.all(8),
                          children: [
                            /*
                            |--------------------------------------------------------------------------
                            | All Categories
                            |--------------------------------------------------------------------------
                            */

                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedCategoryId = null;
                                });
                              },
                              child: Container(
                                height: 120,
                                width: 115,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: selectedCategoryId == null
                                      ? Colors.orange.shade100
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: selectedCategoryId == null
                                        ? Colors.orange
                                        : Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.restaurant_menu,
                                      size: 38,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'All',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
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
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredProducts.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.2,
                          ),
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];

                            return productCard(product);
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
            width: 330,
            color: Colors.grey.shade100,
            child: Column(
              children: [
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
                | Cart Items
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

                            final isNewItem = newItems.any(
                              (newItem) => newItem['id'] == item['id'],
                            );

                            final lineTotal = toMoneyDouble(item['quantity']) *
                                toMoneyDouble(item['price']);

                            return ListTile(
                              title: Text(item['name']),
                              subtitle: Text(
                                '${item['quantity']} × ${formatMoney(item['price'])}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    formatMoney(lineTotal),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  if (isNewItem)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        removeFromCart(item['id']);
                                      },
                                    )
                                  else
                                    const Icon(
                                      Icons.lock,
                                      color: Colors.grey,
                                    ),
                                ],
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
                            formatMoney(totalAmount),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: cart.isEmpty ? null : sendOrderToKitchen,
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