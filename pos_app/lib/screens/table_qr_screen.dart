import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/*
|--------------------------------------------------------------------------
| Table QR Screen
|--------------------------------------------------------------------------
*/

class TableQrScreen extends StatelessWidget {
  final Map<String, dynamic> table;
  final String serverUrl;

  const TableQrScreen({
    super.key,
    required this.table,
    required this.serverUrl,
  });

  @override
  Widget build(BuildContext context) {
    final cleanServerUrl = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;

    final qrUrl = '$cleanServerUrl/customer-menu/table/${table['id']}';

    return Scaffold(
      appBar: AppBar(title: Text('QR Code - ${table['table_name']}')),
      body: Center(
        child: Card(
          elevation: 5,
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  table['table_name'] ?? 'Table',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                QrImageView(data: qrUrl, size: 300),

                const SizedBox(height: 20),

                SelectableText(qrUrl, textAlign: TextAlign.center),

                const SizedBox(height: 20),

                const Text('Scan to open customer menu'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
