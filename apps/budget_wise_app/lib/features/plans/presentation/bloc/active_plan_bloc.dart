import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/plan.dart';
import '../../../../domain/entities/plan_item.dart';
import '../../../../domain/repositories/plan_repository.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';

part 'active_plan_event.dart';
part 'active_plan_state.dart';

/// BLoC for managing active plan state
class ActivePlanBloc extends Bloc<ActivePlanEvent, ActivePlanState> {
  final PlanRepository _planRepository;
  final TransactionRepository _transactionRepository;

  ActivePlanBloc({
    required PlanRepository planRepository,
    required TransactionRepository transactionRepository,
  })  : _planRepository = planRepository,
        _transactionRepository = transactionRepository,
        super(const ActivePlanState()) {
    on<LoadActivePlan>(_onLoadActivePlan);
    on<RefreshActivePlan>(_onRefreshActivePlan);
    on<CloseActivePlanRequested>(_onCloseActivePlan);
    on<AddPlanItemRequested>(_onAddPlanItem);
    on<DeletePlanItemRequested>(_onDeletePlanItem);
    on<UpdatePlanItemRequested>(_onUpdatePlanItem);
    on<CreatePlanRequested>(_onCreatePlan);
    on<UpdatePlanRequested>(_onUpdatePlan);
  }

  Future<void> _onLoadActivePlan(
    LoadActivePlan event,
    Emitter<ActivePlanState> emit,
  ) async {
    emit(state.copyWith(status: ActivePlanStatus.loading));

    try {
      final plan = await _planRepository.getActivePlan();

      if (plan == null) {
        emit(state.copyWith(
          status: ActivePlanStatus.loaded,
          clearPlan: true,
          planItems: [],
          actualIncome: 0,
        ));
        return;
      }

      final planItems = await _planRepository.getPlanItems(plan.id);
      final actualIncome = await _planRepository.getActualIncome(plan.id);

      emit(state.copyWith(
        status: ActivePlanStatus.loaded,
        plan: plan,
        planItems: planItems,
        actualIncome: actualIncome,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ActivePlanStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshActivePlan(
    RefreshActivePlan event,
    Emitter<ActivePlanState> emit,
  ) async {
    // Don't show loading state for refresh
    try {
      final plan = await _planRepository.getActivePlan();

      if (plan == null) {
        emit(state.copyWith(
          status: ActivePlanStatus.loaded,
          clearPlan: true,
          planItems: [],
          actualIncome: 0,
        ));
        return;
      }

      final planItems = await _planRepository.getPlanItems(plan.id);
      final actualIncome = await _planRepository.getActualIncome(plan.id);

      emit(state.copyWith(
        status: ActivePlanStatus.loaded,
        plan: plan,
        planItems: planItems,
        actualIncome: actualIncome,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ActivePlanStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCloseActivePlan(
    CloseActivePlanRequested event,
    Emitter<ActivePlanState> emit,
  ) async {
    if (state.plan == null) return;

    try {
      await _planRepository.closePlan(state.plan!.id);

      emit(state.copyWith(
        status: ActivePlanStatus.loaded,
        clearPlan: true,
        planItems: [],
        actualIncome: 0,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ActivePlanStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAddPlanItem(
    AddPlanItemRequested event,
    Emitter<ActivePlanState> emit,
  ) async {
    if (state.plan == null) return;

    try {
      final newItem = await _planRepository.addPlanItem(
        planId: state.plan!.id,
        name: event.name,
        description: event.description,
        expectedAmount: event.expectedAmount,
      );

      emit(state.copyWith(
        planItems: [...state.planItems, newItem],
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ActivePlanStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDeletePlanItem(
    DeletePlanItemRequested event,
    Emitter<ActivePlanState> emit,
  ) async {
    try {
      // Check if any transactions reference this plan item
      final txnCount = await _transactionRepository.countByPlanItemId(event.itemId);
      if (txnCount > 0) {
        emit(state.copyWith(
          status: ActivePlanStatus.error,
          errorMessage:
              'Cannot delete — $txnCount ${txnCount == 1 ? 'transaction is' : 'transactions are'} linked. Remove or reassign them first.',
        ));
        // Restore to loaded so UI isn't stuck on error
        emit(state.copyWith(status: ActivePlanStatus.loaded));
        return;
      }

      await _planRepository.deletePlanItem(event.itemId);

      emit(state.copyWith(
        planItems:
            state.planItems.where((item) => item.id != event.itemId).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ActivePlanStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUpdatePlanItem(
    UpdatePlanItemRequested event,
    Emitter<ActivePlanState> emit,
  ) async {
    try {
      final existingItem = state.planItems.firstWhere(
        (item) => item.id == event.itemId,
      );

      final updatedItem = existingItem.copyWith(
        name: event.name,
        description: event.description,
        expectedAmount: event.expectedAmount,
      );

      final result = await _planRepository.updatePlanItem(updatedItem);

      emit(state.copyWith(
        planItems: state.planItems.map((item) {
          return item.id == event.itemId ? result : item;
        }).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ActivePlanStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCreatePlan(
    CreatePlanRequested event,
    Emitter<ActivePlanState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ActivePlanStatus.loading));

      final newPlan = await _planRepository.createPlan(
        name: event.name,
        startDate: event.startDate,
        endDate: event.endDate,
        expectedIncome: event.expectedIncome,
        isActive: event.isActive,
      );

      emit(state.copyWith(
        status: ActivePlanStatus.loaded,
        plan: newPlan,
        planItems: [],
        actualIncome: 0,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ActivePlanStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUpdatePlan(
    UpdatePlanRequested event,
    Emitter<ActivePlanState> emit,
  ) async {
    if (state.plan == null) return;

    try {
      final updatedPlan = state.plan!.copyWith(
        name: event.name,
        startDate: event.startDate,
        endDate: event.endDate,
        expectedIncome: event.expectedIncome,
        isActive: event.isActive,
      );

      final result = await _planRepository.updatePlan(updatedPlan);

      emit(state.copyWith(
        plan: result,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ActivePlanStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
