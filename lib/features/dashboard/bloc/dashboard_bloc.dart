import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import '../../../data/models/expense_model.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  static const _pageSize = 10;
  final Box<ExpenseModel> box;

  DashboardBloc(this.box) : super(DashboardLoading()) {
    on<LoadExpenses>(_onLoad);
    on<ChangeFilter>(_onChangeFilter);
  }

  List<ExpenseModel> filterBy(
    List<ExpenseModel> items,
    DashboardFilter f, {
    DateTime? now,
  }) {
    final localNow = (now ?? DateTime.now()).toLocal();

    // helper: [start, end) in local time
    bool inRange(DateTime dt, DateTime start, DateTime end) {
      final t = dt.toLocal();
      return !t.isBefore(start) && t.isBefore(end);
    }

    late DateTime start, end;

    switch (f) {
      case DashboardFilter.thisMonth:
        start = DateTime(localNow.year, localNow.month, 1);
        end = DateTime(
          localNow.year,
          localNow.month + 1,
          1,
        ); // next month 00:00
        break;

      case DashboardFilter.last7Days:
        // last 7 calendar days INCLUDING today
        final today0 = DateTime(localNow.year, localNow.month, localNow.day);
        start = today0.subtract(
          const Duration(days: 6),
        ); // 6 back + today = 7 days
        end = today0.add(const Duration(days: 1)); // tomorrow 00:00 (exclusive)
        break;

      case DashboardFilter.all:
        return items..sort((a, b) => b.date.compareTo(a.date));
    }

    return (items.where((e) => inRange(e.date, start, end)).toList()
      ..sort((a, b) => b.date.compareTo(a.date)));
  }

  void _emitPage(
    List<ExpenseModel> filtered,
    int page,
    DashboardFilter filter,
    Emitter<DashboardState> emit,
  ) {
    filtered.sort((a, b) => b.date.compareTo(a.date));
    final start = (page - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, filtered.length);
    final pageItems =
        start < filtered.length
            ? filtered.sublist(start, end)
            : <ExpenseModel>[];
    final hasMore = end < filtered.length;

    final income = filtered
        .where((e) => e.usdAmount > 0)
        .fold<double>(0.0, (a, b) => a + b.usdAmount);
    final expense = filtered
        .where((e) => e.usdAmount < 0)
        .fold<double>(0.0, (a, b) => a + b.usdAmount.abs());
    final balance = income - expense;

    emit(
      DashboardLoaded(
        pageItems: pageItems,
        page: page,
        hasMore: hasMore,
        filter: filter,
        totalIncome: income,
        totalExpenses: expense,
        totalBalance: balance,
      ),
    );
  }

  Future<void> _onLoad(LoadExpenses e, Emitter<DashboardState> emit) async {
    try {
      final all = box.values.toList();
      final filtered = filterBy(all, e.filter);
      _emitPage(filtered, e.page, e.filter, emit);
    } catch (err) {
      emit(DashboardError('Failed to load: $err'));
    }
  }

  List<ExpenseModel> allFiltered(DashboardFilter f, {DateTime? now}) {
    final all = box.values.toList();
    return filterBy(all, f, now: now);
  }

  Future<void> _onChangeFilter(
    ChangeFilter e,
    Emitter<DashboardState> emit,
  ) async {
    add(LoadExpenses(page: 1, filter: e.filter));
  }
}
