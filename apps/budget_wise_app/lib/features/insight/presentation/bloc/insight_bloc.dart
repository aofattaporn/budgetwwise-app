import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/plan.dart';
import '../../../../domain/entities/plan_item.dart';
import '../../../../domain/repositories/plan_repository.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';

part 'insight_event.dart';
part 'insight_state.dart';

class InsightBloc extends Bloc<InsightEvent, InsightState> {
  final TransactionRepository _transactionRepository;
  final PlanRepository _planRepository;

  InsightBloc({
    required TransactionRepository transactionRepository,
    required PlanRepository planRepository,
  })  : _transactionRepository = transactionRepository,
        _planRepository = planRepository,
        super(InsightState.initial()) {
    on<LoadInsightData>(_onLoad);
    on<RefreshInsightData>(_onRefresh);
    on<ChangeInsightPlan>(_onChangePlan);
  }

  Future<void> _onLoad(
    LoadInsightData event,
    Emitter<InsightState> emit,
  ) async {
    emit(state.copyWith(status: InsightStatus.loading));
    await _loadPlansAndData(emit);
  }

  Future<void> _onRefresh(
    RefreshInsightData event,
    Emitter<InsightState> emit,
  ) async {
    // Drop cached plans/items so a refresh re-reads from the DB. Transactions
    // are never cached, but plan data has a 5-min TTL and would otherwise be
    // served stale on pull-to-refresh / tab switch.
    _planRepository.invalidateCache();
    await _loadPlansAndData(emit);
  }

  Future<void> _onChangePlan(
    ChangeInsightPlan event,
    Emitter<InsightState> emit,
  ) async {
    emit(state.copyWith(
      selectedPlanIndex: event.planIndex,
      status: InsightStatus.loading,
    ));
    await _fetchDataForSelectedPlan(emit);
  }

  /// Load all plans, find active plan index, then fetch transactions
  Future<void> _loadPlansAndData(Emitter<InsightState> emit) async {
    try {
      // Load all plans sorted by startDate descending (newest first)
      List<Plan> allPlans = [];
      Plan? activePlan;
      try {
        allPlans = await _planRepository.getAllPlans();
        // Sort newest first
        allPlans.sort((a, b) => b.startDate.compareTo(a.startDate));
        activePlan = await _planRepository.getActivePlan();
      } catch (_) {
        // Plans are optional
      }

      // Find index of active plan
      int activeIndex = 0;
      if (activePlan != null) {
        activeIndex = allPlans.indexWhere((p) => p.id == activePlan!.id);
        if (activeIndex < 0) activeIndex = 0;
      }

      emit(state.copyWith(
        allPlans: allPlans,
        selectedPlanIndex: activeIndex,
        activePlan: activePlan,
        clearPlan: activePlan == null,
      ));

      await _fetchDataForSelectedPlan(emit);
    } catch (e) {
      emit(state.copyWith(
        status: InsightStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Fetch transactions and plan items for the currently selected plan
  Future<void> _fetchDataForSelectedPlan(Emitter<InsightState> emit) async {
    try {
      final plan = state.selectedPlan;

      // Date range from plan, or current month fallback
      final start = state.periodStart;
      final end = DateTime(
          state.periodEnd.year, state.periodEnd.month, state.periodEnd.day,
          23, 59, 59);

      final transactions =
          await _transactionRepository.getTransactionsByDateRange(
        start: start,
        end: end,
      );

      // Load plan items for category names + budgets
      List<PlanItem> planItems = [];
      if (plan != null) {
        try {
          planItems = await _planRepository.getPlanItems(plan.id);
        } catch (_) {}
      }

      emit(state.copyWith(
        status: InsightStatus.loaded,
        transactions: transactions,
        planItems: planItems,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: InsightStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
