import 'dart:convert';
import 'package:http/http.dart' as http;

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
      body: jsonEncode({
        'kitchen_status': kitchenStatus,
      }),
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
    final response = await http.get(
      Uri.parse('$baseUrl/billable-orders'),
    );

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
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard-stats'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load dashboard statistics');
  }
  /*
  |--------------------------------------------------------------------------
  | Load Daily Sales Report
  |--------------------------------------------------------------------------
  | Returns today's detailed POS sales report.
  */
  Future<Map<String, dynamic>> getDailySalesReport() async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/daily-sales'),
    );

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
      body: jsonEncode({
        'void_reason': voidReason,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to void item: ${response.body}');
  }

}