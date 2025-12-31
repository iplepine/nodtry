import '../models/home_state.dart';
import '../repositories/record_repository.dart';

class GetNowCardsUseCase {
  final RecordRepository _recordRepository;

  GetNowCardsUseCase(this._recordRepository);

  Future<List<HomeCardModel>> execute() {
    return _recordRepository.getHomeCardStates();
  }
}
