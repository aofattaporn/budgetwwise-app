import 'package:equatable/equatable.dart';

import 'plan_item.dart';

/// A plan item as it was designed in one [PlanRevision].
class PlanRevisionItem extends Equatable {
  final String itemId;
  final String name;
  final double expectedAmount;
  final int? iconIndex;
  final bool isTrackingOnly;

  const PlanRevisionItem({
    required this.itemId,
    required this.name,
    required this.expectedAmount,
    this.iconIndex,
    this.isTrackingOnly = false,
  });

  @override
  List<Object?> get props =>
      [itemId, name, expectedAmount, iconIndex, isTrackingOnly];
}

/// A frozen snapshot of a plan's design. Revision N is the state of version N;
/// the live plan_items always hold the current version.
class PlanRevision extends Equatable {
  final String id;
  final String planId;
  final int revisionNo;
  final String? note;
  final double? expectedIncome;
  final List<PlanRevisionItem> items;
  final DateTime createdAt;

  const PlanRevision({
    required this.id,
    required this.planId,
    required this.revisionNo,
    this.note,
    this.expectedIncome,
    required this.items,
    required this.createdAt,
  });

  /// Total budgeted in this version, excluding tracking-only items.
  double get totalPlanned => items
      .where((i) => !i.isTrackingOnly)
      .fold(0.0, (sum, i) => sum + i.expectedAmount);

  /// Compares this version's budgets against today's actuals from
  /// [currentItems] — "how would each category land if I'd kept this design".
  /// Items added after this version appear with a null [budget].
  List<RevisionComparison> compareWith(List<PlanItem> currentItems) {
    final byId = {for (final i in currentItems) i.id: i};
    final rows = items
        .map((r) => RevisionComparison(
              itemId: r.itemId,
              name: byId[r.itemId]?.name ?? r.name,
              iconIndex: r.iconIndex,
              budget: r.expectedAmount,
              actual: byId[r.itemId]?.actualAmount ?? 0,
              isTrackingOnly: r.isTrackingOnly,
            ))
        .toList();
    final known = items.map((r) => r.itemId).toSet();
    rows.addAll(currentItems.where((i) => !known.contains(i.id)).map(
          (i) => RevisionComparison(
            itemId: i.id,
            name: i.name,
            iconIndex: i.iconIndex,
            budget: null,
            actual: i.actualAmount,
            isTrackingOnly: i.isTrackingOnly,
          ),
        ));
    return rows;
  }

  /// Amounts ({itemId: amount}) that bring [currentItems] back to this
  /// version's budgets. Only changed items are included; items added after
  /// this version (or since removed) are left untouched.
  Map<String, double> restoreAmounts(List<PlanItem> currentItems) {
    final budgets = {for (final r in items) r.itemId: r.expectedAmount};
    return {
      for (final i in currentItems)
        if (budgets.containsKey(i.id) && budgets[i.id] != i.expectedAmount)
          i.id: budgets[i.id]!,
    };
  }

  /// Total planned (excluding tracking-only) after [restoreAmounts] is applied.
  double restoredTotal(List<PlanItem> currentItems) {
    final restore = restoreAmounts(currentItems);
    return currentItems
        .where((i) => !i.isTrackingOnly)
        .fold(0.0, (sum, i) => sum + (restore[i.id] ?? i.expectedAmount));
  }

  @override
  List<Object?> get props =>
      [id, planId, revisionNo, note, expectedIncome, items, createdAt];
}

/// One row of [PlanRevision.compareWith].
class RevisionComparison extends Equatable {
  final String itemId;
  final String name;
  final int? iconIndex;

  /// Budget in the compared version; null when the item didn't exist yet.
  final double? budget;
  final double actual;
  final bool isTrackingOnly;

  const RevisionComparison({
    required this.itemId,
    required this.name,
    this.iconIndex,
    required this.budget,
    required this.actual,
    this.isTrackingOnly = false,
  });

  /// budget - actual: positive = left over, negative = over by that much.
  double? get difference => budget == null ? null : budget! - actual;

  bool get isOver => !isTrackingOnly && (difference ?? 0) < 0;

  @override
  List<Object?> get props =>
      [itemId, name, iconIndex, budget, actual, isTrackingOnly];
}
