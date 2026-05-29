import 'package:flutter/material.dart';

class SnackbarHelper {
  /*
  |--------------------------------------------------------------------------
  | Success
  |--------------------------------------------------------------------------
  */

  static void success(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.green, content: Text(message)));
  }

  /*
  |--------------------------------------------------------------------------
  | Error
  |--------------------------------------------------------------------------
  */

  static void error(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(message)));
  }

  /*
  |--------------------------------------------------------------------------
  | Warning
  |--------------------------------------------------------------------------
  */

  static void warning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.orange, content: Text(message)));
  }

  /*
  |--------------------------------------------------------------------------
  | Info
  |--------------------------------------------------------------------------
  */

  static void info(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.blue, content: Text(message)));
  }
}
