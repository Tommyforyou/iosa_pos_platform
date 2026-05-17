import 'package:intl/intl.dart';

/*
|--------------------------------------------------------------------------
| Currency Formatter
|--------------------------------------------------------------------------
| Reusable formatter for POS financial displays.
|
| Examples:
| Rs 1,250.00
| Rs 12,500.50
| Rs 125,000.75
*/

final currencyFormatter =
    NumberFormat('#,##0.00');