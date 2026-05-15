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
}