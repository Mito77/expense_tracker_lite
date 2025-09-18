// lib/myApp.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import 'data/models/expense_model.dart';
import 'data/datasources/currency_remote_datasource.dart';
import 'data/repositories/currency_repository.dart';
import 'features/add_expense/bloc/add_expense_bloc.dart';
import 'features/dashboard/bloc/dashboard_bloc.dart';
import 'features/dashboard/bloc/dashboard_event.dart';
import 'features/dashboard/screens/dashboard_screen.dart';

class MyApp extends StatelessWidget {
  final Box<ExpenseModel> expenseBox;

  const MyApp({super.key, required this.expenseBox});

  @override
  Widget build(BuildContext context) {

    final currencyRepo = CurrencyRepository(
      CurrencyRemoteDataSource(http.Client()),
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create:
              (_) => DashboardBloc(expenseBox)
                ..add(LoadExpenses(page: 1, filter: DashboardFilter.thisMonth)),
        ),
        BlocProvider(create: (_) => AddExpenseBloc(expenseBox, currencyRepo)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Expense Tracker Lite',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF3A6FF7),
          scaffoldBackgroundColor: const Color(0xFFF7F8FB),
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}
