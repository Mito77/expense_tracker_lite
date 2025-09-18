import 'package:hive/hive.dart';
import '../models/expense_model.dart';

class LocalDataSource {
  static const String expenseBoxName = "expenses_box";

  Future<void> init() async {
    await Hive.openBox<ExpenseModel>(expenseBoxName);
  }

  Future<void> addExpense(ExpenseModel expense) async {
    final box = Hive.box<ExpenseModel>(expenseBoxName);
    await box.put(expense.id, expense);
  }

  List<ExpenseModel> getExpenses() {
    final box = Hive.box<ExpenseModel>(expenseBoxName);
    return box.values.toList();
  }
}
