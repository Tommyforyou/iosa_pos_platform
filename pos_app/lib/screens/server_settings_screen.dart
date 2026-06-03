import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

/*
|--------------------------------------------------------------------------
| Server Settings Screen
|--------------------------------------------------------------------------
*/

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  final ApiService apiService = ApiService();

  final serverController = TextEditingController();

  bool isTesting = false;
  bool? isConnected;

  @override
  void initState() {
    super.initState();
    loadServerUrl();
  }

  @override
  void dispose() {
    serverController.dispose();
    super.dispose();
  }

  /*
  |--------------------------------------------------------------------------
  | Load Saved Server URL
  |--------------------------------------------------------------------------
  */

  Future<void> loadServerUrl() async {
    final prefs = await SharedPreferences.getInstance();

    serverController.text =
        prefs.getString('server_url') ?? 'http://127.0.0.1:8000';
  }

  /*
  |--------------------------------------------------------------------------
  | Test Connection
  |--------------------------------------------------------------------------
  */

  Future<void> testConnection() async {
    setState(() {
      isTesting = true;
      isConnected = null;
    });

    final result = await apiService.testConnection(
      serverController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      isTesting = false;
      isConnected = result;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result ? 'Server connection successful' : 'Server connection failed',
        ),
        backgroundColor: result ? Colors.green : Colors.red,
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Save Server URL
  |--------------------------------------------------------------------------
  */

  Future<void> saveServerUrl() async {
    final serverUrl = serverController.text.trim();

    if (serverUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter server URL'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('server_url', serverUrl);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Server URL saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Build
  |--------------------------------------------------------------------------
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Server Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Server Configuration',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  const Text('Enter the Laravel POS server address.'),

                  const SizedBox(height: 20),

                  TextField(
                    controller: serverController,
                    decoration: const InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'http://192.168.100.3:8000',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.dns),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (isConnected != null)
                    Row(
                      children: [
                        Icon(
                          isConnected! ? Icons.check_circle : Icons.error,
                          color: isConnected! ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isConnected! ? 'Connected' : 'Connection failed',
                          style: TextStyle(
                            color: isConnected! ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isTesting ? null : testConnection,
                          icon: isTesting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.wifi_tethering),
                          label: Text(
                            isTesting ? 'Testing...' : 'Test Connection',
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: saveServerUrl,
                          icon: const Icon(Icons.save),
                          label: const Text('Save'),
                        ),
                      ),
                    ],
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
