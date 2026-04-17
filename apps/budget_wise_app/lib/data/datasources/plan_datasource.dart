import '../models/plan_model.dart';
import '../models/plan_item_model.dart';

/// Plan data source interface
/// Implemented by Supabase data sources
abstract class PlanDataSource {
  /// Get the currently active plan
  Future<PlanModel?> getActivePlan();

  /// Get all plans
  Future<List<PlanModel>> getAllPlans();

  /// Get plan by ID
  Future<PlanModel?> getPlanById(String id);

  /// Create a new plan
  Future<PlanModel> createPlan({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    double? expectedIncome,
    bool isActive = false,
  });

  /// Update an existing plan
  Future<PlanModel> updatePlan(PlanModel plan);

  /// Delete a plan
  Future<void> deletePlan(String id);

  /// Set plan as active (deactivates other plans)
  Future<PlanModel> setActivePlan(String id);

  /// Close/deactivate a plan
  Future<PlanModel> closePlan(String id);

  /// Get all items for a plan
  Future<List<PlanItemModel>> getPlanItems(String planId);

  /// Get plan item by ID
  Future<PlanItemModel?> getPlanItemById(String id);

  /// Add item to a plan
  Future<PlanItemModel> addPlanItem({
    required String planId,
    required String name,
    String? description,
    required double expectedAmount,
  });

  /// Update a plan item
  Future<PlanItemModel> updatePlanItem(PlanItemModel item);

  /// Delete a plan item
  Future<void> deletePlanItem(String id);

  /// Get actual amounts for plan items (from transactions)
  Future<Map<String, double>> getPlanItemActuals(String planId);

  /// Get total actual income for a plan
  Future<double> getActualIncome(String planId);
}
