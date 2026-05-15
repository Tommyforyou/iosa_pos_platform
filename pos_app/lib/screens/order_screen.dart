import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OrderScreen extends StatefulWidget {
  final Map<String, dynamic> table;

  const OrderScreen({
    super.key,
    required this.table,
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final ApiService apiService = ApiService();

  List<dynamic> products = [];
  List<Map<String, dynamic>> cart = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      final data = await apiService.getProducts();

      setState(() {
        products = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      setState(() {
        isLoading = false;
      });
    }
  }

  void addToCart(dynamic product) {
    final existingIndex = cart.indexWhere(
      (item) => item['id'] == product['id'],
    );

    if (existingIndex >= 0) {
      setState(() {
        cart[existingIndex]['quantity'] += 1;
      });
    } else {
      setState(() {
        cart.add({
          'id': product['id'],
          'name': product['name'],
          'price': double.parse(product['selling_price'].toString()),
          'quantity': 1,
        });
      });
    }
  }

  double get totalAmount {
    double total = 0;

    for (var item in cart) {
      total += item['price'] * item['quantity'];
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order - ${widget.table['table_name']}'),
      ),
      body: Row(
        children: [
          /*
          |--------------------------------------------------------------------------
          | Product List
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

                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
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

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {},
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