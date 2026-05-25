import 'package:app_template/domain/entities/plan_item.dart';
import 'package:flutter_test/flutter_test.dart';

PlanItem _item({required double expected, double actual = 0}) => PlanItem(
      id: 'i1',
      planId: 'p1',
      name: 'Groceries',
      expectedAmount: expected,
      actualAmount: actual,
    );

void main() {
  group('PlanItem amounts', () {
    test('remainingAmount = expected - actual', () {
      expect(_item(expected: 100, actual: 30).remainingAmount, 70);
    });

    test('overAmount is the excess only when over budget', () {
      expect(_item(expected: 100, actual: 120).overAmount, 20);
      expect(_item(expected: 100, actual: 80).overAmount, 0);
    });
  });

  group('PlanItem.progressPercentage', () {
    test('is the used ratio for a normal item', () {
      expect(_item(expected: 100, actual: 25).progressPercentage, 0.25);
    });

    test('is capped at 1.0 when over budget', () {
      expect(_item(expected: 100, actual: 150).progressPercentage, 1.0);
    });

    test('is 0 when expectedAmount <= 0 (guard against divide-by-zero)', () {
      expect(_item(expected: 0).progressPercentage, 0);
    });
  });

  group('PlanItem.status / flags', () {
    test('noActivity when nothing has been spent', () {
      final item = _item(expected: 100, actual: 0);
      expect(item.status, PlanItemStatus.noActivity);
      expect(item.isOverBudget, isFalse);
      expect(item.isNearLimit, isFalse);
    });

    test('inProgress below the 85% threshold', () {
      final item = _item(expected: 100, actual: 84);
      expect(item.isNearLimit, isFalse);
      expect(item.status, PlanItemStatus.inProgress);
    });

    test('nearLimit exactly at the 85% threshold', () {
      final item = _item(expected: 100, actual: 85);
      expect(item.isNearLimit, isTrue);
      expect(item.status, PlanItemStatus.nearLimit);
    });

    test('overBudget when actual exceeds expected', () {
      final item = _item(expected: 100, actual: 101);
      expect(item.isOverBudget, isTrue);
      expect(item.isNearLimit, isFalse,
          reason: 'over budget should not also report near-limit');
      expect(item.status, PlanItemStatus.overBudget);
    });
  });
}
