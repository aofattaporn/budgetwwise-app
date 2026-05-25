import 'package:app_template/domain/entities/plan.dart';
import 'package:flutter_test/flutter_test.dart';

Plan _plan({required DateTime start, required DateTime end}) => Plan(
      id: 'p1',
      name: 'May budget',
      startDate: start,
      endDate: end,
    );

void main() {
  group('Plan.isInProgress', () {
    final now = DateTime.now();

    test('true when now is within the plan window', () {
      final plan = _plan(
        start: now.subtract(const Duration(days: 5)),
        end: now.add(const Duration(days: 5)),
      );
      expect(plan.isInProgress, isTrue);
    });

    test('false when the window is entirely in the past', () {
      final plan = _plan(
        start: now.subtract(const Duration(days: 10)),
        end: now.subtract(const Duration(days: 5)),
      );
      expect(plan.isInProgress, isFalse);
    });

    test('false when the window is entirely in the future', () {
      final plan = _plan(
        start: now.add(const Duration(days: 5)),
        end: now.add(const Duration(days: 10)),
      );
      expect(plan.isInProgress, isFalse);
    });
  });
}
