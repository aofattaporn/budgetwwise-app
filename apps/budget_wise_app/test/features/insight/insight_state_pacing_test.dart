import 'package:app_template/domain/entities/plan.dart';
import 'package:app_template/domain/entities/plan_item.dart';
import 'package:app_template/features/insight/presentation/bloc/insight_bloc.dart';
import 'package:app_template/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

Plan _plan({required DateTime start, required DateTime end}) => Plan(
      id: 'p1',
      name: 'Test Plan',
      startDate: start,
      endDate: end,
      isActive: true,
    );

PlanItem _planItem(String id, double budget) => PlanItem(
      id: id,
      planId: 'p1',
      name: 'Category $id',
      expectedAmount: budget,
      actualAmount: 0,
    );

Transaction _expense(double amount, DateTime date) => Transaction(
      id: 'tx_${amount.toInt()}',
      accountId: 'acc1',
      type: TransactionType.expense,
      amount: amount,
      occurredAt: date,
    );

InsightState _stateWithPlan({
  required Plan plan,
  List<PlanItem> planItems = const [],
  List<Transaction> transactions = const [],
}) =>
    InsightState(
      status: InsightStatus.loaded,
      allPlans: [plan],
      selectedPlanIndex: 0,
      transactions: transactions,
      planItems: planItems,
    );

void main() {
  group('InsightState.periodTotalDays', () {
    test('counts days inclusively', () {
      final state = _stateWithPlan(
        plan: _plan(start: DateTime(2026, 6, 1), end: DateTime(2026, 6, 30)),
      );
      expect(state.periodTotalDays, 30);
    });

    test('single-day plan returns 1', () {
      final state = _stateWithPlan(
        plan: _plan(start: DateTime(2026, 6, 1), end: DateTime(2026, 6, 1)),
      );
      expect(state.periodTotalDays, 1);
    });

    test('31-day month returns 31', () {
      final state = _stateWithPlan(
        plan: _plan(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31)),
      );
      expect(state.periodTotalDays, 31);
    });
  });

  group('InsightState.periodElapsedDays', () {
    test('returns periodTotalDays for a fully past plan', () {
      final state = _stateWithPlan(
        plan: _plan(start: DateTime(2020, 1, 1), end: DateTime(2020, 1, 31)),
      );
      expect(state.periodElapsedDays, 31);
    });

    test('returns 0 for a plan that has not started yet', () {
      final state = _stateWithPlan(
        plan: _plan(start: DateTime(2030, 1, 1), end: DateTime(2030, 1, 31)),
      );
      expect(state.periodElapsedDays, 0);
    });
  });

  group('InsightState.periodRemainingDays', () {
    test('returns 0 for a fully completed plan', () {
      final state = _stateWithPlan(
        plan: _plan(start: DateTime(2020, 1, 1), end: DateTime(2020, 1, 31)),
      );
      expect(state.periodRemainingDays, 0);
    });

    test('returns full length for a future plan', () {
      final state = _stateWithPlan(
        plan: _plan(start: DateTime(2030, 1, 1), end: DateTime(2030, 1, 10)),
      );
      expect(state.periodRemainingDays, 10);
    });
  });

  group('InsightState.periodProgressPct', () {
    test('returns 1.0 for a past plan', () {
      final state = _stateWithPlan(
        plan: _plan(start: DateTime(2020, 1, 1), end: DateTime(2020, 1, 10)),
      );
      expect(state.periodProgressPct, 1.0);
    });

    test('returns 0.0 for a future plan', () {
      final state = _stateWithPlan(
        plan: _plan(start: DateTime(2030, 1, 1), end: DateTime(2030, 1, 10)),
      );
      expect(state.periodProgressPct, 0.0);
    });
  });

  group('InsightState.budgetSpentPct', () {
    test('returns 0.0 when no budget items exist', () {
      final state = _stateWithPlan(
        plan: _plan(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31)),
        transactions: [_expense(500, DateTime(2026, 1, 5))],
      );
      expect(state.budgetSpentPct, 0.0);
    });

    test('returns correct fraction of budget spent', () {
      final state = _stateWithPlan(
        plan: _plan(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31)),
        planItems: [_planItem('c1', 1000)],
        transactions: [_expense(400, DateTime(2026, 1, 5))],
      );
      expect(state.budgetSpentPct, closeTo(0.4, 0.001));
    });

    test('clamps at 2.0 when expense is more than double the budget', () {
      final state = _stateWithPlan(
        plan: _plan(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31)),
        planItems: [_planItem('c1', 100)],
        transactions: [_expense(500, DateTime(2026, 1, 5))],
      );
      expect(state.budgetSpentPct, 2.0);
    });
  });

  group('InsightState.dailyBudgetRemaining', () {
    test('returns 0 when plan is already finished', () {
      final state = _stateWithPlan(
        plan: _plan(start: DateTime(2020, 1, 1), end: DateTime(2020, 1, 10)),
        planItems: [_planItem('c1', 1000)],
        transactions: [_expense(400, DateTime(2020, 1, 5))],
      );
      expect(state.dailyBudgetRemaining, 0.0);
    });

    test('returns remaining budget divided by days left for a future plan', () {
      final state = _stateWithPlan(
        plan: _plan(start: DateTime(2030, 1, 1), end: DateTime(2030, 1, 10)),
        planItems: [_planItem('c1', 1000)],
      );
      // ฿1,000 remaining / 10 days = ฿100/day
      expect(state.dailyBudgetRemaining, closeTo(100.0, 0.1));
    });

    test('returns 0 when already over budget', () {
      final state = _stateWithPlan(
        plan: _plan(start: DateTime(2030, 1, 1), end: DateTime(2030, 1, 10)),
        planItems: [_planItem('c1', 500)],
        transactions: [_expense(600, DateTime(2030, 1, 1))],
      );
      expect(state.dailyBudgetRemaining, 0.0);
    });
  });

  group('InsightState.pacingStatus', () {
    test('returns onPace when no budget is set', () {
      final state = _stateWithPlan(
        plan: _plan(start: DateTime(2020, 1, 1), end: DateTime(2020, 1, 31)),
      );
      expect(state.pacingStatus, PacingStatus.onPace);
    });

    test('returns underPace when spent far less than time elapsed', () {
      // Past plan → 100% time elapsed. Spent only 20% of budget.
      final state = _stateWithPlan(
        plan: _plan(start: DateTime(2020, 1, 1), end: DateTime(2020, 1, 31)),
        planItems: [_planItem('c1', 10000)],
        transactions: [_expense(2000, DateTime(2020, 1, 15))],
      );
      expect(state.pacingStatus, PacingStatus.underPace);
    });

    test('returns overPace when spending exceeds time proportion by >5%', () {
      // Future plan → 0% time elapsed. Any expense > 5% of budget = over pace.
      final state = _stateWithPlan(
        plan: _plan(start: DateTime(2030, 1, 1), end: DateTime(2030, 1, 31)),
        planItems: [_planItem('c1', 1000)],
        transactions: [_expense(200, DateTime(2030, 1, 1))], // 20% spent, 0% time
      );
      expect(state.pacingStatus, PacingStatus.overPace);
    });

    test('returns onPace when diff is within ±5% buffer', () {
      // Past plan → 100% time. 97% spent → diff = -3% → within buffer.
      final state = _stateWithPlan(
        plan: _plan(start: DateTime(2020, 1, 1), end: DateTime(2020, 1, 31)),
        planItems: [_planItem('c1', 1000)],
        transactions: [_expense(970, DateTime(2020, 1, 20))],
      );
      expect(state.pacingStatus, PacingStatus.onPace);
    });
  });
}
