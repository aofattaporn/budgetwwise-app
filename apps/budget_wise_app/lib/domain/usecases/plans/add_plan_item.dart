import '../../entities/plan_item.dart';
import '../../repositories/plan_repository.dart';

/// Use case to add an item to a plan
class AddPlanItem {
  final PlanRepository repository;

  AddPlanItem(this.repository);

  Future<PlanItem> call({
    required String planId,
    required String name,
    required double expectedAmount,
    String? description,
    int? iconIndex,
    RecurrenceType recurrenceType = RecurrenceType.daily,
  }) async {
    return await repository.addPlanItem(
      planId: planId,
      name: name,
      expectedAmount: expectedAmount,
      description: description,
      iconIndex: iconIndex,
      recurrenceType: recurrenceType,
    );
  }
}
