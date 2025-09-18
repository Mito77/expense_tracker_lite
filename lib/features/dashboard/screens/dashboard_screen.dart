import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../../add_expense/screens/add_expense_screen.dart';
import '../../../data/models/expense_model.dart';
import 'package:share_plus/share_plus.dart';
// if not already there
import '../../../core/export/export_service.dart';
import '../../../core/export/pdf_export.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _exportCurrent(
    BuildContext context,
    DashboardLoaded state, {
    required bool asPdf,
  }) async {
    try {
      final bloc = context.read<DashboardBloc>();
      final items = bloc.allFiltered(state.filter);

      final nowStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final filterStr = () {
        switch (state.filter) {
          case DashboardFilter.thisMonth:
            return 'this-month';
          case DashboardFilter.last7Days:
            return 'last-7-days';
          case DashboardFilter.all:
          default:
            return 'all';
        }
      }();
      final baseName = 'expenses_${filterStr}_$nowStr';

      if (asPdf) {
        final file = await PdfExport.buildAndSave(
          items: items,
          totalIncome: state.totalIncome,
          totalExpenses: state.totalExpenses,
          totalBalance: state.totalBalance,
          fileName: baseName,
        );
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Expenses PDF export');
      } else {
        final file = await ExportService.exportCsv(
          items: items,
          fileName: baseName,
        );
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Expenses CSV export');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(asPdf ? 'PDF exported' : 'CSV exported')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeBlue = const Color(0xFF3A6FF7);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FB),

        body: SafeArea(
          child: BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              if (state is DashboardLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is DashboardLoaded) {
                final items = state.pageItems;
                return Stack(
                  children: [
                    // Blue background header
                    Container(
                      height: 250,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF3A6FF7), Color(0xFF6C92F4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                    ),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: KeyedSubtree(
                        key: ValueKey(
                          'len:${items.length}-f:${state.filter}-p:${state.page}',
                        ),
                        child: CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: _buildHeader(state, context),
                            ),
                            SliverToBoxAdapter(child: _buildBalanceCard(state)),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Recent Expenses",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        context.read<DashboardBloc>().add(
                                          ChangeFilter(DashboardFilter.all),
                                        );
                                      },
                                      child: const Text(
                                        "see all",
                                        style: TextStyle(
                                          color: Color(0xFF3A6FF7),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SliverList.separated(
                              itemCount: items.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 10),
                              itemBuilder:
                                  (context, index) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: _FadeSlideIn(
                                      index: index,
                                      child: _expenseItem(items[index]),
                                    ),
                                  ),
                            ),

                            SliverToBoxAdapter(
                              child: _loadMoreButton(context, state),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              } else if (state is DashboardError) {
                return Center(child: Text(state.message));
              }
              return const SizedBox();
            },
          ),
        ),

        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: themeBlue,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          currentIndex: 0,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: (index) async {
            if (index == 2) {
              await Navigator.of(context).push(
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 220),
                  reverseTransitionDuration: const Duration(milliseconds: 200),
                  pageBuilder: (_, __, ___) => const AddExpenseScreen(),
                  transitionsBuilder: (
                    _,
                    animation,
                    secondaryAnimation,
                    child,
                  ) {
                    final curved = CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    );
                    return FadeTransition(
                      opacity: curved,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.05),
                          end: Offset.zero,
                        ).animate(curved),
                        child: child,
                      ),
                    );
                  },
                ),
              );

              context.read<DashboardBloc>().add(
                LoadExpenses(page: 1, filter: DashboardFilter.thisMonth),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded, size: 28),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded, size: 28),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle, size: 52, color: Color(0xFF3A6FF7)),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.wallet, size: 28),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded, size: 28),
              label: "",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(DashboardLoaded state, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(
                  "https://cdn.dribbble.com/users/11477597/avatars/normal/98b253c065e646c0ae38361afe89aead.png?1701021289",
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Good Morning",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    "Shihab Rahman",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _filterDropdown(context, state),
              const SizedBox(width: 8),
              _moreMenu(context, state),
            ],
          ),
        ],
      ),
    );
  }

  Widget _moreMenu(BuildContext context, DashboardLoaded state) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (v) async {
        if (v == 'export_csv') {
          await _exportCurrent(context, state, asPdf: false);
        } else if (v == 'export_pdf') {
          await _exportCurrent(context, state, asPdf: true);
        }
      },
      itemBuilder:
          (_) => const [
            PopupMenuItem(value: 'export_csv', child: Text('Export CSV')),
            PopupMenuItem(value: 'export_pdf', child: Text('Export PDF')),
          ],
    );
  }

  Widget _filterDropdown(BuildContext context, DashboardLoaded state) {
    String label;
    switch (state.filter) {
      case DashboardFilter.thisMonth:
        label = 'This month';
        break;
      case DashboardFilter.last7Days:
        label = 'Last 7 days';
        break;
      case DashboardFilter.all:
      default:
        label = 'All';
        break;
    }

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      offset: Offset(0, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      onSelected: (value) {
        if (value == 'this_month') {
          context.read<DashboardBloc>().add(
            LoadExpenses(page: 1, filter: DashboardFilter.thisMonth),
          );
        } else if (value == 'last_7') {
          context.read<DashboardBloc>().add(
            LoadExpenses(page: 1, filter: DashboardFilter.last7Days),
          );
        } else {
          context.read<DashboardBloc>().add(
            LoadExpenses(page: 1, filter: DashboardFilter.all),
          );
        }
      },
      itemBuilder:
          (_) => const [
            PopupMenuItem(value: 'this_month', child: Text('This month')),
            PopupMenuItem(value: 'last_7', child: Text('Last 7 days')),
            PopupMenuItem(value: 'all', child: Text('All')),
          ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder:
                  (child, anim) => FadeTransition(opacity: anim, child: child),
              child: Text(
                label,
                key: ValueKey(label),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(DashboardLoaded state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4B7BF8), Color(0xFF7AA1F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3A6FF7).withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "Total Balance",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Icon(Icons.keyboard_arrow_up, color: Colors.white),
                ],
              ),
              Icon(Icons.more_horiz, color: Colors.white),
            ],
          ),
          const SizedBox(height: 6),
          _AnimatedMoney(
            value: state.totalBalance,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _balanceItem(
                  "Income",
                  state.totalIncome,
                  Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _balanceItem(
                  "Expenses",
                  state.totalExpenses,
                  Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceItem(String label, double amount, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10.0),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          _AnimatedMoney(
            value: amount,
            duration: const Duration(milliseconds: 350),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _expenseItem(ExpenseModel expense) {
    final isExpense = expense.amount < 0;
    final amountText =
        "${isExpense ? "-" : "+"}${_currency(expense.amount.abs())}";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFEAF0FF),
            child: Icon(
              _iconForCategory(expense.category),
              color: const Color(0xFF3A6FF7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Manually",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountText,
                style: TextStyle(
                  color: isExpense ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _friendlyTime(expense.date),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _loadMoreButton(BuildContext context, DashboardLoaded state) {
    if (!state.hasMore) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: OutlinedButton(
        onPressed: () {
          final bloc = context.read<DashboardBloc>();
          final s = bloc.state;
          final nextPage = s is DashboardLoaded ? s.page + 1 : 2;
          final filter =
              s is DashboardLoaded ? s.filter : DashboardFilter.thisMonth;

          bloc.add(LoadExpenses(page: nextPage, filter: filter));
        },
        child: const Text('Load more'),
      ),
    );
  }

  static String _currency(double v) {
    final f = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    return f.format(v);
  }

  static String _friendlyTime(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final time = DateFormat('h:mm a').format(dt);
    return "${isToday ? "Today" : DateFormat('MMM d').format(dt)} $time";
  }

  static IconData _iconForCategory(String category) {
    final key = category.toLowerCase();
    if (key.contains('grocery') ||
        key.contains('grocer') ||
        key.contains('market')) {
      return Icons.local_grocery_store_rounded;
    }
    if (key.contains('entertain')) return Icons.icecream;
    if (key.contains('transport') ||
        key.contains('uber') ||
        key.contains('bus') ||
        key.contains('metro')) {
      return Icons.directions_bus_rounded;
    }
    if (key.contains('rent') || key.contains('home') || key.contains('house')) {
      return Icons.home_rounded;
    }
    if (key.contains('food') || key.contains('restaurant')) {
      return Icons.restaurant_rounded;
    }
    return Icons.shopping_cart_rounded;
  }
}

class _AnimatedMoney extends StatelessWidget {
  final double value;
  final TextStyle style;
  final Duration duration;
  const _AnimatedMoney({
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOut,
      builder: (_, v, __) {
        final t = NumberFormat.currency(
          locale: 'en_US',
          symbol: '\$',
        ).format(v);
        return Text(t, style: style);
      },
    );
  }
}

class _FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int index;
  const _FadeSlideIn({required this.child, required this.index});

  @override
  Widget build(BuildContext context) {
    final ms = 180 + (index % 6) * 30;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 12, end: 0),
      duration: Duration(milliseconds: ms),
      curve: Curves.easeOut,
      builder:
          (_, offset, __) => Transform.translate(
            offset: Offset(0, offset),
            child: Opacity(opacity: (12 - offset) / 12, child: child),
          ),
    );
  }
}
