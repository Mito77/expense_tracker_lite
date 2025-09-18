abstract class DashboardEvent {}

class LoadExpenses extends DashboardEvent {
  final int page;
  final DashboardFilter filter;
  LoadExpenses({required this.page, required this.filter});
}

class ChangeFilter extends DashboardEvent {
  final DashboardFilter filter;
  ChangeFilter(this.filter);
}

enum DashboardFilter { thisMonth, last7Days, all }
