import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker_lite/core/validation/expense_validator.dart';
import 'package:expense_tracker_lite/data/models/expense_model.dart';

ExpenseModel exp({
  double amount = -50.0,
  String category = 'Food',
  DateTime? date,
  String id = 'test-1',
  String currency = 'USD',
  double? usdAmount,
}) {
  final d = date ?? DateTime(2025, 9, 17, 10);
  final usd = usdAmount ?? amount;
  return ExpenseModel(
    amount: amount,
    category: category,
    date: d,
    id: id,
    currency: currency,
    usdAmount: usd,
  );
}

void main() {
  group('ExpenseValidator', () {
    final fixedNow = DateTime(2025, 9, 18, 12);

    test('valid expense passes', () {
      final e = exp();
      final errors = ExpenseValidator.validate(e, now: fixedNow);
      expect(errors, isEmpty);
    });

    test('fails: empty category, zero amount, future date', () {
      final e = exp(
        amount: 0,
        category: '   ',
        date: DateTime(2025, 12, 1),
        usdAmount: 0,
      );
      final errors = ExpenseValidator.validate(e, now: fixedNow);
      expect(errors, contains('Category is required.'));
      expect(errors, contains('Amount cannot be 0.'));
      expect(errors, contains('Date cannot be in the future.'));
    });

    test('fails: non-finite and huge amount', () {
      final eInf = exp(amount: double.infinity);
      final errsInf = ExpenseValidator.validate(
        eInf,
        now: fixedNow,
        maxAbsAmount: 1000,
      );
      expect(errsInf, contains('Amount must be a finite number.'));

      final eHuge = exp(amount: 1001);
      final errsHuge = ExpenseValidator.validate(
        eHuge,
        now: fixedNow,
        maxAbsAmount: 1000,
      );
      expect(errsHuge, contains('Amount is unreasonably large.'));
    });
  });
}
