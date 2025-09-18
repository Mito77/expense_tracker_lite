import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/repositories/currency_repository.dart';
import 'add_expense_event.dart';
import 'add_expense_state.dart';


class AddExpenseBloc extends Bloc<AddExpenseEvent, AddExpenseState> {
  final Box<ExpenseModel> expenseBox;
  final CurrencyRepository currencyRepository;


  AddExpenseBloc(this.expenseBox, this.currencyRepository) : super(AddExpenseInitial()) {
    on<SaveExpense>(_onSaveExpense);
    print('[AddExpenseBloc] ready');
  }

  Future<void> _onSaveExpense(SaveExpense e, Emitter<AddExpenseState> emit) async {
    print('[AddExpenseBloc] received SaveExpense: ${e.category}, ${e.amount} ${e.currency}');
    emit(AddExpenseLoading());
    try {

      final usdAmount = await currencyRepository
          .convertToUSD(e.amount, e.currency)
          .timeout(const Duration(seconds: 10));

      final expense = ExpenseModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        category: e.category,
        amount: e.amount,
        usdAmount: usdAmount,
        currency: e.currency.toUpperCase(),
        date: e.date,
        receiptPath: e.receiptPath,
      );

      await expenseBox.add(expense);
      print('[AddExpenseBloc] saved expense id=${expense.id}');
      emit(AddExpenseSuccess());
    } catch (err, st) {
      print('[AddExpenseBloc] error: $err\n$st');
      emit(AddExpenseFailure('Failed to save: $err'));
    }
  }

}