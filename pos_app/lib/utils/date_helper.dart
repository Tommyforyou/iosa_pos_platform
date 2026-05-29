import 'package:intl/intl.dart';

class DateHelper {
  /*
  |--------------------------------------------------------------------------
  | Format Date Time
  |--------------------------------------------------------------------------
  */

  static String formatDateTime(String? dateTime) {
    try {
      if (dateTime == null) {
        return '-';
      }

      final parsed = DateTime.parse(dateTime).toLocal();

      return DateFormat('dd/MM/yyyy HH:mm').format(parsed);
    } catch (e) {
      return dateTime ?? '-';
    }
  }
}
