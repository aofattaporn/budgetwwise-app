import 'package:supabase_flutter/supabase_flutter.dart';

import '../plan_datasource.dart';
import '../../models/plan_model.dart';
import '../../models/plan_item_model.dart';

/// Supabase implementation of PlanDataSource
class PlanSupabaseDataSource implements PlanDataSource {
  final SupabaseClient _client;

  static const String _plansTable = 'plans';
  static const String _planItemsTable = 'plan_items';

  PlanSupabaseDataSource(this._client);

  @override
  Future<PlanModel?> getActivePlan() async {
    final response = await _client
        .from(_plansTable)
        .select()
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) return null;
    return PlanModel.fromJson(response);
  }

  @override
  Future<List<PlanModel>> getAllPlans() async {
    final response = await _client
        .from(_plansTable)
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => PlanModel.fromJson(json))
        .toList();
  }

  @override
  Future<PlanModel?> getPlanById(String id) async {
    final response = await _client
        .from(_plansTable)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return PlanModel.fromJson(response);
  }

  @override
  Future<PlanModel> createPlan({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    double? expectedIncome,
    bool isActive = false,
  }) async {
    final data = {
      'name': name,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'expected_income': expectedIncome,
      'is_active': isActive,
    };

    final response = await _client
        .from(_plansTable)
        .insert(data)
        .select()
        .single();

    return PlanModel.fromJson(response);
  }

  @override
  Future<PlanModel> updatePlan(PlanModel plan) async {
    final response = await _client
        .from(_plansTable)
        .update(plan.toUpdateJson())
        .eq('id', plan.id)
        .select()
        .single();

    return PlanModel.fromJson(response);
  }

  @override
  Future<void> deletePlan(String id) async {
    await _client.from(_plansTable).delete().eq('id', id);
  }

  @override
  Future<PlanModel> setActivePlan(String id) async {
    // First, deactivate all plans
    await _client
        .from(_plansTable)
        .update({'is_active': false})
        .eq('is_active', true);

    // Then, activate the specified plan
    final response = await _client
        .from(_plansTable)
        .update({
          'is_active': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();

    return PlanModel.fromJson(response);
  }

  @override
  Future<PlanModel> closePlan(String id) async {
    final response = await _client
        .from(_plansTable)
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();

    return PlanModel.fromJson(response);
  }

  @override
  Future<List<PlanItemModel>> getPlanItems(String planId) async {
    final response = await _client
        .from(_planItemsTable)
        .select()
        .eq('plan_id', planId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => PlanItemModel.fromJson(json))
        .toList();
  }

  @override
  Future<PlanItemModel?> getPlanItemById(String id) async {
    final response = await _client
        .from(_planItemsTable)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return PlanItemModel.fromJson(response);
  }

  @override
  Future<PlanItemModel> addPlanItem({
    required String planId,
    required String name,
    String? description,
    required double expectedAmount,
  }) async {
    final data = {
      'plan_id': planId,
      'name': name,
      'description': description,
      'expected_amount': expectedAmount,
    };

    final response = await _client
        .from(_planItemsTable)
        .insert(data)
        .select()
        .single();

    return PlanItemModel.fromJson(response);
  }

  @override
  Future<PlanItemModel> updatePlanItem(PlanItemModel item) async {
    final response = await _client
        .from(_planItemsTable)
        .update(item.toUpdateJson())
        .eq('id', item.id)
        .select()
        .single();

    return PlanItemModel.fromJson(response);
  }

  @override
  Future<void> deletePlanItem(String id) async {
    await _client.from(_planItemsTable).delete().eq('id', id);
  }

  @override
  Future<Map<String, double>> getPlanItemActuals(String planId) async {
    try {
      // Get all plan_item IDs for this plan
      final itemsResponse = await _client
          .from(_planItemsTable)
          .select('id')
          .eq('plan_id', planId);

      final itemIds =
          (itemsResponse as List).map((e) => e['id'] as String).toList();

      if (itemIds.isEmpty) return {};

      // Get expense transactions linked to these plan items
      final txnResponse = await _client
          .from('transactions')
          .select('plan_item_id, amount')
          .eq('type', 'expense')
          .inFilter('plan_item_id', itemIds);

      final result = <String, double>{};
      for (final row in txnResponse as List) {
        final itemId = row['plan_item_id'] as String;
        final amount = double.parse(row['amount'].toString());
        result[itemId] = (result[itemId] ?? 0) + amount;
      }
      return result;
    } catch (e) {
      throw Exception('Failed to get plan item actuals: $e');
    }
  }

  @override
  Future<double> getActualIncome(String planId) async {
    try {
      // Get plan to determine the period
      final plan = await getPlanById(planId);
      if (plan == null) return 0;

      // Sum income transactions within the plan period
      final response = await _client
          .from('transactions')
          .select('amount')
          .eq('type', 'income')
          .gte('occurred_at', plan.startDate.toIso8601String())
          .lte('occurred_at', plan.endDate.toIso8601String());

      double total = 0;
      for (final row in response as List) {
        total += double.parse(row['amount'].toString());
      }
      return total;
    } catch (e) {
      throw Exception('Failed to get actual income: $e');
    }
  }
}
