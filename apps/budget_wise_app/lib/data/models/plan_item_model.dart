import '../../domain/entities/plan_item.dart';

/// Data model for PlanItem with JSON serialization
class PlanItemModel extends PlanItem {
  const PlanItemModel({
    required super.id,
    required super.planId,
    required super.name,
    super.description,
    required super.expectedAmount,
    super.iconIndex,
    super.recurrenceType,
    super.actualAmount,
    super.createdAt,
    super.updatedAt,
  });

  factory PlanItemModel.fromJson(Map<String, dynamic> json) {
    return PlanItemModel(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      expectedAmount: (json['expected_amount'] as num).toDouble(),
      iconIndex: json['icon_index'] as int?,
      recurrenceType: RecurrenceType.fromValue(json['recurrence_type'] as String?),
      actualAmount: json['actual_amount'] != null
          ? (json['actual_amount'] as num).toDouble()
          : 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'name': name,
      'expected_amount': expectedAmount,
      'recurrence_type': recurrenceType.value,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'plan_id': planId,
      'name': name,
      'description': description,
      'expected_amount': expectedAmount,
      'icon_index': iconIndex,
      'recurrence_type': recurrenceType.value,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'description': description,
      'expected_amount': expectedAmount,
      'icon_index': iconIndex,
      'recurrence_type': recurrenceType.value,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory PlanItemModel.fromEntity(PlanItem item) {
    return PlanItemModel(
      id: item.id,
      planId: item.planId,
      name: item.name,
      description: item.description,
      expectedAmount: item.expectedAmount,
      iconIndex: item.iconIndex,
      recurrenceType: item.recurrenceType,
      actualAmount: item.actualAmount,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    );
  }

  PlanItem toEntity() {
    return PlanItem(
      id: id,
      planId: planId,
      name: name,
      description: description,
      expectedAmount: expectedAmount,
      iconIndex: iconIndex,
      recurrenceType: recurrenceType,
      actualAmount: actualAmount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  PlanItemModel copyWithActual(double actual) {
    return PlanItemModel(
      id: id,
      planId: planId,
      name: name,
      description: description,
      expectedAmount: expectedAmount,
      iconIndex: iconIndex,
      recurrenceType: recurrenceType,
      actualAmount: actual,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
