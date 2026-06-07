import 'package:app_template/domain/entities/plan_item.dart';
import 'package:app_template/features/insight/presentation/bloc/insight_bloc.dart';
import 'package:app_template/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction _expense({
  required String id,
  required double amount,
  required DateTime date,
  String? planItemId,
}) =>
    Transaction(
      id: id,
      accountId: 'acc1',
      type: TransactionType.expense,
      amount: amount,
      occurredAt: date,
      planItemId: planItemId,
    );

PlanItem _planItem(String id, String name) => PlanItem(
      id: id,
      planId: 'p1',
      name: name,
      expectedAmount: 1000,
      actualAmount: 0,
    );

InsightState _state({
  required List<Transaction> transactions,
  List<PlanItem> planItems = const [],
}) =>
    InsightState(
      status: InsightStatus.loaded,
      transactions: transactions,
      planItems: planItems,
    );

void main() {
  group('InsightState.dailyCategoryAmounts', () {
    test('returns empty list when there are no transactions', () {
      final state = _state(transactions: []);
      expect(state.dailyCategoryAmounts, isEmpty);
    });

    test('aggregates expenses by date and category', () {
      final date = DateTime(2026, 5, 10);
      final state = _state(
        transactions: [
          _expense(id: 't1', amount: 100, date: date, planItemId: 'c1'),
          _expense(id: 't2', amount: 50, date: date, planItemId: 'c1'),
          _expense(id: 't3', amount: 200, date: date, planItemId: 'c2'),
        ],
        planItems: [_planItem('c1', 'Food'), _planItem('c2', 'Fuel')],
      );

      final amounts = state.dailyCategoryAmounts;
      expect(amounts.length, 2);

      final food = amounts.firstWhere((e) => e.categoryName == 'Food');
      expect(food.amount, 150);
      expect(food.txCount, 2);

      final fuel = amounts.firstWhere((e) => e.categoryName == 'Fuel');
      expect(fuel.amount, 200);
      expect(fuel.txCount, 1);
    });

    test('uses Uncategorized for transactions without planItemId', () {
      final date = DateTime(2026, 5, 1);
      final state = _state(
        transactions: [
          _expense(id: 't1', amount: 80, date: date),
        ],
      );

      final amounts = state.dailyCategoryAmounts;
      expect(amounts.length, 1);
      expect(amounts.first.categoryName, 'Uncategorized');
    });

    test('separates same category across different dates', () {
      final state = _state(
        transactions: [
          _expense(id: 't1', amount: 100, date: DateTime(2026, 5, 1), planItemId: 'c1'),
          _expense(id: 't2', amount: 200, date: DateTime(2026, 5, 2), planItemId: 'c1'),
        ],
        planItems: [_planItem('c1', 'Food')],
      );

      final amounts = state.dailyCategoryAmounts;
      expect(amounts.length, 2);
      expect(amounts[0].date, DateTime(2026, 5, 1));
      expect(amounts[1].date, DateTime(2026, 5, 2));
    });

    test('ignores income transactions', () {
      final state = _state(
        transactions: [
          Transaction(
            id: 'i1',
            accountId: 'acc1',
            type: TransactionType.income,
            amount: 5000,
            occurredAt: DateTime(2026, 5, 1),
          ),
        ],
      );

      expect(state.dailyCategoryAmounts, isEmpty);
    });
  });

  group('InsightState.dowExpenseTotals', () {
    test('returns zeros for all days with no transactions', () {
      final totals = _state(transactions: []).dowExpenseTotals;
      expect(totals, List.filled(7, 0.0));
    });

    test('buckets expense amounts by day-of-week (Sun=0)', () {
      // 2026-05-10 is a Sunday (weekday=7 → %7=0)
      final sunday = DateTime(2026, 5, 10);
      // 2026-05-11 is a Monday (weekday=1)
      final monday = DateTime(2026, 5, 11);

      final state = _state(
        transactions: [
          _expense(id: 't1', amount: 100, date: sunday),
          _expense(id: 't2', amount: 200, date: sunday),
          _expense(id: 't3', amount: 50, date: monday),
        ],
      );

      final totals = state.dowExpenseTotals;
      expect(totals[0], 300); // Sunday
      expect(totals[1], 50);  // Monday
      expect(totals[2], 0);
    });
  });

  group('InsightState.activeDaysWithExpense', () {
    test('counts distinct days with expense transactions', () {
      final state = _state(
        transactions: [
          _expense(id: 't1', amount: 100, date: DateTime(2026, 5, 1)),
          _expense(id: 't2', amount: 50, date: DateTime(2026, 5, 1)),
          _expense(id: 't3', amount: 200, date: DateTime(2026, 5, 3)),
        ],
      );

      expect(state.activeDaysWithExpense, 2);
    });
  });
}
