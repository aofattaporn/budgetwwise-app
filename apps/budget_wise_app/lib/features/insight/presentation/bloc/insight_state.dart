part of 'insight_bloc.dart';

enum InsightStatus { initial, loading, loaded, error }

/// Daily aggregation for charts
class DailyAmount extends Equatable {
  final DateTime date;
  final double income;
  final double expense;

  const DailyAmount({
    required this.date,
    required this.income,
    required this.expense,
  });

  double get net => income - expense;

  @override
  List<Object?> get props => [date, income, expense];
}

/// Category insight — maps plan item budget vs actual spending
class CategoryInsight extends Equatable {
  final String name;
  final double budget;
  final double actual;

  const CategoryInsight({
    required this.name,
    required this.budget,
    required this.actual,
  });

  double get overAmount => actual > budget ? actual - budget : 0;
  double get remaining => budget - actual;
  bool get isOverBudget => actual > budget;
  double get percentage => budget > 0 ? (actual / budget).clamp(0.0, double.infinity) : 0;

  @override
  List<Object?> get props => [name, budget, actual];
}

/// Per-day per-category expense entry used by the heatmap.
class DailyCategoryAmount extends Equatable {
  final DateTime date;
  final String categoryName;
  final double amount;
  final int txCount;

  const DailyCategoryAmount({
    required this.date,
    required this.categoryName,
    required this.amount,
    required this.txCount,
  });

  @override
  List<Object?> get props => [date, categoryName, amount, txCount];
}

enum PacingStatus { underPace, onPace, overPace }

/// Private key for grouping by (date, category).
class _DayCategory {
  final DateTime date;
  final String category;

  const _DayCategory(this.date, this.category);

  @override
  bool operator ==(Object other) =>
      other is _DayCategory && date == other.date && category == other.category;

  @override
  int get hashCode => Object.hash(date, category);
}

/// Private accumulator for amount + count.
class _DayCategoryAccum {
  final double amount;
  final int count;

  const _DayCategoryAccum(this.amount, this.count);
}

class InsightState extends Equatable {
  final InsightStatus status;
  final List<Plan> allPlans;
  final int selectedPlanIndex;
  final List<Transaction> transactions;
  final Plan? activePlan;
  final List<PlanItem> planItems;
  final String? errorMessage;

  const InsightState({
    required this.status,
    this.allPlans = const [],
    this.selectedPlanIndex = 0,
    required this.transactions,
    this.activePlan,
    this.planItems = const [],
    this.errorMessage,
  });

  factory InsightState.initial() {
    return const InsightState(
      status: InsightStatus.initial,
      transactions: [],
    );
  }

  /// The currently viewed plan (from allPlans at selectedPlanIndex)
  Plan? get selectedPlan =>
      allPlans.isNotEmpty && selectedPlanIndex < allPlans.length
          ? allPlans[selectedPlanIndex]
          : null;

