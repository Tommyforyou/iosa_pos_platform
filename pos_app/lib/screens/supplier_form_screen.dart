import 'package:flutter/material.dart';

import '../services/api_service.dart';

/*
|--------------------------------------------------------------------------
| Supplier Form Screen
|--------------------------------------------------------------------------
*/

class SupplierFormScreen extends StatefulWidget {
  final Map<String, dynamic>? supplier;

  const SupplierFormScreen({
    super.key,
    this.supplier,
  });

  @override
  State<SupplierFormScreen> createState() =>
      _SupplierFormScreenState();
}

class _SupplierFormScreenState
    extends State<SupplierFormScreen> {
  /*
  |--------------------------------------------------------------------------
  | API Service
  |--------------------------------------------------------------------------
  */

  final ApiService apiService = ApiService();

  /*
  |--------------------------------------------------------------------------
  | Controllers
  |--------------------------------------------------------------------------
  */

  late TextEditingController nameController;
  late TextEditingController brnController;
  late TextEditingController vatController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController addressController;

  /*
  |--------------------------------------------------------------------------
  | State
  |--------------------------------------------------------------------------
  */

  bool isSaving = false;
  bool isActive = true;

  bool get isEditing =>
      widget.supplier != null;

  @override
  void initState() {
    super.initState();

    final supplier =
        widget.supplier;

    nameController =
        TextEditingController(
      text: supplier?['name'] ?? '',
    );

    brnController =
        TextEditingController(
      text: supplier?['brn'] ?? '',
    );

    vatController =
        TextEditingController(
      text:
          supplier?['vat_number'] ??
              '',
    );

    phoneController =
        TextEditingController(
      text: supplier?['phone'] ?? '',
    );

    emailController =
        TextEditingController(
      text: supplier?['email'] ?? '',
    );

    addressController =
        TextEditingController(
      text:
          supplier?['address'] ??
              '',
    );

    isActive =
        supplier?['is_active'] ??
            true;
  }

  @override
  void dispose() {
    nameController.dispose();
    brnController.dispose();
    vatController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();

    super.dispose();
  }

  /*
  |--------------------------------------------------------------------------
  | Save Supplier
  |--------------------------------------------------------------------------
  */

  Future<void> saveSupplier() async {
    if (nameController.text
        .trim()
        .isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Supplier name is required',
          ),
          backgroundColor:
              Colors.red,
        ),
      );

      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      if (isEditing) {
        await apiService
            .updateSupplier(
          supplierId:
              widget.supplier!['id'],

          name:
              nameController.text
                  .trim(),

          brn:
              brnController.text
                  .trim(),

          vatNumber:
              vatController.text
                  .trim(),

          phone:
              phoneController.text
                  .trim(),

          email:
              emailController.text
                  .trim(),

          address:
              addressController.text
                  .trim(),

          isActive: isActive,
        );
      } else {
        await apiService
            .createSupplier(
          name:
              nameController.text
                  .trim(),

          brn:
              brnController.text
                  .trim(),

          vatNumber:
              vatController.text
                  .trim(),

          phone:
              phoneController.text
                  .trim(),

          email:
              emailController.text
                  .trim(),

          address:
              addressController.text
                  .trim(),

          isActive: isActive,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Supplier updated successfully'
                : 'Supplier created successfully',
          ),
          backgroundColor:
              Colors.green,
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text(e.toString()),
          backgroundColor:
              Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Input Field
  |--------------------------------------------------------------------------
  */

  Widget inputField({
    required String label,
    required TextEditingController
        controller,
    int maxLines = 1,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 16,
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,

        decoration: InputDecoration(
          labelText: label,

          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
                    14),
          ),
        ),
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Build
  |--------------------------------------------------------------------------
  */

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(
        0xFFF4F6FA,
      ),

      appBar: AppBar(
        title: Text(
          isEditing
              ? 'Edit Supplier'
              : 'New Supplier',
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 700,
          ),

          child: Padding(
            padding:
                const EdgeInsets.all(
              24,
            ),

            child: Container(
              padding:
                  const EdgeInsets.all(
                24,
              ),

              decoration:
                  BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(
                        24),

                boxShadow: [
                  BoxShadow(
                    color: Colors
                        .black
                        .withOpacity(
                            0.04),

                    blurRadius: 12,

                    offset:
                        const Offset(
                            0,
                            4),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [

                  const Text(
                    'Supplier Information',

                    style: TextStyle(
                      fontSize: 24,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                      height: 24),

                  Expanded(
                    child:
                        SingleChildScrollView(
                      child: Column(
                        children: [

                          inputField(
                            label:
                                'Supplier Name *',

                            controller:
                                nameController,
                          ),

                          inputField(
                            label: 'BRN',

                            controller:
                                brnController,
                          ),

                          inputField(
                            label:
                                'VAT Number',

                            controller:
                                vatController,
                          ),

                          inputField(
                            label: 'Phone',

                            controller:
                                phoneController,
                          ),

                          inputField(
                            label: 'Email',

                            controller:
                                emailController,
                          ),

                          inputField(
                            label:
                                'Address',

                            controller:
                                addressController,

                            maxLines: 3,
                          ),

                          SwitchListTile(
                            value:
                                isActive,

                            title:
                                const Text(
                              'Active Supplier',
                            ),

                            onChanged:
                                (value) {
                              setState(() {
                                isActive =
                                    value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                      height: 18),

                  SizedBox(
                    width:
                        double.infinity,

                    height: 54,

                    child:
                        ElevatedButton.icon(
                      onPressed:
                          isSaving
                              ? null
                              : saveSupplier,

                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,

                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                                color:
                                    Colors.white,
                              ),
                            )

                          : const Icon(
                              Icons.save,
                            ),

                      label: Text(
                        isEditing
                            ? 'Update Supplier'
                            : 'Create Supplier',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}