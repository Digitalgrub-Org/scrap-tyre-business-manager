import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  static final compactCurrency = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );
  static final date = DateFormat('dd MMM yyyy');
  static final databaseDate = DateFormat('yyyy-MM-dd');
  static final quantity = NumberFormat('#,##0.##', 'en_IN');

  static String money(double value) => currency.format(value);

  static String compactMoney(double value) => compactCurrency.format(value);

  static String weight(double value) => '${quantity.format(value)} kg';
}
