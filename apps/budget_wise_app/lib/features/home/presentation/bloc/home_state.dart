part of 'home_bloc.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState extends Equatable {
  final HomeStatus status;
  final Plan? activePlan;
  final List<PlanItem> planItems;
  final double actualIncome;
  final List<Account> accounts;
  final List<Transaction> recentTransactions;
  final List<Transaction> todayTransactions;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.activePlan,
    this.planItems = const [],
    this.actualIncome = 0,
    this.accounts = const [],
    this.recentTransactions = const [],
    this.todayTransactions = const [],
    this.errorMessage,
  });

  bool get hasActivePlan => activePlan != null;

  double get totalBalance =>
      accounts.fold(0, (sum, account) => sum + account.balance);

  int get accountCount => accounts.length;

  double get totalPlannedExpenses =>
      planItems.fold(0, (sum, item) => sum + item.expectedAmount);

  double get totalActualExpenses =>
      planItems.fold(0, (sum, item) => sum + item.actualAmount);

  double get remainingBudget =>
      (activePlan?.expectedIncome ?? 0) - totalActualExpenses;

  /// Total amount overspent across categories that exceeded their budget.
  /// Sums only the positive overspend (`overAmount`) of each over-budget item.
  double get totalOverrun =>
      planItems.fold(0, (sum, item) => sum + item.overAmount);

  /// Budget still genuinely available to spend: the leftover room counting
  /// only items that are still within budget (over-budget items contribute 0,
  /// not a negative). Differs from [remainingBudget], which can be dragged
  /// down by overspend on other categories.
  double get realRemainingBudget => planItems.fold(
        0,
        (sum, item) => sum + (item.remainingAmount > 0 ? item.remainingAmount : 0),
      );

  /// Cash you can freely use this period.
  /// Formula: balance − remaining budget − remaining expected expenses.
  /// "Remaining budget" is the genuinely-usable leftover ([realRemainingBudget],
  /// over-budget categories contribute 0). The expected-expenses term is
  /// reserved for future projection and is currently 0.
  double get freeCash => totalBalance - realRemainingBudget - remainingExpectedExpenses;

  /// Expenses still expected before the period ends, beyond what is already
  /// captured by [realRemainingBudget]. Reserved for future projection; 0 today.
  double get remainingExpectedExpenses => 0;

  /// Total expense logged today (transfers and income excluded).
  double get todayExpenseTotal => todayTransactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  HomeState copyWith({
    HomeStatus? status,
    Plan? activePlan,
    List<PlanItem>? planItems,
    double? actualIncome,
    List<Account>? accounts,
    List<Transaction>? recentTransactions,
    List<Transaction>? todayTransactions,
    String? errorMessage,
    bool clearPlan = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      activePlan: clearPlan ? null : (activePlan ?? this.activePlan),
      planItems: planItems ?? this.planItems,
      actualIncome: actualIncome ?? this.actualIncome,
      accounts: accounts ?? this.accounts,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      todayTransactions: todayTransactions ?? this.todayTransactions,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        activePlan,
        planItems,
        actualIncome,
        accounts,
        recentTransactions,
        todayTransactions,
        errorMessage,
      ];
}
