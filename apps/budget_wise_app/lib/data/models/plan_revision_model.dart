import '../../domain/entities/plan_revision.dart';

/// Data model for PlanRevision with JSON serialization
class PlanRevisionModel extends PlanRevision {
  const PlanRevisionModel({
    required super.id,
    required super.planId,
    required super.revisionNo,
    super.note,
    super.expectedIncome,
    required super.items,
    required super.createdAt,
  });

  factory PlanRevisionModel.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? const [];
    return PlanRevisionModel(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      revisionNo: json['revision_no'] as int,
      note: json['note'] as String?,
      expectedIncome: json['expected_income'] != null
          ? (json['expected_income'] as num).toDouble()
          : null,
      items: rawItems
          .cast<Map<String, dynamic>>()
          .map((i) => PlanRevisionItem(
                itemId: i['item_id'] as String,
                name: i['name'] as String,
                expectedAmount: (i['expected_amount'] as num).toDouble(),
                iconIndex: i['icon_index'] as int?,
                isTrackingOnly: i['is_tracking_only'] as bool? ?? false,
              ))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  PlanRevision toEntity() => PlanRevision(
        id: id,
        planId: planId,
        revisionNo: revisionNo,
        note: note,
        expectedIncome: expectedIncome,
        items: items,
        createdAt: createdAt,
      );
}
