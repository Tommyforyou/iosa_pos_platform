import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:http_parser/http_parser.dart';

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
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  /*
  |--------------------------------------------------------------------------
  | Load Products
  |--------------------------------------------------------------------------
  | Gets active products/menu items from Laravel.
  */
  Future<List<dynamic>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load products');
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
    final response = await http.get(Uri.parse('$baseUrl/restaurant-tables'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load restaurant tables');
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
    final response = await http.get(Uri.parse('$baseUrl/kitchen-orders'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load kitchen orders');
  }

  /*
  |--------------------------------------------------------------------------
  | Load Active Order By Table
  |--------------------------------------------------------------------------
  | Used when a waiter reopens an occupied table.
  */
  Future<Map<String, dynamic>> getActiveOrderByTable(int tableId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/restaurant-tables/$tableId/active-order'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load active order');
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
  | Create Customer
  |--------------------------------------------------------------------------
  */

  Future<Map<String, dynamic>> createCustomer({
    required String name,
    required String phone,
    String? address,
    String? email,
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
        'address': address,
        'email': email,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to create customer');
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
    final response = await http.get(Uri.parse('$baseUrl/billable-orders'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load billable orders');
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
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await http.get(Uri.parse('$baseUrl/dashboard-stats'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load dashboard statistics');
  }

  /*
  |--------------------------------------------------------------------------
  | Sales History
  |--------------------------------------------------------------------------
  */

  Future<List<dynamic>> getSalesHistory({String? from, String? to}) async {
    final uri = Uri.parse('$baseUrl/sales-history').replace(
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load sales history');
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
    final response = await http.post(
      Uri.parse('$baseUrl/restaurant-orders/draft'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'restaurant_table_id': restaurantTableId,
        'customer_id': customerId,
        'order_type': orderType,
        'items': items,
        'notes': notes,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to save draft order: ${response.body}');
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
    final response = await http.patch(
      Uri.parse('$baseUrl/restaurant-orders/$orderId/send-to-kitchen'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to send draft items to kitchen: ${response.body}');
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
  | Load Active Categories
  |--------------------------------------------------------------------------
  | Used by POS ordering screens.
  | Back Office uses getCategories() to show all categories.
  */
  Future<List<dynamic>> getActiveCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/active-categories'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load active categories');
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
}
