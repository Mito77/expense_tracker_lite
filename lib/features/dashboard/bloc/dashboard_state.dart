import '../../../data/models/expense_model.dart';
import 'dashboard_event.dart';


abstract class DashboardState {}


class DashboardLoading extends DashboardState {}


class DashboardLoaded extends DashboardState {
  final List<ExpenseModel> pageItems;
  final int page;
  final bool hasMore;
  final DashboardFilter filter;
  final double totalIncome;
  final double totalExpenses;
  final double totalBalance;


  DashboardLoaded({
    required this.pageItems,
    required this.page,
    required this.hasMore,
    required this.filter,
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalBalance,
  });
}


class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}