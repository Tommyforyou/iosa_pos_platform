import 'package:flutter/material.dart';

import '../services/api_service.dart';

/*
|--------------------------------------------------------------------------
| Business Settings Screen
|--------------------------------------------------------------------------
*/

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() =>
      _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  final ApiService apiService = ApiService();

  final companyNameController = TextEditingController();
  final brnController = TextEditingController();
  final vatNumberController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final receiptFooterController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  bool mraEnabled = false;
  String defaultPrintFormat = 'thermal';

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  @override
  void dispose() {
    companyNameController.dispose();
    brnController.dispose();
    vatNumberController.dispose();
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();
    receiptFooterController.dispose();
    super.dispose();
  }

  Future<void> loadSettings() async {
    try {
      final settings = await apiService.getBusinessSettings();

      setState(() {
        companyNameController.text = settings['company_name'] ?? '';
        brnController.text = settings['brn'] ?? '';
        vatNumberController.text = settings['vat_number'] ?? '';
        addressController.text = settings['address'] ?? '';
        phoneController.text = settings['phone'] ?? '';
        emailController.text = settings['email'] ?? '';
        receiptFooterController.text = settings['receipt_footer'] ?? '';
        defaultPrintFormat = settings['default_print_format'] ?? 'thermal';
        mraEnabled = settings['mra_enabled'] ?? false;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> saveSettings() async {
    setState(() => isSaving = true);

    try {
      await apiService.updateBusinessSettings(
        data: {
          'company_name': companyNameController.text.trim(),
          'brn': brnController.text.trim(),
          'vat_number': vatNumberController.text.trim(),
          'address': addressController.text.trim(),
          'phone': phoneController.text.trim(),
          'email': emailController.text.trim(),
          'receipt_footer': receiptFooterController.text.trim(),
          'default_print_format': defaultPrintFormat,
          'mra_enabled': mraEnabled,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Business Settings'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: companyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Company Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: brnController,
                      decoration: const InputDecoration(
                        labelText: 'BRN',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: vatNumberController,
                      decoration: const InputDecoration(
                        labelText: 'VAT Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: addressController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: receiptFooterController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Receipt Footer',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: defaultPrintFormat,
                      decoration: const InputDecoration(
                        labelText: 'Default Print Format',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'thermal',
                          child: Text('Thermal Receipt'),
                        ),
                        DropdownMenuItem(
                          value: 'a4',
                          child: Text('A4 Invoice'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          defaultPrintFormat = value ?? 'thermal';
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      value: mraEnabled,
                      title: const Text('Enable MRA e-Invoicing'),
                      subtitle: const Text(
                        'Only enable this for businesses registered with MRA e-Invoicing.',
                      ),
                      onChanged: (value) {
                        setState(() => mraEnabled = value);
                      },
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : saveSettings,
                        icon: const Icon(Icons.save),
                        label: Text(isSaving ? 'Saving...' : 'Save Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}