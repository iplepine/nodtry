import '../../../../repositories/record_repository.dart';

class PokePartnerUseCase {
  final RecordRepository _repository;

  PokePartnerUseCase(this._repository);

  /// 파트너 찌르기 (똑똑)
  Future<void> execute(String planId, {String? message}) {
    return _repository.pokePartner(planId, message: message);
  }
}
