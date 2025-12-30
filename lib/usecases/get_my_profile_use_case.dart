import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../datasources/user_local_data_source.dart';

class GetMyProfileUseCase {
  final UserRepository _userRepository;
  final UserLocalDataSource _userLocalDataSource;

  GetMyProfileUseCase(this._userRepository, this._userLocalDataSource);

  Stream<UserModel?> execute() async* {
    // 1. 로컬 캐시 확인 및 즉시 반환 (Fast Check)
    final cachedUser = _userLocalDataSource.getUser();
    if (cachedUser != null) {
      yield cachedUser;
    }

    // 2. 서버 데이터 확인 (Back-end Check)
    try {
      final remoteUser = await _userRepository.getMyProfile();

      if (remoteUser != null) {
        // 서버에 데이터가 존재하면 로컬 캐시 갱신
        await _userLocalDataSource.saveUser(remoteUser);
        yield remoteUser;
      } else {
        // 캐시에는 있었으나 서버에는 없는 경우 (삭제된 계정 등) -> 캐시 삭제
        if (cachedUser != null) {
          await _userLocalDataSource.clearUser();
          yield null; // 로그아웃 처리 유도
        } else {
          // 캐시도 없고 서버도 없음
          yield null;
        }
      }
    } catch (e) {
      // 네트워크 에러 등으로 서버 조회 실패 시, 캐시가 있었으면 그 상태 유지
      // 에러를 던져야 할까? UI에서 스낵바 등을 띄우려면 rethrow 하거나 Error 상태 yield
      // 일단은 캐시 데이터만으로 유지
      if (cachedUser == null) {
        // 캐시도 없고 에러남 -> 에러 전파??
        // Stream 에러 처리는 복잡하므로 여기선 로그 남기고 종료
        // yield* Stream.error(e);
        yield null;
      }
      // 캐시가 있으면 아무것도 안함 (캐시된 데이터가 최신이라 믿음)
    }
  }
}
