import '../models/user_model.dart';
import '../repositories/user_repository.dart';

class GetMyProfileUseCase {
  final UserRepository _userRepository;

  GetMyProfileUseCase(this._userRepository);

  Future<UserModel?> execute() {
    return _userRepository.getMyProfile();
  }
}
