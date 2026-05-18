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
| → Apply Discount
| → Select Payment Method
| → Pay Immediately
| → Send To Kitchen
| → Show Receipt
|
| This screen does not use table numbers.
*/

class CounterPosScreen extends StatefulWidget {
  const CounterPosScreen({super.key});

  @override
  State<CounterPosScreen> createState() =>
      _CounterPosScreenState();
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
  | Food Court Buzzer
  |--------------------------------------------------------------------------
  */

  final TextEditingController buzzerController =
      TextEditingController();


  /*
  |--------------------------------------------------------------------------
  | Discount Options
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

    /*
    |--------------------------------------------------------------------------
    | Initial Data Load
    |--------------------------------------------------------------------------
    */

    loadData();
  }

  /*
  |--------------------------------------------------------------------------
  | Load Categories And Products
  |--------------------------------------------------------------------------
  | Loads POS categories and products from Laravel API.
  */

  Future<void> loadData() async {
    try {
      final loadedCategories = await apiService.getActiveCategories();
      final loadedProducts = await apiService.getProducts();

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
  | Product Price Helper
  |--------------------------------------------------------------------------
  | Products from Laravel usually use selling_price.
  | This fallback protects the screen if price is used later.
  */

  double productPrice(dynamic product) {
    return toMoneyDouble(
      product['selling_price'] ?? product['price'],
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Filtered Products
  |--------------------------------------------------------------------------
  | If no category is selected, show all products.
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
  | Adds one quantity of selected product.
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
  | Remove Product From Cart
  |--------------------------------------------------------------------------
  | Reduces quantity by one. If quantity becomes zero, removes item.
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
      total += toMoneyDouble(item['quantity']) *
          toMoneyDouble(item['price']);
    }

    return total;
  }

  /*
  |--------------------------------------------------------------------------
  | Process Counter Payment
  |--------------------------------------------------------------------------
  | Sends counter order to Laravel.
  |
  | Backend will:
  | - create takeaway order
  | - save order items
  | - mark order as paid
  | - send items to kitchen
  | - return order for receipt
  */

  Future<void> processCounterPayment({
    required double subtotalAmount,
    required double discountAmount,
    required double vatIncluded,
    required double finalTotal,
  }) async {
    try {
      final result = await apiService.processCounterOrderPayment(
        items: cart,
        paymentMethod: paymentMethod,
        subtotal: subtotalAmount,
        taxAmount: vatIncluded,
        discountAmount: discountAmount,
        discountPercentage: discountPercentage,
        totalAmount: finalTotal,
        buzzerNumber: buzzerController.text.trim(),
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

  /*
  |--------------------------------------------------------------------------
  | Dispose Controllers
  |--------------------------------------------------------------------------
  */

  @override
  void dispose() {
    buzzerController.dispose();
    super.dispose();
  }
  
  /*
    |--------------------------------------------------------------------------
    | Build
    |--------------------------------------------------------------------------
    */

  @override
  Widget build(BuildContext context) {
    /*
    |--------------------------------------------------------------------------
    | Financial Calculations
    |--------------------------------------------------------------------------
    */

    final subtotalAmount = subtotal();

    final discountAmount = calculateDiscountAmount(
      subtotal: subtotalAmount,
      discountPercentage: discountPercentage,
    );

    final finalTotal = calculateFinalTotal(
      subtotal: subtotalAmount,
      discountPercentage: discountPercentage,
    );

    final vatIncluded = calculateVatIncluded(finalTotal);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        title: const Text('Counter POS'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isLoading = true;
              });

              loadData();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Row(
              children: [
                /*
                |--------------------------------------------------------------------------
                | LEFT SIDE: CATEGORIES + PRODUCT GRID
                |--------------------------------------------------------------------------
                */

                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      /*
                      |--------------------------------------------------------------------------
                      | Visual Category Bar
                      |--------------------------------------------------------------------------
                      */

                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          children: [
                            /*
                            |--------------------------------------------------------------------------
                            | All Categories Card
                            |--------------------------------------------------------------------------
                            */

                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedCategoryId = null;
                                });
                              },
                              child: Container(
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
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.15),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.restaurant_menu,
                                      size: 42,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'All',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            /*
                            |--------------------------------------------------------------------------
                            | Category Image Cards
                            |--------------------------------------------------------------------------
                            */

                            ...categories.map((category) {
                              final selected =
                                  selectedCategoryId == category['id'];

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedCategoryId = category['id'];
                                  });
                                },
                                child: Container(
                                  width: 125,
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? Colors.orange.shade100
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: selected
                                          ? Colors.orange
                                          : Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.15),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      /*
                                      |--------------------------------------------------------------------------
                                      | Category Image
                                      |--------------------------------------------------------------------------
                                      */

                                      if (category['image_url'] != null && category['image_url'].toString().isNotEmpty)
                                       
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.network(
                                                  category['image_url'],
                                                  height: 55,
                                                  width: 80,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return const Icon(
                                                      Icons.broken_image,
                                                      size: 42,
                                                      color: Colors.red,
                                                    );
                                                  },
                                                )
                                         )
                                      else
                                        const Icon(
                                          Icons.fastfood,
                                          size: 42,
                                          color: Colors.orange,
                                        ),

                                      const SizedBox(height: 8),

                                      Text(
                                        category['name'],
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
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
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredProducts.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 0.95,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];

                            return InkWell(
                              onTap: () {
                                addToCart(product);
                              },
                              child: Card(
                                elevation: 4,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      /*
                                      |--------------------------------------------------------------------------
                                      | Product Image
                                      |--------------------------------------------------------------------------
                                      */

                                      if (product['image_url'] != null)
                                        SizedBox(
                                          height: 90,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.network(
                                              product['image_url'],
                                              width: double.infinity,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        )
                                      else
                                        const Icon(
                                          Icons.fastfood,
                                          size: 48,
                                          color: Colors.blueGrey,
                                        ),

                                      const SizedBox(height: 10),

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
                                        formatMoney(
                                          productPrice(product),
                                        ),
                                        style: const TextStyle(
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
                    ],
                  ),
                ),

                /*
                |--------------------------------------------------------------------------
                | RIGHT SIDE: CART + DISCOUNT + PAYMENT
                |--------------------------------------------------------------------------
                */

                Container(
                  width: 430,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /*
                        |--------------------------------------------------------------------------
                        | Cart Header
                        |--------------------------------------------------------------------------
                        */

                        const Text(
                          'Cart',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),
                        /*
                        |--------------------------------------------------------------------------
                        | Buzzer Number
                        |--------------------------------------------------------------------------
                        */

                        TextField(
                          controller: buzzerController,

                          decoration: InputDecoration(
                            labelText: 'Buzzer Number',
                            hintText: 'Optional',

                            prefixIcon: const Icon(
                              Icons.notifications_active,
                            ),

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),


                        /*
                        |--------------------------------------------------------------------------
                        | Cart Listing
                        |--------------------------------------------------------------------------
                        */

                        Expanded(
                          child: cart.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No items selected',
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: cart.length,
                                  itemBuilder: (context, index) {
                                    final item = cart[index];

                                    final lineTotal =
                                        toMoneyDouble(item['quantity']) *
                                            toMoneyDouble(item['price']);

                                    return Card(
                                      child: ListTile(
                                        title: Text(
                                          item['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
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
                                            IconButton(
                                              icon: const Icon(
                                                Icons.remove_circle,
                                                color: Colors.red,
                                              ),
                                              onPressed: () {
                                                removeFromCart(item['id']);
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
                        | Discount Selector
                        |--------------------------------------------------------------------------
                        */

                        const Text(
                          'Discount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: discountOptions.map((discount) {
                            return ChoiceChip(
                              label: Text(
                                '${discount.toStringAsFixed(0)}%',
                              ),
                              selected: discountPercentage == discount,
                              onSelected: (_) {
                                setState(() {
                                  discountPercentage = discount;

                                  if (discount == 100) {
                                    paymentMethod = 'complimentary';
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        /*
                        |--------------------------------------------------------------------------
                        | Payment Method Selector
                        |--------------------------------------------------------------------------
                        */

                        const Text(
                          'Payment Method',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: paymentMethods.map((method) {
                            return ChoiceChip(
                              label: Text(method.toUpperCase()),
                              selected: paymentMethod == method,
                              onSelected: (_) {
                                setState(() {
                                  paymentMethod = method;

                                  if (method == 'complimentary') {
                                    discountPercentage = 100;
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),

                        const Divider(height: 32),

                        /*
                        |--------------------------------------------------------------------------
                        | Financial Totals
                        |--------------------------------------------------------------------------
                        */

                        _SummaryRow(
                          label: 'Subtotal',
                          value: formatMoney(subtotalAmount),
                        ),

                        _SummaryRow(
                          label:
                              'Discount (${discountPercentage.toStringAsFixed(0)}%)',
                          value: '- ${formatMoney(discountAmount)}',
                        ),

                        _SummaryRow(
                          label: 'VAT Included',
                          value: formatMoney(vatIncluded),
                        ),

                        const Divider(),

                        _SummaryRow(
                          label: 'TOTAL',
                          value: formatMoney(finalTotal),
                          isBold: true,
                        ),

                        const SizedBox(height: 20),

                        /*
                        |--------------------------------------------------------------------------
                        | Pay And Send Button
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
                                      subtotalAmount: subtotalAmount,
                                      discountAmount: discountAmount,
                                      vatIncluded: vatIncluded,
                                      finalTotal: finalTotal,
                                    );
                                  },
                            icon: const Icon(Icons.payments),
                            label: Text(
                              paymentMethod == 'complimentary'
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
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}