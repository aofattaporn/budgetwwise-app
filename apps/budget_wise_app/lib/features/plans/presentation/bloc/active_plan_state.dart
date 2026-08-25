part of 'active_plan_bloc.dart';

/// Status for ActivePlanBloc
enum ActivePlanStatus {
  initial,
  loading,
  loaded,
  error,
}

/// State for ActivePlanBloc
class ActivePlanState extends Equatable {
  final ActivePlanStatus status;
  final Plan? plan;
  final List<PlanItem> planItems;
  final double actualIncome;
  final String? errorMessage;

  const ActivePlanState({
    this.status = ActivePlanStatus.initial,
    this.plan,
    this.planItems = const [],
    this.actualIncome = 0,
    this.errorMessage,
  });

  /// Check if there is an active plan
  bool get hasActivePlan => plan != null;

  /// Get total planned expenses (tracking-only items, e.g. money lent out,
  /// don't compete for budget headroom)
  double get totalPlannedExpenses => planItems
      .where((item) => !item.isTrackingOnly)
      .fold(0, (sum, item) => sum + item.expectedAmount);

  /// Get total actual expenses
  double get totalActualExpenses =>
      planItems.fold(0, (sum, item) => sum + item.actualAmount);

  /// Get income difference (expected - actual)
  double get incomeDifference => (plan?.expectedIncome ?? 0) - actualIncome;

  /// Get count of items near limit
  int get itemsNearLimitCount =>
      planItems.where((item) => item.isNearLimit).length;

  /// Get count of items over budget
  int get itemsOverBudgetCount =>
      planItems.where((item) => item.isOverBudget).length;

  /// copyWith that properly handles nullable plan
  /// Use clearPlan: true to explicitly set plan to null
  ActivePlanState copyWith({
    ActivePlanStatus? status,
    Plan? plan,
    bool clearPlan = false,
    List<PlanItem>? planItems,
    double? actualIncome,
    String? errorMessage,
  }) {
    return ActivePlanState(
      status: status ?? this.status,
      plan: clearPlan ? null : (plan ?? this.plan),
      planItems: planItems ?? this.planItems,
      actualIncome: actualIncome ?? this.actualIncome,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        plan,
        planItems,
        actualIncome,
        errorMessage,
      ];
}
