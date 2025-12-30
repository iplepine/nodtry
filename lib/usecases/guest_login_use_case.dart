import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';
import '../datasources/user_local_data_source.dart';

class GuestLoginUseCase {
  final AuthService _authService;
  final UserRepository _userRepository;
  final UserLocalDataSource _userLocalDataSource;

  GuestLoginUseCase(
    this._authService,
    this._userRepository,
    this._userLocalDataSource,
  );

  Future<UserCredential> execute() async {
    // 1. 익명 로그인
    final userCredential = await _authService.signInAnonymously();

    // 2. 사용자 문서 초기화 (없으면 생성)
    if (userCredential.user != null) {
      await _userRepository.initializeUser(userCredential.user!);

      // 3. 초기화된 유저 정보 가져와서 캐싱
      final user = await _userRepository.getMyProfile();
      if (user != null) {
        await _userLocalDataSource.saveUser(user);
      }
    }

    return userCredential;
  }
}
