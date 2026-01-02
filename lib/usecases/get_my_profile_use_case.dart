import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../datasources/user_local_data_source.dart';

class GetMyProfileUseCase {
  final UserRepository _userRepository;
  final UserLocalDataSource _userLocalDataSource;

  GetMyProfileUseCase(this._userRepository, this._userLocalDataSource);

  Stream<UserModel?> execute() async* {
    // 1. 캐시된 데이터 먼저 방출 (빠른 UI 응답)
    final cachedUser = _userLocalDataSource.getUser();
    if (cachedUser != null) {
      yield cachedUser;
    }

    // 2. Repository의 실시간 스트림(watchMyProfile) 연결
    //    데이터가 올 때마다 캐시도 갱신
    yield* _userRepository.watchMyProfile().map((user) {
      if (user != null) {
        // 비동기로 캐시 업데이트 (await 안함)
        // Fire-and-forget 방식으로 처리하거나, 동기화를 보장하고 싶으면 asyncMap을 써야 함.
        // 여기선 단순 캐싱 목적이므로 비동기 호출만 함.
        _userLocalDataSource.saveUser(user);
      }
      return user;
    });
  }

  Future<UserModel?> getCachedProfile() async {
    return _userLocalDataSource.getUser();
  }
}
