import '../../domain/entities/plan.dart';

/// Data model for Plan with JSON serialization
class PlanModel extends Plan {
  const PlanModel({
    required super.id,
    required super.name,
    required super.startDate,
    required super.endDate,
    super.expectedIncome,
    super.isActive,
    super.createdAt,
    super.updatedAt,
  });

  /// Create PlanModel from JSON (Supabase response)
  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'] as String,
      name: json['name'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      expectedIncome: json['expected_income'] != null
          ? (json['expected_income'] as num).toDouble()
          : null,
      isActive: json['is_active'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : null,
    );
  }

  /// Convert PlanModel to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'expected_income': expectedIncome,
      'is_active': isActive,
    };
  }

  /// Convert to JSON for insert (without id)
  Map<String, dynamic> toInsertJson() {
    return {
      'name': name,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'expected_income': expectedIncome,
      'is_active': isActive,
    };
  }

  /// Convert to JSON for update
  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'expected_income': expectedIncome,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Create PlanModel from Plan entity
  factory PlanModel.fromEntity(Plan plan) {
    return PlanModel(
      id: plan.id,
      name: plan.name,
      startDate: plan.startDate,
      endDate: plan.endDate,
      expectedIncome: plan.expectedIncome,
      isActive: plan.isActive,
      createdAt: plan.createdAt,
      updatedAt: plan.updatedAt,
    );
  }

  /// Convert to Plan entity
  Plan toEntity() {
    return Plan(
      id: id,
      name: name,
      startDate: startDate,
      endDate: endDate,
      expectedIncome: expectedIncome,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
