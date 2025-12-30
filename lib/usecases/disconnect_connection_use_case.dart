import '../repositories/connect_repository.dart';

class DisconnectConnectionUseCase {
  final ConnectRepository _repository;

  DisconnectConnectionUseCase(this._repository);

  Future<void> execute(String targetUserId) {
    return _repository.disconnectByUser(targetUserId);
  }
}
