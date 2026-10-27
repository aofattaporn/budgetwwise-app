import 'package:app_template/data/datasources/plan_datasource.dart';
import 'package:app_template/data/models/plan_item_model.dart';
import 'package:app_template/data/repositories/plan_repository_impl.dart';
import 'package:app_template/domain/entities/plan_item.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDataSource implements PlanDataSource {
  final calls = <String>[];

  @override
  Future<int?> revisePlan(String planId, Map<String, double> amounts,
      {String? note}) async {
    calls.add('revise $planId $amounts');
    return null;
  }

  @override
  Future<PlanItemModel> updatePlanItem(PlanItemModel item) async {
    calls.add('update ${item.id}');
    return item;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('updatePlanItem routes the amount through revisePlan before updating',
      () async {
    final ds = _FakeDataSource();
    await PlanRepositoryImpl(ds).updatePlanItem(const PlanItem(
      id: 'fuel',
      planId: 'p1',
      name: 'Fuel',
      expectedAmount: 2500,
    ));
    expect(ds.calls, ['revise p1 {fuel: 2500.0}', 'update fuel']);
  });
}
