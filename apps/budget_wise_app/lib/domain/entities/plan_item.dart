import 'package:equatable/equatable.dart';

/// Plan item entity representing a budget category within a plan
class PlanItem extends Equatable {
  final String id;
  final String planId;
  final String name;
  final String? description;
  final double expectedAmount;
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
  double get progressPercentage {
    if (expectedAmount <= 0) return 0;
    final progress = actualAmount / expectedAmount;
    return progress > 1 ? 1 : progress;
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
