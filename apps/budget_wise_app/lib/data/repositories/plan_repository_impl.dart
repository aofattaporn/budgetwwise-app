import '../../domain/entities/plan.dart';
import '../../domain/entities/plan_item.dart';
import '../../domain/repositories/plan_repository.dart';
import '../datasources/plan_datasource.dart';
import '../models/plan_model.dart';
import '../models/plan_item_model.dart';

/// Implementation of PlanRepository using PlanDataSource with caching
class PlanRepositoryImpl implements PlanRepository {
  final PlanDataSource _dataSource;

  // Cache variables
  Plan? _cachedActivePlan;
  List<Plan>? _cachedAllPlans;
  Map<String, List<PlanItem>> _cachedPlanItems = {};
  Map<String, double> _cachedActualIncome = {};
  DateTime? _lastFetch;

  // Cache duration (adjust as needed)
  static const _cacheDuration = Duration(minutes: 5);

  PlanRepositoryImpl(this._dataSource);

  bool _isCacheValid() {
    if (_lastFetch == null) return false;
    return DateTime.now().difference(_lastFetch!) < _cacheDuration;
  }

  void _invalidateCache() {
    _cachedActivePlan = null;
    _cachedAllPlans = null;
    _cachedPlanItems.clear();
    _cachedActualIncome.clear();
    _lastFetch = null;
  }

  @override
  void invalidateCache() => _invalidateCache();

  /// Invalidate only active plan cache - called when active status might change
  void _invalidateActivePlanCache() {
    _cachedActivePlan = null;
    _cachedAllPlans = null;
  }

  @override
  Future<Plan?> getActivePlan() async {
    // Always fetch fresh data for active plan to ensure accuracy
    // This is critical because active status can change from other screens
    final model = await _dataSource.getActivePlan();
    _cachedActivePlan = model?.toEntity();
    return _cachedActivePlan;
  }

  @override
  Future<List<Plan>> getAllPlans() async {
    if (_isCacheValid() && _cachedAllPlans != null) {
      return _cachedAllPlans!;
    }

    final models = await _dataSource.getAllPlans();
    _cachedAllPlans = models.map((m) => m.toEntity()).toList();
    _lastFetch = DateTime.now();
    return _cachedAllPlans!;
  }

  @override
  Future<Plan?> getPlanById(String id) async {
    final model = await _dataSource.getPlanById(id);
    return model?.toEntity();
  }

  @override
  Future<Plan> createPlan({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    double? expectedIncome,
    bool isActive = false,
  }) async {
    final model = await _dataSource.createPlan(
      name: name,
      startDate: startDate,
      endDate: endDate,
      expectedIncome: expectedIncome,
      isActive: isActive,
    );
    _invalidateCache();
    return model.toEntity();
  }

  @override
  Future<Plan> updatePlan(Plan plan) async {
    final model = PlanModel.fromEntity(plan);
    final updated = await _dataSource.updatePlan(model);
    _invalidateCache();
    return updated.toEntity();
  }

  @override
  Future<void> deletePlan(String id) async {
    await _dataSource.deletePlan(id);
    _invalidateCache();
  }

  @override
  Future<Plan> setActivePlan(String id) async {
    final model = await _dataSource.setActivePlan(id);
    _invalidateCache();
    return model.toEntity();
  }

  @override
  Future<Plan> closePlan(String id) async {
    final model = await _dataSource.closePlan(id);
    _invalidateCache();
    return model.toEntity();
  }

  @override
  Future<List<PlanItem>> getPlanItems(String planId) async {
    if (_isCacheValid() && _cachedPlanItems.containsKey(planId)) {
      return _cachedPlanItems[planId]!;
    }

    final models = await _dataSource.getPlanItems(planId);
    final actuals = await _dataSource.getPlanItemActuals(planId);

    final items = models.map((m) {
      final actual = actuals[m.id] ?? 0;
      return m.copyWithActual(actual).toEntity();
    }).toList();

    _cachedPlanItems[planId] = items;
    _lastFetch = DateTime.now();
    return items;
  }

  @override
  Future<PlanItem?> getPlanItemById(String id) async {
    final model = await _dataSource.getPlanItemById(id);
    return model?.toEntity();
  }

  @override
  Future<PlanItem> addPlanItem({
    required String planId,
    required String name,
    String? description,
    required double expectedAmount,
  }) async {
    final model = await _dataSource.addPlanItem(
      planId: planId,
      name: name,
      description: description,
      expectedAmount: expectedAmount,
    );
    _cachedPlanItems.remove(planId); // Invalidate only this plan's items
    return model.toEntity();
  }

  @override
  Future<PlanItem> updatePlanItem(PlanItem item) async {
    final model = PlanItemModel.fromEntity(item);
    final updated = await _dataSource.updatePlanItem(model);
    _cachedPlanItems.remove(item.planId); // Invalidate only this plan's items
    return updated.toEntity();
  }

  @override
  Future<void> deletePlanItem(String id) async {
    await _dataSource.deletePlanItem(id);
    _cachedPlanItems.clear(); // Clear all plan items cache
  }

  @override
  Future<Map<String, double>> getPlanItemActuals(String planId) async {
    return await _dataSource.getPlanItemActuals(planId);
  }

  @override
  Future<double> getActualIncome(String planId) async {
    if (_isCacheValid() && _cachedActualIncome.containsKey(planId)) {
      return _cachedActualIncome[planId]!;
    }

    final income = await _dataSource.getActualIncome(planId);
    _cachedActualIncome[planId] = income;
    _lastFetch = DateTime.now();
    return income;
  }
}
