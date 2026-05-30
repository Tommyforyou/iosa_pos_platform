import 'package:flutter/material.dart';

/*
|--------------------------------------------------------------------------
| Payment Status Color
|--------------------------------------------------------------------------
*/

class StatusHelper {
  static Color paymentStatusColor(String? status) {
    switch (status?.trim().toLowerCase() ?? '') {
      case 'paid':
        return Colors.green;

      case 'partial':
        return Colors.orange;

      case 'unpaid':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }
}
