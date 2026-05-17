import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/money.dart';

/*
|--------------------------------------------------------------------------
| Product Management Screen
|--------------------------------------------------------------------------
| Back-office screen for managing products/menu items.
|
| Features:
| - create product
| - edit product
| - delete product
| - assign category
| - manage price
| - manage stock
| - manage VAT
| - activate/deactivate product
| - upload product image
*/

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState
    extends State<ProductManagementScreen> {
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

  List<dynamic> products = [];
  List<dynamic> categories = [];

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
  | Load Products And Categories
  |--------------------------------------------------------------------------
  */

  Future<void> loadData() async {
    try {
      final loadedProducts = await apiService.getProducts();
      final loadedCategories = await apiService.getCategories();

      setState(() {
        products = loadedProducts;
        categories = loadedCategories;
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
  | Upload Product Image
  |--------------------------------------------------------------------------
  */

  Future<void> uploadProductImage(int productId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result == null) {
        return;
      }

      final filePath = result.files.single.path;

      if (filePath == null) {
        return;
      }

      await apiService.uploadProductImage(
        productId: productId,
        filePath: filePath,
      );

      await loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product image uploaded successfully'),
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
  | Create / Edit Product Dialog
  |--------------------------------------------------------------------------
  */

  Future<void> showProductDialog({
    dynamic product,
  }) async {
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create a category first.'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final nameController = TextEditingController(
      text: product?['name'] ?? '',
    );

    final sellingPriceController = TextEditingController(
      text: product?['selling_price']?.toString() ?? '0',
    );

    final costPriceController = TextEditingController(
      text: product?['cost_price']?.toString() ?? '0',
    );

    final stockController = TextEditingController(
      text: product?['stock_quantity']?.toString() ?? '0',
    );

    final reorderController = TextEditingController(
      text: product?['reorder_level']?.toString() ?? '0',
    );

    final unitController = TextEditingController(
      text: product?['unit'] ?? 'pcs',
    );

    final descriptionController = TextEditingController(
      text: product?['description'] ?? '',
    );

    final vatRateController = TextEditingController(
      text: product?['vat_rate']?.toString() ?? '15',
    );

    int? selectedCategoryId =
        product?['product_category_id'] ?? categories.first['id'];

    bool vatApplicable = product?['vat_applicable'] ?? true;
    bool isActive = product?['is_active'] ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                product == null ? 'Create Product' : 'Edit Product',
              ),
              content: SizedBox(
                width: 540,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /*
                      |--------------------------------------------------------------------------
                      | Product Name
                      |--------------------------------------------------------------------------
                      */

                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      /*
                      |--------------------------------------------------------------------------
                      | Category
                      |--------------------------------------------------------------------------
                      */

                      DropdownButtonFormField<int>(
                        value: selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: categories.map<DropdownMenuItem<int>>(
                          (category) {
                            return DropdownMenuItem<int>(
                              value: category['id'],
                              child: Text(category['name']),
                            );
                          },
                        ).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedCategoryId = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      /*
                      |--------------------------------------------------------------------------
                      | Pricing
                      |--------------------------------------------------------------------------
                      */

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: sellingPriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Selling Price',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: costPriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Cost Price',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      /*
                      |--------------------------------------------------------------------------
                      | Inventory
                      |--------------------------------------------------------------------------
                      */

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: stockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Stock Quantity',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: reorderController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Reorder Level',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      /*
                      |--------------------------------------------------------------------------
                      | Unit
                      |--------------------------------------------------------------------------
                      */

                      TextField(
                        controller: unitController,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      /*
                      |--------------------------------------------------------------------------
                      | Description
                      |--------------------------------------------------------------------------
                      */

                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      /*
                      |--------------------------------------------------------------------------
                      | VAT
                      |--------------------------------------------------------------------------
                      */

                      SwitchListTile(
                        value: vatApplicable,
                        title: const Text('VAT Applicable'),
                        onChanged: (value) {
                          setDialogState(() {
                            vatApplicable = value;
                          });
                        },
                      ),

                      TextField(
                        controller: vatRateController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'VAT Rate',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      /*
                      |--------------------------------------------------------------------------
                      | Active Status
                      |--------------------------------------------------------------------------
                      */

                      SwitchListTile(
                        value: isActive,
                        title: const Text('Active Product'),
                        onChanged: (value) {
                          setDialogState(() {
                            isActive = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) {
      return;
    }

    try {
      final sellingPrice =
          double.tryParse(sellingPriceController.text) ?? 0;

      final costPrice =
          double.tryParse(costPriceController.text) ?? 0;

      final stockQuantity =
          double.tryParse(stockController.text) ?? 0;

      final reorderLevel =
          double.tryParse(reorderController.text) ?? 0;

      final vatRate =
          double.tryParse(vatRateController.text) ?? 15;

      if (product == null) {
        await apiService.createProduct(
          categoryId: selectedCategoryId!,
          name: nameController.text.trim(),
          sellingPrice: sellingPrice,
          costPrice: costPrice,
          stockQuantity: stockQuantity,
          reorderLevel: reorderLevel,
          unit: unitController.text.trim(),
          vatApplicable: vatApplicable,
          vatRate: vatRate,
          isActive: isActive,
          description: descriptionController.text.trim(),
        );
      } else {
        await apiService.updateProduct(
          productId: product['id'],
          categoryId: selectedCategoryId!,
          name: nameController.text.trim(),
          sellingPrice: sellingPrice,
          costPrice: costPrice,
          stockQuantity: stockQuantity,
          reorderLevel: reorderLevel,
          unit: unitController.text.trim(),
          vatApplicable: vatApplicable,
          vatRate: vatRate,
          isActive: isActive,
          description: descriptionController.text.trim(),
        );
      }

      await loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product saved successfully'),
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
  | Delete Product
  |--------------------------------------------------------------------------
  */

  Future<void> deleteProduct(int productId) async {
    try {
      await apiService.deleteProduct(productId);

      await loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product deleted successfully'),
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
  | Confirm Delete
  |--------------------------------------------------------------------------
  */

  Future<void> confirmDeleteProduct(int productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: const Text(
            'Are you sure you want to delete this product?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      deleteProduct(productId);
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Product Category Name
  |--------------------------------------------------------------------------
  */

  String productCategoryName(dynamic product) {
    final categoryId = product['product_category_id'];

    final match = categories.where(
      (category) => category['id'] == categoryId,
    );

    if (match.isEmpty) {
      return 'No Category';
    }

    return match.first['name'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Product Management'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showProductDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Product'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : products.isEmpty
              ? const Center(
                  child: Text(
                    'No products found',
                    style: TextStyle(fontSize: 20),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];

                    return Card(
                      child: ListTile(
                        /*
                        |--------------------------------------------------------------------------
                        | Product Image
                        |--------------------------------------------------------------------------
                        */

                        leading: product['image_url'] != null
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(
                                  product['image_url'],
                                ),
                              )
                            : const CircleAvatar(
                                child: Icon(Icons.fastfood),
                              ),

                        /*
                        |--------------------------------------------------------------------------
                        | Product Name
                        |--------------------------------------------------------------------------
                        */

                        title: Text(
                          product['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        /*
                        |--------------------------------------------------------------------------
                        | Product Details
                        |--------------------------------------------------------------------------
                        */

                        subtitle: Text(
                          '${productCategoryName(product)} • '
                          '${formatMoney(product['selling_price'])} • '
                          'Stock: ${product['stock_quantity']} ${product['unit'] ?? ''}',
                        ),

                        /*
                        |--------------------------------------------------------------------------
                        | Actions
                        |--------------------------------------------------------------------------
                        */

                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              product['is_active']
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: product['is_active']
                                  ? Colors.green
                                  : Colors.red,
                            ),

                            /*
                            |--------------------------------------------------------------------------
                            | Upload Image
                            |--------------------------------------------------------------------------
                            */

                            IconButton(
                              icon: const Icon(Icons.image),
                              onPressed: () {
                                uploadProductImage(product['id']);
                              },
                            ),

                            /*
                            |--------------------------------------------------------------------------
                            | Edit Product
                            |--------------------------------------------------------------------------
                            */

                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                showProductDialog(product: product);
                              },
                            ),

                            /*
                            |--------------------------------------------------------------------------
                            | Delete Product
                            |--------------------------------------------------------------------------
                            */

                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                confirmDeleteProduct(product['id']);
                              },
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