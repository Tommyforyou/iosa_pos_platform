import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/*
|--------------------------------------------------------------------------
| API Service
|--------------------------------------------------------------------------
| This service is the communication layer between Flutter and Laravel.
|
| The UI screens should not directly write HTTP logic. Instead, they call
| this service, and this service talks to the Laravel API.
|
| Main responsibilities:
| - Load products
| - Load categories
| - Load restaurant tables
| - Save dine-in / takeaway / delivery orders
| - Load active table orders
| - Load kitchen orders
| - Update kitchen item status
*/

class ApiService {
  /*
  |--------------------------------------------------------------------------
  | Base API URL
  |--------------------------------------------------------------------------
  | Windows desktop can use 127.0.0.1 when Laravel runs locally.
  |
  | Later note:
  | - Android emulator usually uses http://10.0.2.2:8000/api
  | - Real Android tablet must use the computer LAN IP address
  */
  static const String publicBaseUrl = 'http://127.0.0.1:8000';

  static const String baseUrl = '$publicBaseUrl/api';

  /*
  |--------------------------------------------------------------------------
  | Get Base URL
  |--------------------------------------------------------------------------
  */

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();

    final serverUrl = prefs.getString('server_url') ?? '';

    return '$serverUrl/api';
  }

  /*
  |--------------------------------------------------------------------------
  | Get Business Settings
  |--------------------------------------------------------------------------
  */

  Future<Map<String, dynamic>> getBusinessSettings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/business-settings'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to load business settings');
  }

  /*
|--------------------------------------------------------------------------
| Update Business Settings
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> updateBusinessSettings({
    required Map<String, dynamic> data,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/business-settings'),

      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },

      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to update business settings');
  }

  /*
|--------------------------------------------------------------------------
| Upload Business Logo
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> uploadBusinessLogo({
    required String filePath,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/business-settings/logo'),
    );

    request.headers['Accept'] = 'application/json';

    request.files.add(await http.MultipartFile.fromPath('logo', filePath));

    final response = await request.send();

    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(body));
    }

    throw Exception('Failed to upload business logo: $body');
  }

  /*
|--------------------------------------------------------------------------
| Supplier Balance
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> getSupplierBalance(int supplierId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/suppliers/$supplierId/balance'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to load supplier balance');
  }

  /*
|--------------------------------------------------------------------------
| Supplier Transactions
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> getSupplierTransactions(int supplierId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/suppliers/$supplierId/transactions'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to load supplier transactions');
  }

  /*
|--------------------------------------------------------------------------
| Supplier Outstanding Purchases
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> getSupplierOutstandingPurchases(
    int supplierId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/suppliers/$supplierId/outstanding-purchases'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to load outstanding purchases');
  }

  /*
|--------------------------------------------------------------------------
| Supplier Aging
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> getSupplierAging(int supplierId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/suppliers/$supplierId/aging'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to load supplier aging');
  }

  /*
|--------------------------------------------------------------------------
| Supplier Statement
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> getSupplierStatement(int supplierId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/suppliers/$supplierId/statement'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to load supplier statement');
  }

  /*
|--------------------------------------------------------------------------
| Customer Balance
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> getCustomerBalance(int customerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/customers/$customerId/balance'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to load customer balance');
  }

  /*
|--------------------------------------------------------------------------
| Customer Transactions
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> getCustomerTransactions(int customerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/customers/$customerId/transactions'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to load customer transactions');
  }

  /*
|--------------------------------------------------------------------------
| Record Customer Payment
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> recordCustomerPayment({
    required int customerId,
    required double amount,
    required String paymentMethod,
    String? reference,
    String? notes,
    required String paymentDate,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/customers/$customerId/payments'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'amount': amount,
        'payment_method': paymentMethod,
        'reference': reference,
        'notes': notes,
        'payment_date': paymentDate,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to record customer payment: ${response.body}');
  }

  /*
|--------------------------------------------------------------------------
| Record Customer Payment
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> recordSupplierPayment({
    required int supplierId,
    required double amount,
    required String paymentMethod,
    String? reference,
    String? notes,
    required String paymentDate,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/suppliers/$supplierId/payments'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'amount': amount,
        'payment_method': paymentMethod,
        'reference': reference,
        'notes': notes,
        'payment_date': paymentDate,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to record supplier payment: ${response.body}');
  }

  /*
  |--------------------------------------------------------------------------
  | Retry MRA Submission
  |--------------------------------------------------------------------------
  */

  Future<Map<String, dynamic>> retryMraSubmission(int saleId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sales/$saleId/retry-mra'),
      headers: {'Accept': 'application/json'},
    );

    return Map<String, dynamic>.from(jsonDecode(response.body));
  }

  /*
|--------------------------------------------------------------------------
| Get Products
|--------------------------------------------------------------------------
*/

  Future<List<dynamic>> getProducts({String? search}) async {
    final url = await apiUrl(
      search != null && search.isNotEmpty
          ? 'products?search=$search'
          : 'products',
    );

    debugPrint('PRODUCTS URL: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Failed to load products. Status: ${response.statusCode}. Body: ${response.body}',
    );
  }

  /*
|--------------------------------------------------------------------------
| Void Quick Sale
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> voidQuickSale({
    required int saleId,
    required String reason,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quick-sales/$saleId/void'),

      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },

      body: jsonEncode({'reason': reason}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to void sale: ${response.body}');
  }

  /*
  |--------------------------------------------------------------------------
  | Create Quick Sale
  |--------------------------------------------------------------------------
  */

  Future<Map<String, dynamic>> createQuickSale({
    int? customerId,
    required String saleType,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quick-sales'),

      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },

      body: jsonEncode({
        'customer_id': customerId,
        'sale_type': saleType,
        'payment_method': paymentMethod,
        'items': items,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    }

    throw Exception('Failed to create quick sale: ${response.body}');
  }
  /*
|--------------------------------------------------------------------------
| Quick Sale History
|--------------------------------------------------------------------------
*/

  Future<List<dynamic>> getQuickSalesHistory({
    String? from,
    String? to,
    String? search,
  }) async {
    final uri = Uri.parse('$baseUrl/quick-sales-history').replace(
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load quick sale history');
  }

  /*
  |--------------------------------------------------------------------------
  | Get Customers
  |--------------------------------------------------------------------------
  */

  Future<List<dynamic>> getCustomers({String? search}) async {
    final uri = Uri.parse('$baseUrl/customers').replace(
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load customers: ${response.body}');
  }

  /*
|--------------------------------------------------------------------------
| Create Customer
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> createCustomer({
    required String name,
    required String phone,
    String? brn,
    String? vatNumber,
    String? email,
    String? address,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/customers'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'brn': brn,
        'vat_number': vatNumber,
        'email': email,
        'address': address,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to create customer: ${response.body}');
  }

  /*
|--------------------------------------------------------------------------
| Update Customer
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> updateCustomer({
    required int customerId,
    required String name,
    String? phone,
    String? email,
    String? address,
    String? brn,
    String? vatNumber,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/customers/$customerId'),

      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },

      body: jsonEncode({
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'brn': brn,
        'vat_number': vatNumber,
      }),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to update customer: ${response.body}');
  }

  /*
|--------------------------------------------------------------------------
| Customer Aging Analysis
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> getCustomerAging(int customerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/customers/$customerId/aging'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to load customer aging');
  }

  /*
|--------------------------------------------------------------------------
| Customer Statement
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> getCustomerStatement(int customerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/customers/$customerId/statement'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to load customer statement');
  }

  /*
  |--------------------------------------------------------------------------
  | Get Outstanding Invoices
  |--------------------------------------------------------------------------
  */

  Future<Map<String, dynamic>> getOutstandingInvoices(int customerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/customers/$customerId/outstanding-invoices'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to load outstanding invoices');
  }

  /*
  |--------------------------------------------------------------------------
  | Get Outstanding Purchases
  |--------------------------------------------------------------------------
  */

  Future<Map<String, dynamic>> getOutstandingPurchases(int supplierId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/suppliers/$supplierId/outstanding-purchases'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to load outstanding purchases');
  }

  /*
  |--------------------------------------------------------------------------
  | Stock Movements
  |--------------------------------------------------------------------------
  | Gets Stock movements
  */

  Future<List<dynamic>> getStockMovements({
    String? product,
    String? movementType,
    String? from,
    String? to,
  }) async {
    final uri = Uri.parse('$baseUrl/stock-movements').replace(
      queryParameters: {
        if (product != null && product.isNotEmpty) 'product': product,
        if (movementType != null && movementType.isNotEmpty)
          'movement_type': movementType,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load stock movements: ${response.body}');
  }

  /*
  |--------------------------------------------------------------------------
  | Load Categories
  |--------------------------------------------------------------------------
  | Gets product/menu categories from Laravel.
  */
  Future<List<dynamic>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load categories');
  }

  /*
|--------------------------------------------------------------------------
| Convert Purchase Receipt To Purchase
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> convertPurchaseReceiptToPurchase({
    required int receiptId,
    required String paymentStatus,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/purchase-receipts/$receiptId/convert-to-purchase'),

      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },

      body: jsonEncode({'payment_status': paymentStatus}),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to convert receipt: ${response.body}');
  }

  /*
|--------------------------------------------------------------------------
| Get Purchases
|--------------------------------------------------------------------------
*/

  Future<List<dynamic>> getPurchases({
    String? from,
    String? to,
    String? supplier,
  }) async {
    final uri = Uri.parse('$baseUrl/purchases').replace(
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (supplier != null && supplier.isNotEmpty) 'supplier': supplier,
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load purchases');
  }

  /*
|--------------------------------------------------------------------------
| Get Suppliers
|--------------------------------------------------------------------------
*/

  Future<List<dynamic>> getSuppliers({String? search}) async {
    final uri = Uri.parse('$baseUrl/suppliers').replace(
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load suppliers');
  }

  /*
|--------------------------------------------------------------------------
| Create Supplier
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> createSupplier({
    required String name,
    String? brn,
    String? vatNumber,
    String? phone,
    String? email,
    String? address,
    bool isActive = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/suppliers'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'brn': brn,
        'vat_number': vatNumber,
        'phone': phone,
        'email': email,
        'address': address,
        'is_active': isActive,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to create supplier: ${response.body}');
  }

  /*
|--------------------------------------------------------------------------
| Update Supplier
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> updateSupplier({
    required int supplierId,
    required String name,
    String? brn,
    String? vatNumber,
    String? phone,
    String? email,
    String? address,
    bool isActive = true,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/suppliers/$supplierId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'brn': brn,
        'vat_number': vatNumber,
        'phone': phone,
        'email': email,
        'address': address,
        'is_active': isActive,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to update supplier: ${response.body}');
  }

  /*
|--------------------------------------------------------------------------
| Daily Z-Report
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> getDailyZReport({String? date}) async {
    final uri = Uri.parse(
      '$baseUrl/z-report/daily',
    ).replace(queryParameters: {if (date != null) 'date': date});

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load Z-Report: ${response.body}');
  }

  /*
|--------------------------------------------------------------------------
| Get Supplier Detail
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> getSupplierDetail({
    required int supplierId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/suppliers/$supplierId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load supplier detail');
  }

  /*
|--------------------------------------------------------------------------
| Get Purchase Detail
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> getPurchaseDetail({
    required int purchaseId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/purchases/$purchaseId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load purchase detail');
  }

  /*
|--------------------------------------------------------------------------
| Delete Purchase Receipt
|--------------------------------------------------------------------------
*/

  Future<void> deletePurchaseReceipt({required int receiptId}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/purchase-receipts/$receiptId'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete purchase receipt: ${response.body}');
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Run OCR
  |--------------------------------------------------------------------------
  */

  Future<Map<String, dynamic>> runPurchaseReceiptOcr({
    required int receiptId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/purchase-receipts/$receiptId/run-ocr'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to run OCR');
  }

  /*
  |--------------------------------------------------------------------------
  | Load Restaurant Tables
  |--------------------------------------------------------------------------
  | Gets dine-in table list and statuses.
  */
  Future<List<dynamic>> getRestaurantTables() async {
    final url = await apiUrl('restaurant-tables');

    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load restaurant tables: ${response.body}');
  }

  /*
|--------------------------------------------------------------------------
| Purchase Receipts List
|--------------------------------------------------------------------------
*/

  Future<List<dynamic>> getPurchaseReceipts() async {
    final response = await http.get(Uri.parse('$baseUrl/purchase-receipts'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load purchase receipts');
  }

  /*
|--------------------------------------------------------------------------
| Upload Purchase Receipt
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> uploadPurchaseReceipt({
    required String filePath,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/purchase-receipts/upload'),
    );

    request.headers['Accept'] = 'application/json';

    request.files.add(await http.MultipartFile.fromPath('document', filePath));

    final response = await request.send();

    final body = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(body);
    }

    throw Exception('Failed to upload purchase receipt: $body');
  }

  /*
  |--------------------------------------------------------------------------
  | Update Purchase Receipt
  |--------------------------------------------------------------------------
  */

  Future<Map<String, dynamic>> updatePurchaseReceipt({
    required int receiptId,
    String? supplierName,
    String? supplierBrn,
    String? supplierVatNumber,
    String? invoiceNumber,
    String? invoiceDate,
    double? subtotalExclVat,
    double? vatAmount,
    double? totalInclVat,
    String? status,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/purchase-receipts/$receiptId'),

      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },

      body: jsonEncode({
        'supplier_name': supplierName,
        'supplier_brn': supplierBrn,
        'supplier_vat_number': supplierVatNumber,
        'invoice_number': invoiceNumber,
        'invoice_date': invoiceDate,
        'subtotal_excl_vat': subtotalExclVat,
        'vat_amount': vatAmount,
        'total_incl_vat': totalInclVat,
        'status': status,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to update purchase receipt: ${response.body}');
  }

  /*
  |--------------------------------------------------------------------------
  | Save Restaurant Order
  |--------------------------------------------------------------------------
  | Sends an order from Flutter to Laravel.
  |
  | Supports:
  | - dine_in: requires restaurantTableId
  | - takeaway: table id can be null
  | - delivery: table id can be null
  */
  Future<Map<String, dynamic>> saveRestaurantOrder({
    int? restaurantTableId,
    required String orderType,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/restaurant-orders'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'restaurant_table_id': restaurantTableId,
        'order_type': orderType,
        'items': items,
        'notes': notes,
      }),
    );

    print('SAVE ORDER STATUS: ${response.statusCode}');
    print('SAVE ORDER BODY: ${response.body}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to save order: ${response.body}');
  }

  /*
  |--------------------------------------------------------------------------
  | Load Kitchen Orders
  |--------------------------------------------------------------------------
  | Gets all active orders that should appear on the kitchen display.
  */
  Future<List<dynamic>> getKitchenOrders() async {
    final url = await apiUrl('kitchen-orders');

    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load kitchen orders: ${response.body}');
  }

  /*
|--------------------------------------------------------------------------
| Get Active Order By Table
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> getActiveOrderByTable(int tableId) async {
    final url = await apiUrl('restaurant-tables/$tableId/active-order');

    debugPrint('ACTIVE ORDER URL: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: await authHeaders(),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception(
      'Failed to load active order. '
      'Status: ${response.statusCode}. '
      'Body: ${response.body}',
    );
  }

  /*
|--------------------------------------------------------------------------
| Kitchen Display Orders
|--------------------------------------------------------------------------
| Returns active kitchen workflow orders.
*/

  Future<List<dynamic>> getKitchenDisplayOrders() async {
    final response = await http.get(Uri.parse('$baseUrl/kitchen/orders'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['orders'] ?? [];
    }

    throw Exception('Failed to load kitchen orders');
  }
  /*
  |--------------------------------------------------------------------------
  | Search Customer By Phone
  |--------------------------------------------------------------------------
  */

  Future<Map<String, dynamic>?> searchCustomerByPhone(String phone) async {
    final response = await http.get(
      Uri.parse('$baseUrl/customers/search-by-phone?phone=$phone'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['customer'];
    }

    throw Exception('Failed to search customer');
  }

  /*
  |--------------------------------------------------------------------------
  | Update Kitchen Order Status
  |--------------------------------------------------------------------------
  | Kitchen workflow progression.
  |
  | sent_to_kitchen
  | -> preparing
  | -> ready
  | -> served
  */

  Future<void> updateKitchenOrderStatus({
    required int orderId,
    required String status,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/kitchen/orders/$orderId/status'),

      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },

      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update kitchen order status');
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Update Kitchen Item Status
  |--------------------------------------------------------------------------
  | Updates one kitchen item status.
  |
  | Valid statuses:
  | - pending
  | - preparing
  | - ready
  | - served
  | - cancelled
  */
  Future<Map<String, dynamic>> updateKitchenItemStatus({
    required int itemId,
    required String kitchenStatus,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/restaurant-order-items/$itemId/kitchen-status'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'kitchen_status': kitchenStatus}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to update kitchen status: ${response.body}');
  }

  /*
  |--------------------------------------------------------------------------
  | Load Billable Orders
  |--------------------------------------------------------------------------
  | Returns active restaurant orders that are ready for cashier billing.
  */
  Future<List<dynamic>> getBillableOrders() async {
    final url = await apiUrl('billable-orders');

    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load billable orders: ${response.body}');
  }

  /*
  |--------------------------------------------------------------------------
  | Process Restaurant Payment
  |--------------------------------------------------------------------------
  | Sends payment details to Laravel.
  |
  | Backend will:
  | - mark order as paid
  | - close the order
  | - release dine-in table if applicable
  */
  Future<Map<String, dynamic>> processRestaurantPayment({
    required int orderId,
    required String paymentMethod,
    required double subtotal,
    required double taxAmount,
    required double discountAmount,
    required double totalAmount,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/restaurant-orders/$orderId/payment'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'payment_method': paymentMethod,
        'subtotal': subtotal,
        'tax_amount': taxAmount,
        'discount_amount': discountAmount,
        'total_amount': totalAmount,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to process payment: ${response.body}');
  }

  /*
  |--------------------------------------------------------------------------
  | Load Dashboard Statistics
  |--------------------------------------------------------------------------
  | Returns operational POS dashboard metrics.
  */

  Future<Map<String, dynamic>> getDashboardStatistics() async {
    final url = await apiUrl('dashboard-stats');

    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to load dashboard statistics: ${response.body}');
  }

  /*
  |--------------------------------------------------------------------------
  | Sales History
  |--------------------------------------------------------------------------
  */

  Future<List<dynamic>> getSalesHistory({String? from, String? to}) async {
    final url = await apiUrl('sales-history');

    final uri = Uri.parse(url).replace(
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return List<dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to load sales history: ${response.body}');
  }

  /*
  |--------------------------------------------------------------------------
  | Load Daily Sales Report
  |--------------------------------------------------------------------------
  | Returns today's detailed POS sales report.
  */
  Future<Map<String, dynamic>> getDailySalesReport() async {
    final response = await http.get(Uri.parse('$baseUrl/reports/daily-sales'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load daily sales report');
  }

  /*
|--------------------------------------------------------------------------
| Save Draft Restaurant Order
|--------------------------------------------------------------------------
| Saves current cart as draft so items do not disappear if user leaves
| before sending to kitchen.
*/

  Future<Map<String, dynamic>> saveDraftRestaurantOrder({
    int? customerId,
    int? restaurantTableId,
    required String orderType,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    final url = await apiUrl('restaurant-orders/draft');

    debugPrint('SAVE DRAFT URL: $url');

    final response = await http.post(
      Uri.parse(url),
      headers: await authHeaders(),
      body: jsonEncode({
        'restaurant_table_id': restaurantTableId,
        'customer_id': customerId,
        'order_type': orderType,
        'items': items,
        'notes': notes,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception(
      'Failed to save draft order. '
      'Status: ${response.statusCode}. '
      'Body: ${response.body}',
    );
  }

  /*
|--------------------------------------------------------------------------
| Send Draft Items To Kitchen
|--------------------------------------------------------------------------
| Converts saved draft items into pending kitchen items.
*/

  Future<Map<String, dynamic>> sendDraftItemsToKitchen({
    required int orderId,
  }) async {
    final url = await apiUrl('restaurant-orders/$orderId/send-to-kitchen');

    debugPrint('SEND TO KITCHEN URL: $url');

    final response = await http.patch(
      Uri.parse(url),
      headers: await authHeaders(),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception(
      'Failed to send draft items to kitchen. '
      'Status: ${response.statusCode}. '
      'Body: ${response.body}',
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Process Counter Order Payment
  |--------------------------------------------------------------------------
  | Used by Counter POS / KFC-style workflow.
  |
  | Backend will:
  | - create takeaway order
  | - save items
  | - mark order as paid
  | - send items to kitchen
  | - return order for receipt
  */
  Future<Map<String, dynamic>> processCounterOrderPayment({
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    required double subtotal,
    required double taxAmount,
    required double discountAmount,
    required double discountPercentage,
    required double totalAmount,

    /*
    |--------------------------------------------------------------------------
    | Food Court Buzzer
    |--------------------------------------------------------------------------
    */
    String? buzzerNumber,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/counter-orders'),

      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },

      body: jsonEncode({
        'items': items,
        'payment_method': paymentMethod,
        'subtotal': subtotal,
        'tax_amount': taxAmount,
        'discount_amount': discountAmount,
        'discount_percentage': discountPercentage,
        'total_amount': totalAmount,

        /*
        |--------------------------------------------------------------------------
        | Buzzer Number
        |--------------------------------------------------------------------------
        */
        'buzzer_number': buzzerNumber,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to process counter order: ${response.body}');
  }

  /*
  |--------------------------------------------------------------------------
  | Void Restaurant Order Item
  |--------------------------------------------------------------------------
  | Used by cashier/manager to void a disputed item before payment.
  |
  | This does not delete the item from database.
  | It marks the item as voided for audit purposes.
  */
  Future<Map<String, dynamic>> voidRestaurantOrderItem({
    required int itemId,
    required String voidReason,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/restaurant-order-items/$itemId/void'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'void_reason': voidReason}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to void item: ${response.body}');
  }

  /*
  |--------------------------------------------------------------------------
  | Create Category
  |--------------------------------------------------------------------------
  */

  Future<void> createCategory({
    required String name,
    required int sortOrder,
    required bool isActive,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),

      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },

      body: jsonEncode({
        'name': name,
        'sort_order': sortOrder,
        'is_active': isActive,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create category');
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Update Category
  |--------------------------------------------------------------------------
  */

  Future<void> updateCategory({
    required int categoryId,
    required String name,
    required int sortOrder,
    required bool isActive,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/categories/$categoryId'),

      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },

      body: jsonEncode({
        'name': name,
        'sort_order': sortOrder,
        'is_active': isActive,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update category');
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Delete Category
  |--------------------------------------------------------------------------
  */

  Future<void> deleteCategory(int categoryId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/categories/$categoryId'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete category');
    }
  }

  /*
|--------------------------------------------------------------------------
| Get Active Categories
|--------------------------------------------------------------------------
*/

  Future<List<dynamic>> getActiveCategories() async {
    final url = await apiUrl('categories');

    debugPrint('CATEGORIES URL: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Failed to load categories. Status: ${response.statusCode}. Body: ${response.body}',
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Create Product
  |--------------------------------------------------------------------------
  */

  Future<void> createProduct({
    required int categoryId,
    required String name,
    required double sellingPrice,
    required double costPrice,
    required double stockQuantity,
    required double reorderLevel,
    required String unit,
    required bool vatApplicable,
    required double vatRate,
    required bool isActive,
    String? description,
    String productType = 'general',
    String? barcode,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),

      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },

      body: jsonEncode({
        'product_category_id': categoryId,
        'name': name,
        'product_type': productType,
        'cost_price': costPrice,
        'selling_price': sellingPrice,
        'stock_quantity': stockQuantity,
        'reorder_level': reorderLevel,
        'unit': unit,
        'vat_applicable': vatApplicable,
        'vat_rate': vatRate,
        'description': description,
        'is_active': isActive,
        'barcode': barcode,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create product');
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Update Product
  |--------------------------------------------------------------------------
  */

  Future<void> updateProduct({
    required int productId,
    required int categoryId,
    required String name,
    required double sellingPrice,
    required double costPrice,
    required double stockQuantity,
    required double reorderLevel,
    required String unit,
    required bool vatApplicable,
    required double vatRate,
    required bool isActive,
    String? description,
    String productType = 'general',
    String? barcode,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/products/$productId'),

      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },

      body: jsonEncode({
        'product_category_id': categoryId,
        'name': name,
        'product_type': productType,
        'cost_price': costPrice,
        'selling_price': sellingPrice,
        'stock_quantity': stockQuantity,
        'reorder_level': reorderLevel,
        'unit': unit,
        'vat_applicable': vatApplicable,
        'vat_rate': vatRate,
        'description': description,
        'is_active': isActive,
        'barcode': barcode,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update product');
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Delete Product
  |--------------------------------------------------------------------------
  */

  Future<void> deleteProduct(int productId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/products/$productId'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete product');
    }
  }
  /*
  |--------------------------------------------------------------------------
  | Upload Product Image
  |--------------------------------------------------------------------------
  */

  Future<void> uploadProductImage({
    required int productId,
    required String filePath,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/products/$productId/image'),
    );

    request.headers['Accept'] = 'application/json';

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        filePath,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('Failed to upload product image');
    }
  }

  /*
|--------------------------------------------------------------------------
| Get Printers
|--------------------------------------------------------------------------
*/

  Future<List<dynamic>> getPrinters() async {
    final url = await apiUrl('printers');

    final response = await http.get(
      Uri.parse(url),
      headers: await authHeaders(),
    );

    if (response.statusCode == 200) {
      return List<dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to load printers: ${response.body}');
  }

  /*
|--------------------------------------------------------------------------
| Create Printer
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> createPrinter(Map<String, dynamic> data) async {
    final url = await apiUrl('printers');

    final response = await http.post(
      Uri.parse(url),
      headers: await authHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to create printer: ${response.body}');
  }

  /*
|--------------------------------------------------------------------------
| Update Printer
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> updatePrinter(
    int id,
    Map<String, dynamic> data,
  ) async {
    final url = await apiUrl('printers/$id');

    final response = await http.put(
      Uri.parse(url),
      headers: await authHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to update printer: ${response.body}');
  }

  /*
|--------------------------------------------------------------------------
| Delete Printer
|--------------------------------------------------------------------------
*/

  Future<void> deletePrinter(int id) async {
    final url = await apiUrl('printers/$id');

    final response = await http.delete(
      Uri.parse(url),
      headers: await authHeaders(),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }

    throw Exception('Failed to delete printer: ${response.body}');
  }

  /*
  |--------------------------------------------------------------------------
  | Test Printer
  |--------------------------------------------------------------------------
  */

  Future<void> testPrinter(int id) async {
    final url = await apiUrl('printers/$id/test-print');

    final response = await http.post(
      Uri.parse(url),
      headers: await authHeaders(),
    );

    if (response.statusCode == 200) {
      return;
    }

    throw Exception('Failed to send test print: ${response.body}');
  }
  /*
  |--------------------------------------------------------------------------
  | Upload Category Image
  |--------------------------------------------------------------------------
  */

  Future<void> uploadCategoryImage({
    required int categoryId,
    required String filePath,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/categories/$categoryId/image'),
    );

    request.headers['Accept'] = 'application/json';

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        filePath,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('Failed to upload category image');
    }
  }

  /*
|--------------------------------------------------------------------------
| Accounts Payable Dashboard
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> getAccountsPayableDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/accounts-payable/dashboard'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to load accounts payable dashboard');
  }

  /*
|--------------------------------------------------------------------------
| VAT Summary Report
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> getVatSummary({
    required String from,
    required String to,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/vat-summary?from=$from&to=$to'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to load VAT summary: ${response.body}');
  }

  /*
|--------------------------------------------------------------------------
| Accounts Receivable Dashboard
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> getAccountsReceivableDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/accounts-receivable/dashboard'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to load accounts receivable dashboard');
  }

  /*
|--------------------------------------------------------------------------
| Profit & Loss Report
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> getProfitLoss({
    required String from,
    required String to,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/profit-loss?from=$from&to=$to'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to load Profit & Loss report');
  }
  /*
  |--------------------------------------------------------------------------
  | Waiter Mobile Module
  |--------------------------------------------------------------------------
  | Functions used by Android waiter devices.
  | Uses the existing restaurant order infrastructure.
  */

  /*
  |--------------------------------------------------------------------------
  | Get Waiter Orders
  |--------------------------------------------------------------------------
  */

  Future<List<dynamic>> getWaiterOrders() async {
    final url = await apiUrl('waiter-orders');

    debugPrint('WAITER ORDERS URL: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: await authHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return List<dynamic>.from(data['data']);
    }

    throw Exception(
      'Failed to load waiter orders. '
      'Status: ${response.statusCode}. '
      'Body: ${response.body}',
    );
  }
  /*
|--------------------------------------------------------------------------
| Request Bill
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> requestBill({required int orderId}) async {
    final url = await apiUrl('restaurant-orders/$orderId/request-bill');

    debugPrint('REQUEST BILL URL: $url');

    final response = await http.patch(
      Uri.parse(url),
      headers: await authHeaders(),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception(
      'Failed to request bill. '
      'Status: ${response.statusCode}. '
      'Body: ${response.body}',
    );
  }

  /*
  |--------------------------------------------------------------------------
  | Waiter Login
  |--------------------------------------------------------------------------
  */

  Future<Map<String, dynamic>> waiterLogin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(await apiUrl('mobile/login')),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('LOGIN STATUS: ${response.statusCode}');
      debugPrint('LOGIN BODY: ${response.body}');

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }

      throw Exception(
        'Login failed. Status: ${response.statusCode}. Body: ${response.body}',
      );
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');
      rethrow;
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Authenticated Headers
  |--------------------------------------------------------------------------
  | Builds standard JSON headers and attaches the Sanctum token when available.
  */

  Future<Map<String, String>> authHeaders() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('auth_token');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /*
|--------------------------------------------------------------------------
| Get Current User
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/mobile/me'),
      headers: await authHeaders(),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to retrieve current user');
  }

  /*
|--------------------------------------------------------------------------
| API URL Helper
|--------------------------------------------------------------------------
*/

  Future<String> apiUrl(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();

    final serverUrl = prefs.getString('server_url');

    if (serverUrl == null || serverUrl.isEmpty) {
      throw Exception(
        'Server URL not configured. Please open Server Settings.',
      );
    }

    final cleanServerUrl = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;

    final cleanEndpoint = endpoint.startsWith('/')
        ? endpoint.substring(1)
        : endpoint;

    final url = '$cleanServerUrl/api/$cleanEndpoint';

    debugPrint('API URL: $url');

    return url;
  }

  /*
|--------------------------------------------------------------------------
| Test Server Connection
|--------------------------------------------------------------------------
*/

  Future<bool> testConnection(String serverUrl) async {
    try {
      final cleanServerUrl = serverUrl.endsWith('/')
          ? serverUrl.substring(0, serverUrl.length - 1)
          : serverUrl;

      final response = await http
          .get(
            Uri.parse('$cleanServerUrl/api/health'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('TEST CONNECTION ERROR: $e');
      return false;
    }
  }
  /*
|--------------------------------------------------------------------------
| Get Customer QR Orders
|--------------------------------------------------------------------------
*/

  Future<List<dynamic>> getCustomerOrders() async {
    final url = await apiUrl('customer-orders');

    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return List<dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to load customer orders: ${response.body}');
  }

  /*
|--------------------------------------------------------------------------
| Approve Customer QR Order
|--------------------------------------------------------------------------
*/

  Future<void> approveCustomerOrder(int orderId) async {
    final url = await apiUrl('customer-orders/$orderId/approve');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return;
    }

    throw Exception('Failed to approve customer order: ${response.body}');
  }

  /*
|--------------------------------------------------------------------------
| Reject Customer QR Order
|--------------------------------------------------------------------------
*/

  Future<void> rejectCustomerOrder(int orderId) async {
    final url = await apiUrl('customer-orders/$orderId/reject');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return;
    }

    throw Exception('Failed to reject customer order: ${response.body}');
  }

  /*
|--------------------------------------------------------------------------
| Get Customer Orders Count
|--------------------------------------------------------------------------
*/

  Future<int> getCustomerOrdersCount() async {
    final url = await apiUrl('customer-orders-count');

    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['count'] ?? 0;
    }

    return 0;
  }

  /*
|--------------------------------------------------------------------------
| Create Kiosk Order
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> createKioskOrder({
    required String orderType,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    final url = await apiUrl('kiosk-orders');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'order_type': orderType,
        'items': items,
        'notes': notes,
      }),
    );

    print('KIOSK ORDER STATUS: ${response.statusCode}');
    print('KIOSK ORDER BODY: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to create kiosk order: ${response.body}');
  }

  /*
|--------------------------------------------------------------------------
| Get Pending Kiosk Orders
|--------------------------------------------------------------------------
*/

  Future<List<dynamic>> getPendingKioskOrders() async {
    final url = await apiUrl('kiosk-pending-orders');

    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load kiosk orders');
  }
  /*
|--------------------------------------------------------------------------
| Receive Kiosk Payment
|--------------------------------------------------------------------------
*/

  Future<void> payKioskOrder({
    required int orderId,
    required String paymentMethod,
  }) async {
    final url = await apiUrl('kiosk-orders/$orderId/pay');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'payment_method': paymentMethod}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to receive payment');
    }
  }
  /*
|--------------------------------------------------------------------------
| Add Purchase Receipt Line
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> addPurchaseReceiptLine({
    required int receiptId,
    required String description,
    required double quantity,
    required double unitPrice,
    required double lineTotal,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/purchase-receipts/$receiptId/lines'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'description': description,
        'quantity': quantity,
        'unit_price': unitPrice,
        'line_total': lineTotal,
      }),
    );

    return jsonDecode(response.body);
  }

  /*
|--------------------------------------------------------------------------
| Update Purchase Receipt Line
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> updatePurchaseReceiptLine({
    required int lineId,
    required String description,
    required double quantity,
    required double unitPrice,
    required double lineTotal,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/purchase-receipt-lines/$lineId'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'description': description,
        'quantity': quantity,
        'unit_price': unitPrice,
        'line_total': lineTotal,
      }),
    );

    return jsonDecode(response.body);
  }

  /*
|--------------------------------------------------------------------------
| Delete Purchase Receipt Line
|--------------------------------------------------------------------------
*/

  Future<Map<String, dynamic>> deletePurchaseReceiptLine(int lineId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/purchase-receipt-lines/$lineId'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    return jsonDecode(response.body);
  }
}
