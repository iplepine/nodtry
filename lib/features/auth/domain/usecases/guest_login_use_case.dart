import 'package:firebase_auth/firebase_auth.dart';

import '../../../../repositories/user_repository.dart';
import '../../../../services/auth_service.dart';
import '../../../../datasources/user_local_data_source.dart';
import '../auth_login_result.dart';

class GuestLoginUseCase {
  final AuthService _authService;
  final UserRepository _userRepository;
  final UserLocalDataSource _userLocalDataSource;

  GuestLoginUseCase(
    this._authService,
    this._userRepository,
    this._userLocalDataSource,
  );

  Future<AuthLoginResult> execute() async {
    // 1. 이미 익명 로그인 상태인지 확인
    final currentUser = _authService.currentUser;
    if (currentUser != null && currentUser.isAnonymous) {
      return completeAuthenticatedLogin(() => _initializeAndCache(currentUser));
    }

    // 1. 익명 로그인
    final userCredential = await _authService.signInAnonymously();

    final user = userCredential.user;
    if (user == null) throw StateError('Anonymous sign-in returned no user');
    return completeAuthenticatedLogin(() => _initializeAndCache(user));
  }

  Future<void> _initializeAndCache(User user) async {
    // 2. 사용자 문서 초기화 (없으면 생성)
    await _userRepository.initializeUser(user);

    // 3. 초기화된 유저 정보 가져와서 캐싱
    final userModel = await _userRepository.getMyProfile();
    if (userModel != null) {
      await _userLocalDataSource.saveUser(userModel);
    }
  }
}
