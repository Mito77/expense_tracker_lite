import '../../data/models/expense_model.dart';

class ExpenseValidator {
  static List<String> validate(
    ExpenseModel e, {
    DateTime? now,
    double maxAbsAmount = 1e9,
  }) {
    final errors = <String>[];
    final localNow = (now ?? DateTime.now()).toLocal();

    final cat = (e.category).trim();
    if (cat.isEmpty) errors.add('Category is required.');

    final a = e.amount;
    if (a == 0) errors.add('Amount cannot be 0.');
    if (a.isNaN || !a.isFinite) errors.add('Amount must be a finite number.');
    if (a.abs() > maxAbsAmount) errors.add('Amount is unreasonably large.');

    final dt = e.date.toLocal();
    if (dt.isAfter(localNow)) {
      errors.add('Date cannot be in the future.');
    }

    final lower = DateTime(2000, 1, 1);
    if (dt.isBefore(lower)) {
      errors.add('Date is too old (before 2000).');
    }

    return errors;
  }
}
