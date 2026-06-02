import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/*
|--------------------------------------------------------------------------
| Server QR Screen
|--------------------------------------------------------------------------
| Automatically detects the Windows POS local IP address and generates
| a QR code for waiter mobile devices.
*/

class ServerQrScreen extends StatefulWidget {
  const ServerQrScreen({super.key});

  @override
  State<ServerQrScreen> createState() => _ServerQrScreenState();
}

class _ServerQrScreenState extends State<ServerQrScreen> {
  /*
  |--------------------------------------------------------------------------
  | Detect Local Server URL
  |--------------------------------------------------------------------------
  */

  Future<String> getServerUrl() async {
    final interfaces = await NetworkInterface.list();

    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (address.type == InternetAddressType.IPv4 && !address.isLoopback && !address.address.startsWith('169.254')) {
          return 'http://${address.address}:8000';
        }
      }
    }

    throw Exception('Unable to detect server IP address.');
  }

  /*
  |--------------------------------------------------------------------------
  | Build Screen
  |--------------------------------------------------------------------------
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Server QR Code')),
      body: FutureBuilder<String>(
        future: getServerUrl(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString(), textAlign: TextAlign.center));
          }

          final serverUrl = snapshot.data!;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /*
                  |--------------------------------------------------------------------------
                  | QR Code
                  |--------------------------------------------------------------------------
                  */
                  QrImageView(data: serverUrl, size: 300),

                  const SizedBox(height: 24),

                  /*
                  |--------------------------------------------------------------------------
                  | Server URL
                  |--------------------------------------------------------------------------
                  */
                  Text(
                    serverUrl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  const Text('Scan this QR code from the Android Waiter App', textAlign: TextAlign.center),

                  const SizedBox(height: 24),

                  /*
                  |--------------------------------------------------------------------------
                  | Refresh
                  |--------------------------------------------------------------------------
                  */
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {});
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh IP'),
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
