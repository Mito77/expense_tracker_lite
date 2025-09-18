import 'package:intl/intl.dart';

class MoneyUtils {
  static String formatUSD(double v) {
    final f = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    return f.format(v);
  }

  static (double balance, double income, double expenses) totals(Iterable<double> amounts) {
    double income = 0, expenses = 0;
    for (final x in amounts) {
      if (x >= 0) income += x;
      else expenses += -x;
    }
    return (income - expenses, income, expenses);
  }
}
