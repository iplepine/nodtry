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

  /// 자동 로그인 시도
  /// 로그인 성공 시 UserModel 반환, 실패 하거나 타임아웃 시 Exception/null
  Future<UserModel?> execute() async {
    final user = _authService.currentUser;
    if (user == null) {
      return null;
    }

    try {
      // 1. Firestore에서 유저 정보 직접 확인 (단발성)
      final userModel = await _userRepository.getMyProfile();

      if (userModel == null) {
        // Auth에는 있지만 DB에 없는 경우 -> 서버에서 삭제된 계정으로 간주
        debugPrint(
          '[AutoLoginUseCase] User not found in Firestore. Clearing local data...',
        );
        await _userLocalDataSource.clearUser();
        await _authService.signOut();
        return null;
      }

      // 2. 유저 정보가 있으면 로컬 캐시 갱신 및 반환
      await _userLocalDataSource.saveUser(userModel);
      return userModel;
    } catch (e) {
      debugPrint('[AutoLoginUseCase] Error checking user: $e');
      // 네트워크 에러 등은 일단 패스하고, 로컬 캐시라도 있으면 반환?
      // 아니면 재시도 유도. 여기선 에러 시 로그아웃 보단 null 반환이 안전할수도.
      // 기존 로직 유지: 에러 시 익명이면 세션 유지, 아니면 로그아웃
      if (user.isAnonymous) {
        debugPrint(
          "AutoLogin failed due to error ($e), but keeping Guest session.",
        );
      } else {
        // 일반 유저(구글 등)는 로그아웃 하여 재로그인 유도
        await _authService.signOut();
      }
      rethrow;
    }
  }
}
