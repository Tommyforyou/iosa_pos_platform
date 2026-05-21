import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/money.dart';

/*
|--------------------------------------------------------------------------
| Stock Movement Screen
|--------------------------------------------------------------------------
| Shows inventory movement ledger.
*/

class StockMovementScreen extends StatefulWidget {
  const StockMovementScreen({super.key});

  @override
  State<StockMovementScreen> createState() =>
      _StockMovementScreenState();
}

class _StockMovementScreenState extends State<StockMovementScreen> {
  final ApiService apiService = ApiService();

  List<dynamic> movements = [];
  bool isLoading = true;

  final TextEditingController productController =
      TextEditingController();

  String movementType = '';

  @override
  void initState() {
    super.initState();
    loadMovements();
  }

  @override
  void dispose() {
    productController.dispose();
    super.dispose();
  }

  Future<void> loadMovements() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await apiService.getStockMovements(
        product: productController.text.trim(),
        movementType: movementType,
      );

      if (!mounted) return;

      setState(() {
        movements = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color typeColor(String type) {
    switch (type) {
      case 'sale':
        return Colors.red;
      case 'purchase':
        return Colors.green;
      case 'adjustment':
        return Colors.blue;
      case 'wastage':
        return Colors.orange;
      case 'return':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }

  Widget movementCard(dynamic movement) {
    final product = movement['product'];
    final productName = product?['name'] ?? 'Unknown Product';
    final type = movement['movement_type'] ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: typeColor(type).withOpacity(0.12),
            child: Icon(
              Icons.inventory_2,
              color: typeColor(type),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    Text('Type: ${type.toUpperCase()}'),
                    Text('Qty: ${movement['quantity']}'),
                    Text('Before: ${movement['before_quantity']}'),
                    Text('After: ${movement['after_quantity']}'),
                    Text('Date: ${movement['created_at']}'),
                  ],
                ),

                if (movement['remarks'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      movement['remarks'],
                      style: TextStyle(
                        color: Colors.grey.shade700,
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

  @override
  Widget build(BuildContext context) {
    final saleCount = movements
        .where((m) => m['movement_type'] == 'sale')
        .length;

    final purchaseCount = movements
        .where((m) => m['movement_type'] == 'purchase')
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Stock Movements'),
        actions: [
          IconButton(
            onPressed: loadMovements,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Row(
              children: [
                _SummaryCard(
                  title: 'Total Movements',
                  value: movements.length.toString(),
                  icon: Icons.timeline,
                  color: Colors.blue,
                ),
                const SizedBox(width: 14),
                _SummaryCard(
                  title: 'Sales Out',
                  value: saleCount.toString(),
                  icon: Icons.remove_circle,
                  color: Colors.red,
                ),
                const SizedBox(width: 14),
                _SummaryCard(
                  title: 'Purchases In',
                  value: purchaseCount.toString(),
                  icon: Icons.add_circle,
                  color: Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: productController,
                      onSubmitted: (_) => loadMovements(),
                      decoration: InputDecoration(
                        labelText: 'Search product',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  DropdownButton<String>(
                    value: movementType,
                    items: const [
                      DropdownMenuItem(
                        value: '',
                        child: Text('All Types'),
                      ),
                      DropdownMenuItem(
                        value: 'sale',
                        child: Text('Sale'),
                      ),
                      DropdownMenuItem(
                        value: 'purchase',
                        child: Text('Purchase'),
                      ),
                      DropdownMenuItem(
                        value: 'adjustment',
                        child: Text('Adjustment'),
                      ),
                      DropdownMenuItem(
                        value: 'wastage',
                        child: Text('Wastage'),
                      ),
                      DropdownMenuItem(
                        value: 'return',
                        child: Text('Return'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        movementType = value ?? '';
                      });

                      loadMovements();
                    },
                  ),

                  const SizedBox(width: 12),

                  ElevatedButton.icon(
                    onPressed: loadMovements,
                    icon: const Icon(Icons.filter_alt),
                    label: const Text('Apply'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : movements.isEmpty
                      ? const Center(
                          child: Text('No stock movements found'),
                        )
                      : ListView.builder(
                          itemCount: movements.length,
                          itemBuilder: (context, index) {
                            return movementCard(movements[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(title),
              ],
            ),
          ],
        ),
      ),
    );
  }
}