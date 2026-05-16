import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  Future<List<dynamic>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load products');
  }

  Future<List<dynamic>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load categories');
  }

  Future<List<dynamic>> getRestaurantTables() async {
    final response = await http.get(Uri.parse('$baseUrl/restaurant-tables'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load restaurant tables');
  }

  Future<Map<String, dynamic>> saveRestaurantOrder({
    required int restaurantTableId,
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
        'items': items,
        'notes': notes,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to save order: ${response.body}');
  }

  Future<List<dynamic>> getKitchenOrders() async {
    final response = await http.get(Uri.parse('$baseUrl/kitchen-orders'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load kitchen orders');
  }

  Future<Map<String, dynamic>> getActiveOrderByTable(int tableId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/restaurant-tables/$tableId/active-order'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load active order');
  } 

}