import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final currency = NumberFormat.currency(
    symbol: 'EGP ',
    decimalDigits: 2,
  );
  static final compactCurrency = NumberFormat.currency(
    symbol: 'EGP ',
    decimalDigits: 0,
  );
  static final date = DateFormat('yyyy-MM-dd');
  static final dateTime = DateFormat('yyyy-MM-dd HH:mm');

  static String invoiceNumber(String id) =>
      'INV-${id.replaceAll('-', '').substring(0, 8).toUpperCase()}';
}
