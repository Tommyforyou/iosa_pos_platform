import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/*
|--------------------------------------------------------------------------
| Server QR Screen
|--------------------------------------------------------------------------
*/

class ServerQrScreen extends StatelessWidget {
  final String serverUrl;

  const ServerQrScreen({super.key, required this.serverUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Server QR Code')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(data: serverUrl, size: 300),

            const SizedBox(height: 20),

            Text(serverUrl, style: const TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            const Text('Scan this QR code from the Waiter App'),
          ],
        ),
      ),
    );
  }
}
