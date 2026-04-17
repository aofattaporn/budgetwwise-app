import '../entities/plan.dart';
import '../entities/plan_item.dart';

/// Repository interface for Plan operations
abstract class PlanRepository {
  /// Get the currently active plan
  Future<Plan?> getActivePlan();

  /// Get all plans
  Future<List<Plan>> getAllPlans();

  /// Get plan by ID
  Future<Plan?> getPlanById(String id);

  /// Create a new plan
  Future<Plan> createPlan({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    double? expectedIncome,
    bool isActive = false,
  });

  /// Update an existing plan
  Future<Plan> updatePlan(Plan plan);

  /// Delete a plan
  Future<void> deletePlan(String id);

  /// Set plan as active (deactivates other plans)
  Future<Plan> setActivePlan(String id);

  /// Close/deactivate a plan
  Future<Plan> closePlan(String id);

  /// Get all items for a plan
  Future<List<PlanItem>> getPlanItems(String planId);

  /// Get plan item by ID
  Future<PlanItem?> getPlanItemById(String id);

  /// Add item to a plan
  Future<PlanItem> addPlanItem({
    required String planId,
    required String name,
    String? description,
    required double expectedAmount,
  });

  /// Update a plan item
  Future<PlanItem> updatePlanItem(PlanItem item);

  /// Delete a plan item
  Future<void> deletePlanItem(String id);

  /// Get actual amounts for plan items (from transactions)
  Future<Map<String, double>> getPlanItemActuals(String planId);

  /// Get total actual income for a plan
  Future<double> getActualIncome(String planId);

  /// Invalidate any cached data so next fetch is fresh
  void invalidateCache();
}
