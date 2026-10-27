import 'package:app_template/domain/entities/plan_item.dart';
import 'package:app_template/domain/entities/plan_revision.dart';
import 'package:flutter_test/flutter_test.dart';

PlanItem _current(String id, {double expected = 0, double actual = 0, bool tracking = false}) =>
    PlanItem(
      id: id,
      planId: 'p1',
      name: 'current $id',
      expectedAmount: expected,
      actualAmount: actual,
      isTrackingOnly: tracking,
    );

PlanRevision _revision(List<PlanRevisionItem> items) => PlanRevision(
      id: 'r1',
      planId: 'p1',
      revisionNo: 1,
      items: items,
      createdAt: DateTime(2026, 10, 1),
    );

void main() {
  group('PlanRevision.totalPlanned', () {
    test('sums budgets, excluding tracking-only items', () {
      final rev = _revision(const [
        PlanRevisionItem(itemId: 'a', name: 'Fuel', expectedAmount: 3000),
        PlanRevisionItem(itemId: 'b', name: 'Food', expectedAmount: 5000),
        PlanRevisionItem(
            itemId: 'c', name: 'IOU', expectedAmount: 999, isTrackingOnly: true),
      ]);
      expect(rev.totalPlanned, 8000);
    });
  });

  group('PlanRevision.compareWith', () {
    final rev = _revision(const [
      PlanRevisionItem(itemId: 'fuel', name: 'Fuel', expectedAmount: 3000),
      PlanRevisionItem(itemId: 'food', name: 'Food', expectedAmount: 5000),
    ]);

    test('maps today\'s actuals onto the old budgets', () {
      final rows = rev.compareWith([
        _current('fuel', expected: 2000, actual: 1200),
        _current('food', expected: 6000, actual: 5400),
      ]);

      final fuel = rows.firstWhere((r) => r.itemId == 'fuel');
      expect(fuel.budget, 3000);
      expect(fuel.difference, 1800);
      expect(fuel.isOver, isFalse);

      final food = rows.firstWhere((r) => r.itemId == 'food');
      expect(food.difference, -400);
      expect(food.isOver, isTrue);
    });

    test('uses the current item name so renames show up', () {
      final rows = rev.compareWith([_current('fuel')]);
      expect(rows.firstWhere((r) => r.itemId == 'fuel').name, 'current fuel');
    });

    test('items with no current match count as 0 spent', () {
      final rows = rev.compareWith(const []);
      expect(rows.map((r) => r.actual), everyElement(0));
    });

    test('items added after the revision have no budget', () {
      final rows = rev.compareWith([_current('new', actual: 50)]);
      final added = rows.firstWhere((r) => r.itemId == 'new');
      expect(added.budget, isNull);
      expect(added.difference, isNull);
      expect(added.isOver, isFalse);
    });

    test('tracking-only items never read as over', () {
      final tracking = _revision(const [
        PlanRevisionItem(
            itemId: 't', name: 'IOU', expectedAmount: 100, isTrackingOnly: true),
      ]);
      final row = tracking.compareWith([_current('t', actual: 500)]).single;
      expect(row.difference, -400);
      expect(row.isOver, isFalse);
    });
  });

  group('PlanRevision.restoreAmounts', () {
    final v1 = _revision(const [
      PlanRevisionItem(itemId: 'fuel', name: 'Fuel', expectedAmount: 3000),
      PlanRevisionItem(itemId: 'food', name: 'Food', expectedAmount: 5000),
    ]);

    test('returns only the items whose budget differs from v1', () {
      final amounts = v1.restoreAmounts([
        _current('fuel', expected: 2000),
        _current('food', expected: 5000),
      ]);
      expect(amounts, {'fuel': 3000});
    });

    test('leaves items added after v1 untouched', () {
      final amounts = v1.restoreAmounts([
        _current('fuel', expected: 2000),
        _current('new', expected: 700),
      ]);
      expect(amounts.containsKey('new'), isFalse);
    });

    test('restoredTotal applies restored budgets and keeps the rest', () {
      final current = [
        _current('fuel', expected: 2000),
        _current('food', expected: 6000),
        _current('new', expected: 700),
        _current('iou', expected: 999, tracking: true),
      ];
      expect(v1.restoredTotal(current), 3000 + 5000 + 700);
    });
  });
}
