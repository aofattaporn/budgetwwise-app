part of 'active_plan_bloc.dart';

/// Events for ActivePlanBloc
abstract class ActivePlanEvent extends Equatable {
  const ActivePlanEvent();

  @override
  List<Object?> get props => [];
}

/// Load the active plan and its items
class LoadActivePlan extends ActivePlanEvent {
  const LoadActivePlan();
}

/// Refresh the active plan data
class RefreshActivePlan extends ActivePlanEvent {
  const RefreshActivePlan();
}

/// Close the current active plan
class CloseActivePlanRequested extends ActivePlanEvent {
  const CloseActivePlanRequested();
}

/// Add a new plan item
class AddPlanItemRequested extends ActivePlanEvent {
  final String name;
  final String? description;
  final double expectedAmount;

  const AddPlanItemRequested({
    required this.name,
    this.description,
    required this.expectedAmount,
  });

  @override
  List<Object?> get props => [name, description, expectedAmount];
}

/// Delete a plan item
class DeletePlanItemRequested extends ActivePlanEvent {
  final String itemId;

  const DeletePlanItemRequested(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

/// Update a plan item
class UpdatePlanItemRequested extends ActivePlanEvent {
  final String itemId;
  final String? name;
  final String? description;
  final double? expectedAmount;

  const UpdatePlanItemRequested({
    required this.itemId,
    this.name,
    this.description,
    this.expectedAmount,
  });

  @override
  List<Object?> get props => [itemId, name, description, expectedAmount];
}

/// Create a new plan
class CreatePlanRequested extends ActivePlanEvent {
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final double? expectedIncome;
  final bool isActive;

  const CreatePlanRequested({
    required this.name,
    required this.startDate,
    required this.endDate,
    this.expectedIncome,
    this.isActive = true,
  });

  @override
  List<Object?> get props =>
      [name, startDate, endDate, expectedIncome, isActive];
}

/// Update existing plan
class UpdatePlanRequested extends ActivePlanEvent {
  final String planId;
  final String? name;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? expectedIncome;
  final bool? isActive;

  const UpdatePlanRequested({
    required this.planId,
    this.name,
    this.startDate,
    this.endDate,
    this.expectedIncome,
    this.isActive,
  });

  @override
  List<Object?> get props =>
      [planId, name, startDate, endDate, expectedIncome, isActive];
}
