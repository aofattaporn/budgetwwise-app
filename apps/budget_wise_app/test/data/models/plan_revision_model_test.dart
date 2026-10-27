import 'package:app_template/data/models/plan_revision_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PlanRevisionModel.fromJson parses a plan_revisions row', () {
    final model = PlanRevisionModel.fromJson({
      'id': 'r1',
      'plan_id': 'p1',
      'revision_no': 2,
      'note': 'fuel under, food short',
      'expected_income': 30000,
      'created_at': '2026-10-15T03:00:00Z',
      'items': [
        {
          'item_id': 'i1',
          'name': 'Fuel',
          'expected_amount': 2000.5,
          'icon_index': 3,
          'is_tracking_only': false,
        },
        {'item_id': 'i2', 'name': 'IOU', 'expected_amount': 0},
      ],
    });

    expect(model.revisionNo, 2);
    expect(model.note, 'fuel under, food short');
    expect(model.expectedIncome, 30000);
    expect(model.createdAt.isUtc, isFalse);
    expect(model.items, hasLength(2));
    expect(model.items.first.expectedAmount, 2000.5);
    expect(model.items.first.iconIndex, 3);
    expect(model.items.last.isTrackingOnly, isFalse);
    expect(model.items.last.iconIndex, isNull);
  });

  test('PlanRevisionModel.fromJson tolerates null income and note', () {
    final model = PlanRevisionModel.fromJson({
      'id': 'r1',
      'plan_id': 'p1',
      'revision_no': 1,
      'note': null,
      'expected_income': null,
      'created_at': '2026-10-01T00:00:00Z',
      'items': [],
    });
    expect(model.note, isNull);
    expect(model.expectedIncome, isNull);
    expect(model.items, isEmpty);
  });
}
