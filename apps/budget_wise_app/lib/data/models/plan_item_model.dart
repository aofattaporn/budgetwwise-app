import '../../domain/entities/plan_item.dart';

/// Data model for PlanItem with JSON serialization
class PlanItemModel extends PlanItem {
  const PlanItemModel({
    required super.id,
    required super.planId,
    required super.name,
    super.description,
    required super.expectedAmount,
    super.actualAmount,
    super.createdAt,
    super.updatedAt,
  });

  /// Create PlanItemModel from JSON (Supabase response)
  factory PlanItemModel.fromJson(Map<String, dynamic> json) {
    return PlanItemModel(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      expectedAmount: (json['expected_amount'] as num).toDouble(),
      actualAmount: json['actual_amount'] != null
          ? (json['actual_amount'] as num).toDouble()
          : 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert PlanItemModel to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'name': name,
      'expected_amount': expectedAmount,
    };
  }

  /// Convert to JSON for insert (without id)
  Map<String, dynamic> toInsertJson() {
    return {
      'plan_id': planId,
      'name': name,
      'description': description,
      'expected_amount': expectedAmount,
    };
  }

  /// Convert to JSON for update
  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'description': description,
      'expected_amount': expectedAmount,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Create PlanItemModel from PlanItem entity
  factory PlanItemModel.fromEntity(PlanItem item) {
    return PlanItemModel(
      id: item.id,
      planId: item.planId,
      name: item.name,
      description: item.description,
      expectedAmount: item.expectedAmount,
      actualAmount: item.actualAmount,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    );
  }

  /// Convert to PlanItem entity
  PlanItem toEntity() {
    return PlanItem(
      id: id,
      planId: planId,
      name: name,
      description: description,
      expectedAmount: expectedAmount,
      actualAmount: actualAmount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create a copy with actual amount
  PlanItemModel copyWithActual(double actual) {
    return PlanItemModel(
      id: id,
      planId: planId,
      name: name,
      description: description,
      expectedAmount: expectedAmount,
      actualAmount: actual,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
