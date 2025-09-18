// test/expense_repository_pagination_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';

import 'package:expense_tracker_lite/data/models/expense_model.dart';
import 'package:expense_tracker_lite/data/repositories/expense_repository.dart';

ExpenseModel exp({
  required DateTime date,
  double amount = 1,
  String category = 'test',
}) {
  return ExpenseModel(
    amount: amount,
    category: category,
    date: date,
    id: 't-${date.toIso8601String()}-$amount',
    currency: 'USD',
    usdAmount: amount,
  );
}

void main() {
  late Box<ExpenseModel> box;
  late ExpenseRepository repo;

  setUp(() async {
    await setUpTestHive();

    if (!Hive.isAdapterRegistered(ExpenseModelAdapter().typeId)) {
      Hive.registerAdapter(ExpenseModelAdapter());
    }

    box = await Hive.openBox<ExpenseModel>('expenses_test');

    repo = ExpenseRepository(box, now: () => DateTime(2025, 9, 18, 12));
  });

  tearDown(() async {
    await box.close();
    await tearDownTestHive();
  });

  test('thisMonth excludes next month and paginates 10 per page', () async {
    await box.clear();

    for (var d = 1; d <= 23; d++) {
      await box.add(exp(date: DateTime(2025, 9, d), amount: d.toDouble()));
    }

    await box.add(
      exp(date: DateTime(2025, 10, 1), amount: 999, category: 'future'),
    );

    final p1 = await repo.fetchExpenses(
      page: 1,
      pageSize: 10,
      filter: DashboardFilter.thisMonth,
    );
    final p2 = await repo.fetchExpenses(
      page: 2,
      pageSize: 10,
      filter: DashboardFilter.thisMonth,
    );
    final p3 = await repo.fetchExpenses(
      page: 3,
      pageSize: 10,
      filter: DashboardFilter.thisMonth,
    );

    expect(p1.items.length, 10);
    expect(p1.hasMore, isTrue);

    expect(p2.items.length, 10);
    expect(p2.hasMore, isTrue);

    expect(p3.items.length, 3);
    expect(p3.hasMore, isFalse);

    final all = [...p1.items, ...p2.items, ...p3.items];
    expect(all.any((e) => e.date.month == 10), isFalse);
  });

  test('last7Days (calendar) includes today and previous 6 days', () async {
    await box.clear();

    await box.addAll([
      exp(date: DateTime(2025, 9, 12), amount: -10, category: 'ok'),
      exp(date: DateTime(2025, 9, 13), amount: -20, category: 'ok'),
      exp(date: DateTime(2025, 9, 18, 8), amount: 30, category: 'ok'),
      exp(date: DateTime(2025, 9, 11), amount: -5, category: 'old'),
    ]);

    final r = await repo.fetchExpenses(
      page: 1,
      pageSize: 10,
      filter: DashboardFilter.last7Days,
    );
    expect(r.items.length, 3);
    expect(r.items.any((e) => e.category == 'old'), isFalse);
  });
}
