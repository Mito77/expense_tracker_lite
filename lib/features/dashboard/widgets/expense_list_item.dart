import 'package:flutter/material.dart';
import '../../../data/models/expense_model.dart';

class ExpenseListItem extends StatelessWidget {
  final ExpenseModel expense;

  const ExpenseListItem({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.receipt_long, color: Colors.blue),
      title: Text(
        "${expense.category} - ${expense.amount} ${expense.currency}",
      ),
      subtitle: Text("USD: ${expense.usdAmount.toStringAsFixed(2)}"),
      trailing: Text(expense.date.toLocal().toString().split(' ')[0]),
    );
  }
}
