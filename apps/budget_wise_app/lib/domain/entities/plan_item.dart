import 'package:equatable/equatable.dart';

/// How often a plan item is expected to recur within the plan period.
/// Used for end-of-period spend projection.
enum RecurrenceType {
  daily,
  weekly,
  monthly,
  oneTime;

  String get value => switch (this) {
        RecurrenceType.daily => 'daily',
        RecurrenceType.weekly => 'weekly',
        RecurrenceType.monthly => 'monthly',
        RecurrenceType.oneTime => 'one_time',
      };

  static RecurrenceType fromValue(String? value) => switch (value) {
        'weekly' => RecurrenceType.weekly,
        'monthly' => RecurrenceType.monthly,
        'one_time' => RecurrenceType.oneTime,
        _ => RecurrenceType.daily,
      };

  String get label => switch (this) {
        RecurrenceType.daily => 'Daily',
        RecurrenceType.weekly => 'Weekly',
        RecurrenceType.monthly => 'Monthly',
        RecurrenceType.oneTime => 'One-time',
      };

  String get description => switch (this) {
        RecurrenceType.daily => 'Food, coffee, transport',
        RecurrenceType.weekly => 'Gym, weekly subscription',
        RecurrenceType.monthly => 'Rent, utilities, insurance',
        RecurrenceType.oneTime => 'Car service, registration fee',
      };
}

/// Plan item entity representing a budget category within a plan
class PlanItem extends Equatable {
  final String id;
  final String planId;
  final String name;
  final String? description;
  final double expectedAmount;
  final int? iconIndex;
  final RecurrenceType recurrenceType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Actual amount spent/received (calculated from transactions)
  final double actualAmount;

  const PlanItem({
    required this.id,
    required this.planId,
    required this.name,
    this.description,
    required this.expectedAmount,
    this.iconIndex,
    this.recurrenceType = RecurrenceType.daily,
    this.actualAmount = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// Get remaining amount (expected - actual)
  double get remainingAmount => expectedAmount - actualAmount;

  /// Get over amount if exceeded
  double get overAmount => actualAmount > expectedAmount ? actualAmount - expectedAmount : 0;

  /// Check if over budget
  bool get isOverBudget => actualAmount > expectedAmount;

  /// Check if near limit (>= 85% used)
  bool get isNearLimit => !isOverBudget && (actualAmount / expectedAmount) >= 0.85;

  /// Get progress percentage (0.0 to 1.0, capped at 1.0)
  ///
  /// [actualAmount] can go negative when reimbursements for an item exceed its
  /// spend, so the ratio is floored at 0 as well — a progress bar cannot draw
  /// a negative fill.
  double get progressPercentage {
    if (expectedAmount <= 0) return 0;
    final progress = actualAmount / expectedAmount;
    return progress.clamp(0.0, 1.0);
  }

  /// Get status of the plan item
  PlanItemStatus get status {
    if (isOverBudget) return PlanItemStatus.overBudget;
    if (isNearLimit) return PlanItemStatus.nearLimit;
    if (actualAmount == 0) return PlanItemStatus.noActivity;
    return PlanItemStatus.inProgress;
  }

  PlanItem copyWith({
    String? id,
    String? planId,
    String? name,
    String? description,
    double? expectedAmount,
    int? iconIndex,
    RecurrenceType? recurrenceType,
    double? actualAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlanItem(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      name: name ?? this.name,
      description: description ?? this.description,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      iconIndex: iconIndex ?? this.iconIndex,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      actualAmount: actualAmount ?? this.actualAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        planId,
        name,
        description,
        expectedAmount,
        iconIndex,
        recurrenceType,
        actualAmount,
        createdAt,
        updatedAt,
      ];
}

/// Status enum for plan items
enum PlanItemStatus {
  inProgress,
  nearLimit,
  overBudget,
  noActivity,
}
