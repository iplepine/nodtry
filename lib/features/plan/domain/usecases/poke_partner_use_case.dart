import '../../../../models/promise_model.dart';
import '../../../../repositories/record_repository.dart';

class PokePartnerUseCase {
  final RecordRepository _repository;

  PokePartnerUseCase(this._repository);

  /// 파트너 찌르기 (똑똑) + 선택적 약속 제안
  Future<void> execute(
    String planId, {
    String? message,
    PromiseReward? reward,
    PromisePenalty? penalty,
  }) async {
    await _repository.pokePartner(planId, message: message);
    if (reward != null || penalty != null) {
      await _repository.proposePromise(
        planId,
        reward: reward,
        penalty: penalty,
      );
    }
  }
}
