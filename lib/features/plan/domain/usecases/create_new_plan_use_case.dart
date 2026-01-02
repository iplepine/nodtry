import '../../../../models/plan_model.dart';
import '../../../../repositories/record_repository.dart';

class CreateNewPlanUseCase {
  final RecordRepository _recordRepository;

  CreateNewPlanUseCase(this._recordRepository);

  Future<void> execute(Plan plan) {
    return _recordRepository.createPlan(plan);
  }
}
