import 'package:app_template/domain/entities/plan.dart';
import 'package:app_template/domain/entities/plan_item.dart';
import 'package:app_template/features/insight/presentation/bloc/insight_bloc.dart';
import 'package:app_template/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction _expense(String id, double amount, DateTime date, String itemId) =>
    Transaction(
      id: id,
      accountId: 'acc1',
      type: TransactionType.expense,
      amount: amount,
      occurredAt: date,
      planItemId: itemId,
    );

InsightState _state(List<PlanItem> items, List<Transaction> txns) {
  final now = DateTime.now();
  return InsightState(
    status: InsightStatus.loaded,
    allPlans: [
      Plan(
        id: 'p1',
        name: 'Plan',
        startDate: DateTime(now.year, now.month, now.day - 9),
        endDate: DateTime(now.year, now.month, now.day + 10),
        isActive: true,
      ),
    ],
    transactions: txns,
    planItems: items,
  );
}

PlanItem _item(String id, double budget) => PlanItem(
      id: id,
      planId: 'p1',
      name: 'Item $id',
      expectedAmount: budget,
    );

void main() {
  final today = DateTime.now();

  test('no data yields no highlights', () {
    expect(_state([], []).highlights, isEmpty);
  });

  test('over-budget category is flagged as bad', () {
    final state = _state(
      [_item('a', 100), _item('b', 1000)],
      [_expense('t1', 150, today, 'a')],
    );
    final bad = state.highlights.where((h) => h.tone == HighlightTone.bad);
    expect(bad.single.title, '1 category over budget');
  });

  test('total spend above total budget reports Over budget first', () {
    final state = _state(
      [_item('a', 100)],
      [_expense('t1', 150, today, 'a')],
    );
    expect(state.highlights.first.title, 'Over budget');
  });

  test('projectedExpense extrapolates the daily rate over the period', () {
    final state = _state(
      [_item('a', 1000)],
      [_expense('t1', 100, today, 'a')],
    );
    // 10 days elapsed of 20 total
    expect(state.projectedExpense, 200);
  });
}
