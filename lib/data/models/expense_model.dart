import 'package:hive/hive.dart';


part 'expense_model.g.dart';


@HiveType(typeId: 0)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String category;
  @HiveField(2)
  final double amount; // original amount (entered)
  @HiveField(3)
  final DateTime date; // expense date
  @HiveField(4)
  final String currency; // e.g., EGP, USD, EUR
  @HiveField(5)
  final double usdAmount; // converted to USD at save time
  @HiveField(6)
  final String? receiptPath; // optional local file path


  ExpenseModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.currency,
    required this.usdAmount,
    this.receiptPath,
  });
}