import 'package:flutter/material.dart';
import '../services/api_service.dart';

/*
|--------------------------------------------------------------------------
| Printer Settings Screen
|--------------------------------------------------------------------------
| Manage network thermal printers for kitchen, bar and cashier.
*/

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final ApiService apiService = ApiService();

  final nameController = TextEditingController(text: 'Kitchen Printer');
  final ipController = TextEditingController();
  final portController = TextEditingController(text: '9100');

  List<dynamic> printers = [];

  String location = 'kitchen';
  bool autoPrint = true;
  bool isActive = true;
  bool isLoading = true;
  int? selectedPrinterId;

  @override
  void initState() {
    super.initState();
    loadPrinters();
  }

  @override
  void dispose() {
    nameController.dispose();
    ipController.dispose();
    portController.dispose();
    super.dispose();
  }

  /*
  |--------------------------------------------------------------------------
  | Load Printers
  |--------------------------------------------------------------------------
  */

  Future<void> loadPrinters() async {
    try {
      final data = await apiService.getPrinters();

      setState(() {
        printers = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      showMessage(e.toString(), isError: true);
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Save Printer
  |--------------------------------------------------------------------------
  */

  Future<void> savePrinter() async {
    if (nameController.text.trim().isEmpty || ipController.text.trim().isEmpty || portController.text.trim().isEmpty) {
      showMessage('Please fill all required fields', isError: true);
      return;
    }

    final payload = {
      'name': nameController.text.trim(),
      'ip_address': ipController.text.trim(),
      'port': int.tryParse(portController.text.trim()) ?? 9100,
      'location': location,
      'auto_print': autoPrint,
      'is_active': isActive,
    };

    try {
      if (selectedPrinterId == null) {
        await apiService.createPrinter(payload);
      } else {
        await apiService.updatePrinter(selectedPrinterId!, payload);
      }

      clearForm();
      await loadPrinters();

      showMessage('Printer saved successfully');
    } catch (e) {
      showMessage(e.toString(), isError: true);
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Edit Printer
  |--------------------------------------------------------------------------
  */

  void editPrinter(dynamic printer) {
    setState(() {
      selectedPrinterId = printer['id'];

      nameController.text = printer['name'] ?? '';
      ipController.text = printer['ip_address'] ?? '';
      portController.text = '${printer['port'] ?? 9100}';

      location = printer['location'] ?? 'kitchen';
      autoPrint = printer['auto_print'] == true;
      isActive = printer['is_active'] == true;
    });
  }

  /*
  |--------------------------------------------------------------------------
  | Delete Printer
  |--------------------------------------------------------------------------
  */

  Future<void> deletePrinter(int id) async {
    try {
      await apiService.deletePrinter(id);

      clearForm();
      await loadPrinters();

      showMessage('Printer deleted successfully');
    } catch (e) {
      showMessage(e.toString(), isError: true);
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Test Print
  |--------------------------------------------------------------------------
  */

  Future<void> testPrint(int id) async {
    try {
      await apiService.testPrinter(id);

      showMessage('Test print sent');
    } catch (e) {
      showMessage(e.toString(), isError: true);
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Clear Form
  |--------------------------------------------------------------------------
  */

  void clearForm() {
    setState(() {
      selectedPrinterId = null;

      nameController.text = 'Kitchen Printer';
      ipController.clear();
      portController.text = '9100';

      location = 'kitchen';
      autoPrint = true;
      isActive = true;
    });
  }

  /*
  |--------------------------------------------------------------------------
  | Message
  |--------------------------------------------------------------------------
  */

  void showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green));
  }

  /*
  |--------------------------------------------------------------------------
  | Build Screen
  |--------------------------------------------------------------------------
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Printer Settings')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: formPanel()),
                            const SizedBox(width: 16),
                            Expanded(child: printerListPanel()),
                          ],
                        )
                      : ListView(children: [formPanel(), const SizedBox(height: 16), printerListPanel()]),
                );
              },
            ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Form Panel
  |--------------------------------------------------------------------------
  */

  Widget formPanel() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(selectedPrinterId == null ? 'Add Printer' : 'Edit Printer', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

            const SizedBox(height: 18),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Printer Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.print)),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                hintText: '192.168.100.50',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.router),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Port', border: OutlineInputBorder(), prefixIcon: Icon(Icons.settings_ethernet)),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: location,
              decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder(), prefixIcon: Icon(Icons.place)),
              items: const [
                DropdownMenuItem(value: 'kitchen', child: Text('Kitchen')),
                DropdownMenuItem(value: 'bar', child: Text('Bar')),
                DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  location = value;
                });
              },
            ),

            const SizedBox(height: 12),

            SwitchListTile(
              value: autoPrint,
              title: const Text('Auto Print'),
              onChanged: (value) {
                setState(() {
                  autoPrint = value;
                });
              },
            ),

            SwitchListTile(
              value: isActive,
              title: const Text('Active'),
              onChanged: (value) {
                setState(() {
                  isActive = value;
                });
              },
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(onPressed: savePrinter, icon: const Icon(Icons.save), label: const Text('Save')),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(onPressed: clearForm, icon: const Icon(Icons.clear), label: const Text('Clear')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Printer List Panel
  |--------------------------------------------------------------------------
  */

  Widget printerListPanel() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Configured Printers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

            const SizedBox(height: 12),

            if (printers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('No printers configured')),
              )
            else
              ...printers.map((printer) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.print),
                    title: Text(printer['name'] ?? 'Printer'),
                    subtitle: Text('${printer['ip_address']}:${printer['port']} • ${printer['location']}'),
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        IconButton(tooltip: 'Test Print', icon: const Icon(Icons.receipt_long), onPressed: () => testPrint(printer['id'])),
                        IconButton(tooltip: 'Edit', icon: const Icon(Icons.edit), onPressed: () => editPrinter(printer)),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deletePrinter(printer['id']),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
