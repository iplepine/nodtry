import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../datasources/user_local_data_source.dart';

class GetMyProfileUseCase {
  final UserRepository _userRepository;
  final UserLocalDataSource _userLocalDataSource;

  GetMyProfileUseCase(this._userRepository, this._userLocalDataSource);

  Future<UserModel?> execute() async {
    // 1. 로컬 캐시 확인
    final cachedUser = _userLocalDataSource.getUser();
    if (cachedUser != null) {
      return cachedUser;
    }

    // 2. 캐시 없으면 서버 요청
    final remoteUser = await _userRepository.getMyProfile();

    // 3. 서버 데이터 로컬 저장
    if (remoteUser != null) {
      await _userLocalDataSource.saveUser(remoteUser);
    }

    return remoteUser;
  }
}
