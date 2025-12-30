import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';

class GuestLoginUseCase {
  final AuthService _authService;
  final UserRepository _userRepository;

  GuestLoginUseCase(this._authService, this._userRepository);

  Future<UserCredential> execute() async {
    // 1. 익명 로그인
    final userCredential = await _authService.signInAnonymously();

    // 2. 사용자 문서 초기화 (없으면 생성)
    if (userCredential.user != null) {
      await _userRepository.initializeUser(userCredential.user!);
    }

    return userCredential;
  }
}
