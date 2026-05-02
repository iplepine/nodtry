import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/repositories/mock_record_repository.dart';

void main() {
  test(
    'completeOverduePlans completes expired pending approval plans',
    () async {
      final repository = MockRecordRepository();
      final now = DateTime.now();
      final plan = Plan(
        id: 'expired-pending',
        userId: 'me',
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now.subtract(const Duration(days: 1)),
        state: PlanState.pendingApproval,
        items: [
          PlanItem(title: 'Read', days: const [1, 2, 3, 4, 5, 6, 7], count: 1),
        ],
        createdAt: now.subtract(const Duration(days: 7)),
      );

      await repository.createPlan(plan);

      final completedPlanIds = await repository.completeOverduePlans();
      final plans = await repository.getPlansByUserId('me');
      final completedPlan = plans.firstWhere((p) => p.id == 'expired-pending');

      expect(completedPlanIds, contains('expired-pending'));
      expect(completedPlan.state, PlanState.completed);
    },
  );
}
