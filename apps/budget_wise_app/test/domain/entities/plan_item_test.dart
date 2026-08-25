import 'package:app_template/domain/entities/plan_item.dart';
import 'package:flutter_test/flutter_test.dart';

PlanItem _item({
  required double expected,
  double actual = 0,
  bool isTrackingOnly = false,
}) =>
    PlanItem(
      id: 'i1',
      planId: 'p1',
      name: 'Groceries',
      expectedAmount: expected,
      actualAmount: actual,
      isTrackingOnly: isTrackingOnly,
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

  group('PlanItem with reimbursements exceeding spend (negative actual)', () {
    // Income tagged to a plan item offsets its spend, so actual can go below 0
    // — e.g. pay Netflix 536 then get 620 back. Nothing may render negatively.
    test('progressPercentage is floored at 0, not negative', () {
      expect(_item(expected: 100, actual: -20).progressPercentage, 0);
    });

    test('remainingAmount exceeds the budget rather than capping at it', () {
      expect(_item(expected: 100, actual: -20).remainingAmount, 120);
    });

    test('is neither over budget nor near limit', () {
      final item = _item(expected: 100, actual: -20);
      expect(item.isOverBudget, isFalse);
      expect(item.isNearLimit, isFalse);
      expect(item.overAmount, 0);
    });

    test('fully reimbursed item reads as noActivity', () {
      expect(_item(expected: 100, actual: 0).status, PlanItemStatus.noActivity);
    });
  });

  group('PlanItem.isTrackingOnly (e.g. money lent out)', () {
    test('never reports overBudget even when actual far exceeds expected', () {
      final item = _item(expected: 100, actual: 500, isTrackingOnly: true);
      expect(item.isOverBudget, isFalse);
      expect(item.status, isNot(PlanItemStatus.overBudget));
    });

    test('never reports nearLimit at the 85%+ threshold', () {
      final item = _item(expected: 100, actual: 90, isTrackingOnly: true);
      expect(item.isNearLimit, isFalse);
      expect(item.status, isNot(PlanItemStatus.nearLimit));
    });

    test('a matching non-tracking item at the same amounts does alarm', () {
      final tracked = _item(expected: 100, actual: 500, isTrackingOnly: false);
      expect(tracked.status, PlanItemStatus.overBudget);
    });

    test('status still reflects activity normally otherwise', () {
      expect(_item(expected: 100, actual: 0, isTrackingOnly: true).status,
          PlanItemStatus.noActivity);
      expect(_item(expected: 100, actual: 30, isTrackingOnly: true).status,
          PlanItemStatus.inProgress);
    });
  });
}
