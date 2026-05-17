import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'package:file_picker/file_picker.dart';


/*
|--------------------------------------------------------------------------
| Category Management Screen
|--------------------------------------------------------------------------
| Back-office screen for managing product categories.
|
| Features:
| - create category
| - edit category
| - activate/deactivate
| - delete category
*/

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends State<CategoryManagementScreen> {
  /*
  |--------------------------------------------------------------------------
  | API Service
  |--------------------------------------------------------------------------
  */

  final ApiService apiService = ApiService();

  /*
  |--------------------------------------------------------------------------
  | Category Collection
  |--------------------------------------------------------------------------
  */

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

    loadCategories();
  }

  /*
  |--------------------------------------------------------------------------
  | Load Categories
  |--------------------------------------------------------------------------
  */

  Future<void> loadCategories() async {
    try {
      final data = await apiService.getCategories();

      setState(() {
        categories = data;
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
  | Upload Category Image
  |--------------------------------------------------------------------------
  */

  Future<void> uploadCategoryImage(int categoryId) async {
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

      await apiService.uploadCategoryImage(
      categoryId: categoryId,
      filePath: filePath,
      );

      await loadCategories();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Category image uploaded successfully'),
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
  | Show Create/Edit Dialog
  |--------------------------------------------------------------------------
  */

  Future<void> showCategoryDialog({
    dynamic category,
  }) async {
    final nameController = TextEditingController(
      text: category?['name'] ?? '',
    );

    final sortOrderController =
        TextEditingController(
      text:
          category?['sort_order']?.toString() ??
              '0',
    );

    bool isActive =
        category?['is_active'] ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                category == null
                    ? 'Create Category'
                    : 'Edit Category',
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(
                        labelText: 'Category Name',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller:
                          sortOrderController,
                      keyboardType:
                          TextInputType.number,
                      decoration:
                          const InputDecoration(
                        labelText: 'Sort Order',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SwitchListTile(
                      value: isActive,
                      title:
                          const Text('Active'),
                      onChanged: (value) {
                        setDialogState(() {
                          isActive = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                        context, false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                        context, true);
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
      if (category == null) {
        await apiService.createCategory(
          name: nameController.text.trim(),
          sortOrder: int.tryParse(
                  sortOrderController.text) ??
              0,
          isActive: isActive,
        );
      } else {
        await apiService.updateCategory(
          categoryId: category['id'],
          name: nameController.text.trim(),
          sortOrder: int.tryParse(
                  sortOrderController.text) ??
              0,
          isActive: isActive,
        );
      }

      loadCategories();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text('Category saved successfully'),
        ),
      );
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Delete Category
  |--------------------------------------------------------------------------
  */

  Future<void> deleteCategory(
      int categoryId) async {
    try {
      await apiService.deleteCategory(
        categoryId,
      );

      loadCategories();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text('Category deleted successfully'),
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8FAFC),

      appBar: AppBar(
        title:
            const Text('Category Management'),
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          showCategoryDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : ListView.builder(
              padding:
                  const EdgeInsets.all(16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category =
                    categories[index];

                return Card(
                  child: ListTile(
                    leading:
                        category['image_url'] !=
                                null
                            ? CircleAvatar(
                                backgroundImage:
                                    NetworkImage(
                                  category[
                                      'image_url'],
                                ),
                              )
                            : const CircleAvatar(
                                child:
                                    Icon(Icons.fastfood),
                              ),

                    title: Text(
                      category['name'],
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    subtitle: Text(
                      'Sort Order: ${category['sort_order']}',
                    ),
                    /*
                    |--------------------------------------------------------------------------
                    | Actions
                    |--------------------------------------------------------------------------
                    */
                    trailing: Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [

                        Icon(
                          category['is_active']
                              ? Icons.check_circle
                              : Icons.cancel,
                          color:
                              category['is_active']
                                  ? Colors.green
                                  : Colors.red,
                        ),
                        /*
                        |--------------------------------------------------------------------------
                        | Upload Image for Category
                        |--------------------------------------------------------------------------
                        */
                        IconButton(
                        icon: const Icon(Icons.image),
                        onPressed: () {
                            uploadCategoryImage(category['id']);
                        },
                        ),
                        /*
                        |--------------------------------------------------------------------------
                        | Edit Category
                        |--------------------------------------------------------------------------
                        */
                        IconButton(
                          icon:
                              const Icon(Icons.edit),
                          onPressed: () {
                            showCategoryDialog(
                              category: category,
                            );
                          },
                        ),
                        
                        /*
                        |--------------------------------------------------------------------------
                        | Delete Category
                        |--------------------------------------------------------------------------
                        */
                        
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            deleteCategory(
                              category['id'],
                            );
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