import 'package:flutter/foundation.dart';
import '../../../../models/user_model.dart';
import '../../../../services/auth_service.dart';
import '../../../../repositories/user_repository.dart';
import '../../../../datasources/user_local_data_source.dart';

class AutoLoginUseCase {
  final AuthService _authService;
  final UserRepository _userRepository;
  final UserLocalDataSource _userLocalDataSource;

  AutoLoginUseCase(
    this._authService,
    this._userRepository,
    this._userLocalDataSource,
  );

  Future<UserModel?> execute() async {
    final user = _authService.currentUser;
    if (user == null) {
      return null;
    }

    try {
      // 1. 유저 존재 여부 확인 (10초 타임아웃 추가)
      var userModel = await _userRepository.getMyProfile().timeout(
        const Duration(seconds: 10),
      );

      if (userModel == null) {
        // Auth에는 있지만 DB에 없는 경우 -> 서버에서 삭제된 계정으로 간주
        debugPrint(
          '[AutoLoginUseCase] User not found in Firestore. Clearing local data...',
        );
        await _userLocalDataSource.clearUser();
        await _authService.signOut();
        return null;
      }

      // 2. 데이터 동기화 및 백필 (InviteCode 등)
      //    이미 존재하는 유저임이 확인되었으므로 안심하고 업데이트 수행
      await _userRepository
          .initializeUser(user)
          .timeout(const Duration(seconds: 10));

      // 3. 최신 데이터 다시 조회 (동기화된 필드 반영)
      userModel = await _userRepository.getMyProfile().timeout(
        const Duration(seconds: 5),
      );

      if (userModel != null) {
        // 4. 로컬 캐시 갱신
        await _userLocalDataSource.saveUser(userModel);
      }

      return userModel;
    } catch (e) {
      debugPrint('[AutoLoginUseCase] Error during auto-login check: $e');
      // 타임아웃이나 다른 에러 발생 시 로그아웃 처리하여 무한 로딩 방지
      if (!user.isAnonymous) {
        await _authService.signOut();
      }
      return null; // 에러 발생 시 null 반환하여 호출 측에서 로딩 상태를 해제하게 함
    }
  }
}
