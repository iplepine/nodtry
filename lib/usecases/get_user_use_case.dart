import '../models/user_model.dart';
import '../repositories/user_repository.dart';

class GetUserUseCase {
  final UserRepository _userRepository;

  GetUserUseCase(this._userRepository);

  Future<UserModel?> execute() {
    return _userRepository.getMyProfile();
  }
}
