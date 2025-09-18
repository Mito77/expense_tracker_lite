import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';

enum DashboardFilter { thisMonth, last7Days, all }

class PagedExpenses {
  final List<ExpenseModel> items;
  final bool hasMore;
  final double totalBalance;
  final double totalIncome;
  final double totalExpenses;

  PagedExpenses({
    required this.items,
    required this.hasMore,
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpenses,
  });
}

class ExpenseRepository {
  final Box<ExpenseModel> box;
  final DateTime Function() nowFn;

  ExpenseRepository(this.box, {DateTime Function()? now})
    : nowFn = now ?? DateTime.now;

  // create
  Future<void> addExpense(ExpenseModel expense) async {
    await box.add(expense);
  }

  List<ExpenseModel> all() =>
      box.values.toList()..sort((a, b) => b.date.compareTo(a.date));

  Future<PagedExpenses> fetchExpenses({
    required int page,
    required int pageSize,
    required DashboardFilter filter,
  }) async {
    final now = DateTime.now();
    final filtered =
        _applyFilter(box.values, filter, now).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    final totals = _computeTotals(filtered);

    final start = (page - 1) * pageSize;
    List<ExpenseModel> pageItems = const [];
    bool hasMore = false;

    if (start < filtered.length) {
      final end = (start + pageSize).clamp(0, filtered.length);
      pageItems = filtered.sublist(start, end);
      hasMore = end < filtered.length;
    }

    return PagedExpenses(
      items: pageItems,
      hasMore: hasMore,
      totalBalance: totals.$1,
      totalIncome: totals.$2,
      totalExpenses: totals.$3,
    );
  }

  Iterable<ExpenseModel> _applyFilter(
    Iterable<ExpenseModel> items,
    DashboardFilter filter,
    DateTime now,
  ) {
    switch (filter) {
      case DashboardFilter.thisMonth:
        final first = DateTime(now.year, now.month, 1);
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        return items.where(
          (e) => e.date.isAfterOrAt(first) && e.date.isBefore(nextMonth),
        );
      case DashboardFilter.last7Days:
        final since = now.subtract(const Duration(days: 7));
        return items.where(
          (e) => e.date.isAfterOrAt(since) && e.date.isBeforeOrAt(now),
        );
      case DashboardFilter.all:
      default:
        return items;
    }
  }

  (double, double, double) _computeTotals(List<ExpenseModel> items) {
    double income = 0;
    double expensesMag = 0;
    for (final e in items) {
      final v = e.amount;
      if (v >= 0) {
        income += v;
      } else {
        expensesMag += (-v);
      }
    }
    final balance =
        income - expensesMag; // equals items.fold(0, (s, e) => s + e.amount)
    return (balance, income, expensesMag);
  }
}

/// tiny date helpers (avoid off-by-one in filters)
extension _DateCompare on DateTime {
  bool isAfterOrAt(DateTime other) => isAfter(other) || isAtSameMomentAs(other);

  bool isBeforeOrAt(DateTime other) =>
      isBefore(other) || isAtSameMomentAs(other);
}
