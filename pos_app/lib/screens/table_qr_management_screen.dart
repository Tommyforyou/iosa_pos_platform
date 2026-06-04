import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'table_qr_screen.dart';
import 'dart:ui' as ui;
import 'package:qr/qr.dart';

/*
|--------------------------------------------------------------------------
| Table QR Management Screen
|--------------------------------------------------------------------------
| Generates QR codes for all restaurant tables.
*/

class TableQrManagementScreen extends StatefulWidget {
  const TableQrManagementScreen({super.key});

  @override
  State<TableQrManagementScreen> createState() =>
      _TableQrManagementScreenState();
}

class _TableQrManagementScreenState extends State<TableQrManagementScreen> {
  final ApiService apiService = ApiService();

  bool isLoading = true;

  List<dynamic> tables = [];

  String serverUrl = '';

  /*
  |--------------------------------------------------------------------------
  | Initial Load
  |--------------------------------------------------------------------------
  */

  @override
  void initState() {
    super.initState();

    loadData();
  }

  /*
  |--------------------------------------------------------------------------
  | Load Tables And Server URL
  |--------------------------------------------------------------------------
  */

  Future<void> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final tableData = await apiService.getRestaurantTables();

      if (!mounted) return;

      setState(() {
        serverUrl = prefs.getString('server_url') ?? '';
        tables = tableData;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Build QR URL
  |--------------------------------------------------------------------------
  */

  String qrUrl(dynamic table) {
    final cleanServerUrl = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;

    return '$cleanServerUrl/customer-menu/table/${table['id']}';
  }

  /*
|--------------------------------------------------------------------------
| Generate QR PDF
|--------------------------------------------------------------------------
*/

  Future<Uint8List> generatePdf() async {
    final pdf = pw.Document();

    /*
  |--------------------------------------------------------------------------
  | A4 Layout
  |--------------------------------------------------------------------------
  | 2 columns x 3 rows = 6 QR cards per page.
  */

    final chunks = <List<dynamic>>[];

    for (var i = 0; i < tables.length; i += 4) {
      chunks.add(
        tables.sublist(i, i + 4 > tables.length ? tables.length : i + 4),
      );
    }

    /*
  |--------------------------------------------------------------------------
  | Build PDF Pages
  |--------------------------------------------------------------------------
  */

    for (final pageTables in chunks) {
      final qrCards = await Future.wait(
        pageTables.map((table) => buildQrPdfCard(table)),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) {
            return pw.GridView(
              crossAxisCount: 2,
              childAspectRatio: 0.9,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: qrCards,
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  // Build Pdf Qr Code

  Future<pw.Widget> buildQrPdfCard(dynamic table) async {
    final tableName = table['table_name'] ?? 'Table';
    final url = qrUrl(table);

    /*
      |--------------------------------------------------------------------------
      | Generate QR Image
      |--------------------------------------------------------------------------
      */

    final qrImage = await generateQrImage(url);

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey600, width: 1),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            'IOSA RESTAURANT',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 8),

          pw.Text(
            tableName.toString().toUpperCase(),
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 14),

          /*
        |--------------------------------------------------------------------------
        | QR Image
        |--------------------------------------------------------------------------
        */
          pw.Image(qrImage, width: 130, height: 130),

          pw.SizedBox(height: 14),

          pw.Text(
            'Scan to View Menu',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),

          pw.Text('and Place Order', style: const pw.TextStyle(fontSize: 12)),

          pw.SizedBox(height: 8),

          pw.Text(
            url,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }
  /*
  |--------------------------------------------------------------------------
  | Print All QR Codes
  |--------------------------------------------------------------------------
  */

  Future<void> printAllQrCodes() async {
    final pdfBytes = await generatePdf();

    await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
  }

  /*
  |--------------------------------------------------------------------------
  | Build Screen
  |--------------------------------------------------------------------------
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Table QR Management'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: loadData),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tables.isEmpty
          ? const Center(child: Text('No tables found'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /*
                      |--------------------------------------------------------------------------
                      | Action Buttons
                      |--------------------------------------------------------------------------
                      */
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Preview / Print All QR'),
                          onPressed: printAllQrCodes,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /*
                      |--------------------------------------------------------------------------
                      | Table List
                      |--------------------------------------------------------------------------
                      */
                  Expanded(
                    child: ListView.builder(
                      itemCount: tables.length,
                      itemBuilder: (context, index) {
                        final table = tables[index];

                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.qr_code_2),
                            title: Text(
                              table['table_name'] ?? 'Table',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              qrUrl(table),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: ElevatedButton.icon(
                              icon: const Icon(Icons.visibility),
                              label: const Text('View QR'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TableQrScreen(
                                      table: table,
                                      serverUrl: serverUrl,
                                    ),
                                  ),
                                );
                              },
                            ),
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

  /*
|--------------------------------------------------------------------------
| Generate QR Image For PDF
|--------------------------------------------------------------------------
*/

  Future<pw.MemoryImage> generateQrImage(String data) async {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.H,
    );

    final qrImage = QrImage(qrCode);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    const imageSize = 500.0;
    const quietZone = 40.0;

    final qrSize = imageSize - (quietZone * 2);
    final moduleSize = qrSize / qrCode.moduleCount;

    final whitePaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);

    final blackPaint = ui.Paint()..color = const ui.Color(0xFF000000);

    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, imageSize, imageSize),
      whitePaint,
    );

    for (int row = 0; row < qrCode.moduleCount; row++) {
      for (int col = 0; col < qrCode.moduleCount; col++) {
        if (qrImage.isDark(row, col)) {
          canvas.drawRect(
            ui.Rect.fromLTWH(
              quietZone + (col * moduleSize),
              quietZone + (row * moduleSize),
              moduleSize + 0.4,
              moduleSize + 0.4,
            ),
            blackPaint,
          );
        }
      }
    }

    final picture = recorder.endRecording();

    final image = await picture.toImage(imageSize.toInt(), imageSize.toInt());

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return pw.MemoryImage(byteData!.buffer.asUint8List());
  }
}
