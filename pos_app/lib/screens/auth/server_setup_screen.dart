import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';

/*
|--------------------------------------------------------------------------
| Server Setup Screen
|--------------------------------------------------------------------------
| Scans a QR code containing the Laravel server address.
|
| Example QR value:
| http://192.168.1.25:8000
*/

class ServerSetupScreen extends StatefulWidget {
  ServerSetupScreen({super.key});

  @override
  State<ServerSetupScreen> createState() => _ServerSetupScreenState();
}

class _ServerSetupScreenState extends State<ServerSetupScreen> {
  bool hasScanned = false;

  /*
  |--------------------------------------------------------------------------
  | Save Server URL
  |--------------------------------------------------------------------------
  */

  Future<void> saveServerUrl(String rawValue) async {
    if (hasScanned) return;

    setState(() {
      hasScanned = true;
    });

    final serverUrl = rawValue.trim().replaceAll('/api', '');

    debugPrint('SAVED SERVER URL: $serverUrl');

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('server_url', serverUrl);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Server saved: $serverUrl')));

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  /*
  |--------------------------------------------------------------------------
  | Build Screen
  |--------------------------------------------------------------------------
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Server Setup')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Scan the IOSA POS server QR code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),

          Expanded(
            child: MobileScanner(
              onDetect: (capture) {
                final barcodes = capture.barcodes;

                if (barcodes.isEmpty) return;

                final value = barcodes.first.rawValue;

                if (value == null || value.isEmpty) return;

                saveServerUrl(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
