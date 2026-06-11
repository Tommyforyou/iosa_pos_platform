import 'package:flutter/material.dart';
import '../services/api_service.dart';

/*
|--------------------------------------------------------------------------
| Pharmacy Batch Screen
|--------------------------------------------------------------------------
| Displays all medicine batches.
|
| Purpose:
| - View stock by batch
| - View expiry dates
| - View batch quantities
|--------------------------------------------------------------------------
*/

class PharmacyBatchScreen extends StatefulWidget {
  const PharmacyBatchScreen({super.key});

  @override
  State<PharmacyBatchScreen> createState() => _PharmacyBatchScreenState();
}

class _PharmacyBatchScreenState extends State<PharmacyBatchScreen> {
  /*
  |--------------------------------------------------------------------------
  | API Service
  |--------------------------------------------------------------------------
  */

  final ApiService apiService = ApiService();

  /*
|--------------------------------------------------------------------------
| Batch Form Controllers
|--------------------------------------------------------------------------
*/

  final TextEditingController batchNumberController = TextEditingController();

  final TextEditingController expiryDateController = TextEditingController();

  final TextEditingController quantityController = TextEditingController();

  final TextEditingController costPriceController = TextEditingController();

  final TextEditingController sellingPriceController = TextEditingController();

  int selectedProductId = 1;

  /*
  |--------------------------------------------------------------------------
  | Screen State
  |--------------------------------------------------------------------------
  */

  List<dynamic> batches = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadBatches();
  }

  /*
  |--------------------------------------------------------------------------
  | Load Batches
  |--------------------------------------------------------------------------
  */

  Future<void> loadBatches() async {
    try {
      final data = await apiService.getProductBatches();

      setState(() {
        batches = data;
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
| Add Batch Dialog
|--------------------------------------------------------------------------
*/

  Future<void> showAddBatchDialog() async {
    batchNumberController.clear();
    expiryDateController.clear();
    quantityController.clear();
    costPriceController.clear();
    sellingPriceController.clear();

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Add Product Batch'),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: batchNumberController,
                  decoration: const InputDecoration(labelText: 'Batch Number'),
                ),

                TextField(
                  controller: expiryDateController,
                  decoration: const InputDecoration(
                    labelText: 'Expiry Date (YYYY-MM-DD)',
                  ),
                ),

                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),

                TextField(
                  controller: costPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cost Price'),
                ),

                TextField(
                  controller: sellingPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Selling Price'),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () async {
                try {
                  await apiService.createProductBatch(
                    productId: selectedProductId,
                    batchNumber: batchNumberController.text,
                    expiryDate: expiryDateController.text,
                    quantity: double.parse(quantityController.text),
                    costPrice: double.parse(costPriceController.text),
                    sellingPrice: double.parse(sellingPriceController.text),
                  );

                  if (!mounted) return;

                  Navigator.pop(context);

                  setState(() {
                    isLoading = true;
                  });

                  loadBatches();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Batch created successfully')),
                  );
                } catch (e) {
                  debugPrint(e.toString());
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Build Screen
  |--------------------------------------------------------------------------
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        title: const Text('Pharmacy Batch Management'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isLoading = true;
              });

              loadBatches();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showAddBatchDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Batch'),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : batches.isEmpty
          ? const Center(
              child: Text('No batches found', style: TextStyle(fontSize: 20)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: batches.length,
              itemBuilder: (context, index) {
                final batch = batches[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.medication)),

                    title: Text(
                      batch['product']['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Batch: ${batch['batch_number']}'),
                        Text('Expiry: ${batch['expiry_date'] ?? '-'}'),
                        Text('Qty: ${batch['quantity']}'),
                      ],
                    ),

                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Cost', style: TextStyle(color: Colors.grey[600])),
                        Text(
                          batch['cost_price'].toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
