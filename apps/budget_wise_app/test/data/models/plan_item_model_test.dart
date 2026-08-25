import 'package:app_template/data/models/plan_item_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlanItemModel.fromJson', () {
    test('maps all fields and parses numeric/date values', () {
      final model = PlanItemModel.fromJson({
        'id': 'i1',
        'plan_id': 'p1',
        'name': 'Groceries',
        'description': 'food',
        'expected_amount': 250,
        'icon_index': 3,
        'actual_amount': 100.5,
        'created_at': '2026-05-01T00:00:00.000Z',
        'updated_at': '2026-05-02T00:00:00.000Z',
        'is_tracking_only': true,
      });

      expect(model.id, 'i1');
      expect(model.planId, 'p1');
      expect(model.expectedAmount, 250.0);
      expect(model.iconIndex, 3);
      expect(model.actualAmount, 100.5);
      expect(model.createdAt, DateTime.parse('2026-05-01T00:00:00.000Z'));
      expect(model.isTrackingOnly, isTrue);
    });

    test('defaults actualAmount to 0 and tolerates null optionals', () {
      final model = PlanItemModel.fromJson({
        'id': 'i1',
        'plan_id': 'p1',
        'name': 'Rent',
        'description': null,
        'expected_amount': 1000,
        'icon_index': null,
        'actual_amount': null,
        'created_at': null,
        'updated_at': null,
      });

      expect(model.actualAmount, 0);
      expect(model.description, isNull);
      expect(model.iconIndex, isNull);
      expect(model.createdAt, isNull);
      expect(model.isTrackingOnly, isFalse);
    });
  });

  test('fromEntity -> toEntity round-trips the data', () {
    final original = PlanItemModel.fromJson({
      'id': 'i1',
      'plan_id': 'p1',
      'name': 'Groceries',
      'expected_amount': 250,
      'actual_amount': 40,
      'is_tracking_only': true,
    });

    final roundTripped = PlanItemModel.fromEntity(original.toEntity());

    expect(roundTripped.id, original.id);
    expect(roundTripped.expectedAmount, original.expectedAmount);
    expect(roundTripped.actualAmount, original.actualAmount);
    expect(roundTripped.isTrackingOnly, isTrue);
  });
}
