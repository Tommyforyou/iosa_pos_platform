import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../utils/date_helper.dart';
import '../utils/snackbar_helper.dart';
import 'customer_detail_screen.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  /*
  |--------------------------------------------------------------------------
  | Services
  |--------------------------------------------------------------------------
  */

  final ApiService apiService = ApiService();

  /*
  |--------------------------------------------------------------------------
  | State
  |--------------------------------------------------------------------------
  */

  bool isLoading = true;

  List<dynamic> customers = [];
  final TextEditingController searchController = TextEditingController();

  String selectedFilter = 'all';

  /*
  |--------------------------------------------------------------------------
  | Init
  |--------------------------------------------------------------------------
  */

  @override
  void initState() {
    super.initState();

    loadCustomers();
  }

  /*
|--------------------------------------------------------------------------
| Filtered Customers
|--------------------------------------------------------------------------
*/

  List<dynamic> get filteredCustomers {
    final query = searchController.text.trim().toLowerCase();

    return customers.where((customer) {
      final name = (customer['name'] ?? '').toString().toLowerCase();

      final phone = (customer['phone'] ?? '').toString().toLowerCase();

      final matchesSearch = name.contains(query) || phone.contains(query);

      return matchesSearch;
    }).toList();
  }

  /*
  |--------------------------------------------------------------------------
  | Add Customer Dialog
  |--------------------------------------------------------------------------
  */

  Future<void> showAddCustomerDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    final brnController = TextEditingController();
    final vatController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Customer'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  TextField(
                    controller: brnController,
                    decoration: const InputDecoration(labelText: 'BRN'),
                  ),
                  TextField(
                    controller: vatController,
                    decoration: const InputDecoration(labelText: 'VAT Number'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final result = await apiService.createCustomer(
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    email: emailController.text.trim(),
                    address: addressController.text.trim(),
                    brn: brnController.text.trim(),
                    vatNumber: vatController.text.trim(),
                  );

                  //debugPrint(result.toString());
                  SnackbarHelper.success(context, 'Customer created successfully');
                  if (!mounted) return;

                  Navigator.pop(context);

                  loadCustomers();
                } catch (e) {
                  //debugPrint(e.toString());

                  SnackbarHelper.error(context, e.toString());
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
  /*
  |--------------------------------------------------------------------------
  | Load Customers
  |--------------------------------------------------------------------------
  */

  Future<void> loadCustomers() async {
    try {
      final result = await apiService.getCustomers();

      setState(() {
        customers = result;

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      debugPrint(e.toString());
    }
  }

  /*
  |--------------------------------------------------------------------------
  | UI
  |--------------------------------------------------------------------------
  */

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Management')),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddCustomerDialog,

        icon: const Icon(Icons.add),

        label: const Text('Add Customer'),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: const Color(0xFFF4F6FA),

              child: Column(
                children: [
                  /*
            |--------------------------------------------------------------------------
            | Search + Filters
            |--------------------------------------------------------------------------
            */
                  Container(
                    padding: const EdgeInsets.all(18),

                    decoration: const BoxDecoration(color: Colors.white),

                    child: Column(
                      children: [
                        TextField(
                          controller: searchController,

                          decoration: InputDecoration(
                            hintText: 'Search customer...',

                            prefixIcon: const Icon(Icons.search),

                            filled: true,

                            fillColor: Colors.grey.shade100,

                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),

                          onChanged: (_) {
                            setState(() {});
                          },
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            _FilterChip(
                              title: 'All',
                              selected: selectedFilter == 'all',

                              onTap: () {
                                setState(() {
                                  selectedFilter = 'all';
                                });
                              },
                            ),

                            const SizedBox(width: 10),

                            _FilterChip(
                              title: 'Outstanding',
                              selected: selectedFilter == 'outstanding',

                              onTap: () {
                                setState(() {
                                  selectedFilter = 'outstanding';
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  /*
            |--------------------------------------------------------------------------
            | Customer List
            |--------------------------------------------------------------------------
            */
                  Expanded(
                    child: filteredCustomers.isEmpty
                        ? const Center(child: Text('No customers found'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(18),

                            itemCount: filteredCustomers.length,

                            itemBuilder: (context, index) {
                              final customer = filteredCustomers[index];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),

                                padding: const EdgeInsets.all(20),

                                decoration: BoxDecoration(
                                  color: Colors.white,

                                  borderRadius: BorderRadius.circular(24),

                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6))],
                                ),

                                child: Row(
                                  children: [
                                    /*
                                    |--------------------------------------------------------------------------
                                    | Avatar
                                    |--------------------------------------------------------------------------
                              */
                                    CircleAvatar(
                                      radius: 28,

                                      backgroundColor: Colors.blue.shade50,

                                      child: Text(
                                        customer['name'].toString().substring(0, 1).toUpperCase(),

                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.blue),
                                      ),
                                    ),

                                    const SizedBox(width: 18),

                                    /*
                                    |--------------------------------------------------------------------------
                                    | Customer Info
                                    |--------------------------------------------------------------------------
                                    */
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,

                                        children: [
                                          Text(customer['name'] ?? '-', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                                          const SizedBox(height: 4),

                                          Text(customer['phone'] ?? '-'),

                                          if (customer['vat_number'] != null) Text('VAT: ${customer['vat_number']}'),
                                        ],
                                      ),
                                    ),

                                    /*
                                    |--------------------------------------------------------------------------
                                    | Outstanding Badge
                                    |--------------------------------------------------------------------------
                                    */
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

                                      decoration: BoxDecoration(
                                        color: (double.tryParse(customer['outstanding_balance']?.toString() ?? '0') ?? 0) > 0
                                            ? Colors.orange.shade50
                                            : Colors.green.shade50,

                                        borderRadius: BorderRadius.circular(18),
                                      ),

                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,

                                        children: [
                                          const Text('Outstanding', style: TextStyle(fontSize: 11, color: Colors.grey)),

                                          Text(
                                            'Rs ${money.format(double.tryParse(customer['outstanding_balance']?.toString() ?? '0') ?? 0)}',

                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,

                                              color: (double.tryParse(customer['outstanding_balance']?.toString() ?? '0') ?? 0) > 0
                                                  ? Colors.orange
                                                  : Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 14),

                                    /*
                                    |--------------------------------------------------------------------------
                                    | Actions
                                    |--------------------------------------------------------------------------
                                    */
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,

                                          MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: Map<String, dynamic>.from(customer))),
                                        );
                                      },

                                      icon: const Icon(Icons.visibility),

                                      label: const Text('Open'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.title, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),

        decoration: BoxDecoration(color: selected ? Colors.blue : Colors.grey.shade200, borderRadius: BorderRadius.circular(30)),

        child: Text(
          title,

          style: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
