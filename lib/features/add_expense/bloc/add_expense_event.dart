abstract class AddExpenseEvent {}


class SaveExpense extends AddExpenseEvent {
  final String category;
  final double amount;
  final DateTime date;
  final String currency;
  final String? receiptPath;
  SaveExpense({
    required this.category,
    required this.amount,
    required this.date,
    required this.currency,
    this.receiptPath,
  });
}