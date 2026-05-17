import 'package:intl/intl.dart';

/*
|--------------------------------------------------------------------------
| Money Formatter
|--------------------------------------------------------------------------
| Central formatter for all POS money displays.
|
| Purpose:
| - Always show commas
| - Always show 2 decimal places
| - Prevent formatting errors when API values arrive as string/number/null
|
| Examples:
| Rs 1,250.00
| Rs 12,500.50
| Rs 125,000.75
*/

final NumberFormat moneyFormatter = NumberFormat('#,##0.00');

/*
|--------------------------------------------------------------------------
| Convert Dynamic Value To Double
|--------------------------------------------------------------------------
| Laravel/PostgreSQL values may arrive in Flutter as:
| - int
| - double
| - string
| - null
|
| This helper safely converts them.
*/

double toMoneyDouble(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is int) {
    return value.toDouble();
  }

  if (value is double) {
    return value;
  }

  return double.tryParse(value.toString()) ?? 0;
}

/*
|--------------------------------------------------------------------------
| Format Money With Currency
|--------------------------------------------------------------------------
| Main helper used by all POS screens.
*/

String formatMoney(dynamic value) {
  return 'Rs ${moneyFormatter.format(toMoneyDouble(value))}';
}