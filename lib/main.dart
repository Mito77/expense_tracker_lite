import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/models/expense_model.dart';
import 'data/models/fx_rates.dart';
import 'myApp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseModelAdapter());
  Hive.registerAdapter(FxRatesAdapter());

  final expenseBox = await Hive.openBox<ExpenseModel>('expenses');

  runApp(MyApp(expenseBox: expenseBox));
}