  /// Date range from the selected plan, or current calendar month as fallback
  DateTime get periodStart {
    final plan = selectedPlan;
    if (plan != null) return plan.startDate;
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  DateTime get periodEnd {
    final plan = selectedPlan;
    if (plan != null) return plan.endDate;
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  bool get canGoNext => selectedPlanIndex > 0;
  bool get canGoPrevious => selectedPlanIndex < allPlans.length - 1;

  // ── Computed values ────────────────────────────────────────

  double get totalIncome => transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get netAmount => totalIncome - totalExpense;

  double get totalBudget => planItems
      .where((item) => !item.isTrackingOnly)
      .fold(0.0, (sum, item) => sum + item.expectedAmount);

  /// Plan item ID → name map
  Map<String, String> get _planItemNames {
    final map = <String, String>{};
    for (final item in planItems) {
      map[item.id] = item.name;
    }
    return map;
  }

  /// Resolve planItemId to a display name
  String categoryName(String? planItemId) {
    if (planItemId == null) return 'Uncategorized';
    return _planItemNames[planItemId] ?? 'Unknown';
  }

  /// Daily income & expense for line chart (uses plan date range)
  List<DailyAmount> get dailyAmounts {
    final start = periodStart;
    final end = periodEnd;
    final totalDays = end.difference(start).inDays + 1;
    final map = <DateTime, DailyAmount>{};

    for (int i = 0; i < totalDays; i++) {
      final date = DateTime(start.year, start.month, start.day + i);
      map[date] = DailyAmount(date: date, income: 0, expense: 0);
    }

    for (final txn in transactions) {
      final dateKey = DateTime(
          txn.occurredAt.year, txn.occurredAt.month, txn.occurredAt.day);
      final existing = map[dateKey];
      if (existing == null) continue;
      if (txn.type == TransactionType.income) {
        map[dateKey] = DailyAmount(
          date: existing.date,
          income: existing.income + txn.amount,
          expense: existing.expense,
        );
      } else if (txn.type == TransactionType.expense) {
        map[dateKey] = DailyAmount(
          date: existing.date,
          income: existing.income,
          expense: existing.expense + txn.amount,
        );
      }
    }

    final sorted = map.keys.toList()..sort();
    return sorted.map((d) => map[d]!).toList();
  }

  /// Expense grouped by category name (resolved from planItems)
  List<CategoryInsight> get categoryInsights {
    // Aggregate actual spending per planItemId
    final actualMap = <String?, double>{};
    for (final txn in transactions) {
      if (txn.type != TransactionType.expense) continue;
      actualMap[txn.planItemId] = (actualMap[txn.planItemId] ?? 0) + txn.amount;
    }

    final results = <CategoryInsight>[];

    // For each plan item, build insight with budget + actual
    for (final item in planItems) {
      final actual = actualMap.remove(item.id) ?? 0;
      results.add(CategoryInsight(
        name: item.name,
        budget: item.expectedAmount,
        actual: actual,
      ));
    }

    // Remaining entries are uncategorized or from unknown planItemIds
    double uncategorizedTotal = 0;
    for (final entry in actualMap.entries) {
      uncategorizedTotal += entry.value;
    }
    if (uncategorizedTotal > 0) {
      results.add(CategoryInsight(
        name: 'Uncategorized',
        budget: 0,
        actual: uncategorizedTotal,
      ));
    }

    // Sort by actual spending descending
    results.sort((a, b) => b.actual.compareTo(a.actual));
    return results;
  }

  /// Only categories that are over budget
  List<CategoryInsight> get overspentCategories =>
      categoryInsights.where((c) => c.isOverBudget).toList();

  int get transactionCount => transactions.length;

  /// Per-day per-category expense aggregation for the heatmap.
  /// Only expense transactions are included.
  List<DailyCategoryAmount> get dailyCategoryAmounts {
    final names = _planItemNames;
    final map = <_DayCategory, _DayCategoryAccum>{};

    for (final txn in transactions) {
      if (txn.type != TransactionType.expense) continue;
      final dateKey = DateTime(
          txn.occurredAt.year, txn.occurredAt.month, txn.occurredAt.day);
      final catName = txn.planItemId != null
          ? (names[txn.planItemId] ?? 'Unknown')
          : 'Uncategorized';
      final key = _DayCategory(dateKey, catName);
      final existing = map[key] ?? _DayCategoryAccum(0, 0);
      map[key] = _DayCategoryAccum(existing.amount + txn.amount, existing.count + 1);
    }

    return map.entries
        .map((e) => DailyCategoryAmount(
              date: e.key.date,
              categoryName: e.key.category,
              amount: e.value.amount,
              txCount: e.value.count,
            ))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Expense totals indexed by day-of-week (0=Sun … 6=Sat).
  List<double> get dowExpenseTotals {
    final totals = List<double>.filled(7, 0);
    for (final txn in transactions) {
      if (txn.type != TransactionType.expense) continue;
      totals[txn.occurredAt.weekday % 7] += txn.amount;
    }
    return totals;
  }

  /// Number of distinct days that have at least one expense transaction.
  int get activeDaysWithExpense {
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .map((t) =>
            DateTime(t.occurredAt.year, t.occurredAt.month, t.occurredAt.day))
        .toSet()
        .length;
  }

  // ── Period pacing ──────────────────────────────────────────

  int get periodTotalDays {
    final start = DateTime(periodStart.year, periodStart.month, periodStart.day);
    final end = DateTime(periodEnd.year, periodEnd.month, periodEnd.day);
    return end.difference(start).inDays + 1;
  }

  int get periodElapsedDays {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(periodStart.year, periodStart.month, periodStart.day);
    final end = DateTime(periodEnd.year, periodEnd.month, periodEnd.day);
    if (today.isBefore(start)) return 0;
    if (today.isAfter(end)) return periodTotalDays;
    return today.difference(start).inDays + 1;
  }

  int get periodRemainingDays =>
      (periodTotalDays - periodElapsedDays).clamp(0, periodTotalDays);

  double get periodProgressPct {
    final total = periodTotalDays;
    return total > 0 ? (periodElapsedDays / total).clamp(0.0, 1.0) : 0.0;
  }

  double get budgetSpentPct =>
      totalBudget > 0 ? (totalExpense / totalBudget).clamp(0.0, 2.0) : 0.0;

  /// How much budget remains per day for the rest of the period.
  double get dailyBudgetRemaining {
    final remaining = totalBudget - totalExpense;
    final days = periodRemainingDays;
    if (days <= 0 || remaining <= 0) return 0;
    return remaining / days;
  }

  /// Whether spending is ahead of, behind, or in sync with the period timeline.
  /// Uses a ±5 percentage-point buffer to avoid flickering on "on track".
  PacingStatus get pacingStatus {
    if (totalBudget == 0) return PacingStatus.onPace;
    final diff = budgetSpentPct - periodProgressPct;
    if (diff > 0.05) return PacingStatus.overPace;
    if (diff < -0.05) return PacingStatus.underPace;
    return PacingStatus.onPace;
  }

  InsightState copyWith({
    InsightStatus? status,
    List<Plan>? allPlans,
    int? selectedPlanIndex,
    List<Transaction>? transactions,
    Plan? activePlan,
    bool clearPlan = false,
    List<PlanItem>? planItems,
    String? errorMessage,
  }) {
    return InsightState(
      status: status ?? this.status,
      allPlans: allPlans ?? this.allPlans,
      selectedPlanIndex: selectedPlanIndex ?? this.selectedPlanIndex,
      transactions: transactions ?? this.transactions,
      activePlan: clearPlan ? null : (activePlan ?? this.activePlan),
      planItems: planItems ?? this.planItems,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, allPlans, selectedPlanIndex, transactions, activePlan, planItems, errorMessage];
}
