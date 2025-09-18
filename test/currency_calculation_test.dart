import 'package:expense_tracker_lite/core/utils/money_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatUSD formats correctly', () {
    expect(MoneyUtils.formatUSD(0), equals('\$0.00'));
    expect(MoneyUtils.formatUSD(1234.5), equals('\$1,234.50'));
    expect(MoneyUtils.formatUSD(-9.99), equals('-\$9.99'));
  });

  test('totals compute income/expenses/balance', () {
    final (balance, income, expenses) = MoneyUtils.totals([
      1000,
      -50,
      -30,
      200,
    ]);
    expect(income, 1200);
    expect(expenses, 80);
    expect(balance, 1120);
  });
}
