# Expense Tracker Lite

A lightweight Flutter app for tracking expenses with Hive local storage, Bloc state management,
pagination, filters, and exports.

## Overview

- **Architecture**: Feature-first (feature/dashboard, data/, core/). Clean separation between UI,
  Bloc, and Repository.
- **Storage**: Hive (`ExpenseModel` with adapters).
- **State Management**: `flutter_bloc` with `DashboardBloc` for pagination + filters.
- **Testing**: Unit tests for validation, currency, and repository pagination with `hive_test`.
- **Extras**: CSV/PDF export, basic animations, CI pipeline.

## Structure

lib/
core/ # utils/ # currency_api, money_utils.dart
export/ # CSV/PDF services
utils/ # constant
validation/ # ExpenseValidator
data/
models/ # ExpenseModel + adapter
repositories/ # ExpenseRepository (filter-aware pagination)
feature/
dashboard/
bloc/ # events, states, bloc
screens/ # dashboard, add_expense

## State Management

- `DashboardBloc` listens to:
    - `LoadExpenses(page, filter)`
    - `LoadMoreExpenses` (append with `hasMore`)
    - `ChangeFilter(filter)` (resets to page 1)
    - `RefreshExpenses`
- Concurrency: `restartable()` for loads, throttled `LoadMoreExpenses`.

## API Integration

- (If local only) No remote API. Replace `ExpenseRepository` with a service that fetches from API;
  keep the same paging interface.

## Pagination Strategy

- **Local/Hive**: filter → sort → page (10 per page). `hasMore` computed from filtered length.
- Works with infinite scroll + “Load more” button.

## Screenshots

(Add images in `/screenshots`, then embed:)
![Dashboard](screenshots/dashboard.png)
![Add Expense](screenshots/add_expense.png)

## Trade-offs / Assumptions

- Local-only by default; easy to swap to API.
- Totals computed on the **filtered** set.
- Timezone handled using local time in filters (`[start, end)` boundaries).

## How to Run

```bash
flutter pub get
flutter run

flutter test
# coverage
flutter test --coverage

 Better date pickers & locales

 Persist user currency preference

 Widget tests for filter dropdown tap
