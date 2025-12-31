import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../repositories/user_repository.dart';
import '../datasources/user_local_data_source.dart';

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
      // 1. 유저 존재 여부 확인
      //    (삭제된 계정인지 확인하기 위함)
      var userModel = await _userRepository.getMyProfile();

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
      await _userRepository.initializeUser(user);

      // 3. 최신 데이터 다시 조회 (동기화된 필드 반영)
      //    initializeUser는 반환값이 없으므로 다시 조회해야 함
      userModel = await _userRepository.getMyProfile();

      if (userModel != null) {
        // 4. 로컬 캐시 갱신
        await _userLocalDataSource.saveUser(userModel);
      }

      return userModel;
    } catch (e) {
      debugPrint('[AutoLoginUseCase] Error checking user: $e');
      if (user.isAnonymous) {
        debugPrint(
          "AutoLogin failed due to error ($e), but keeping Guest session.",
        );
      } else {
        await _authService.signOut();
      }
      rethrow;
    }
  }
}
