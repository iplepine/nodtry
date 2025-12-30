import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../repositories/user_repository.dart';

class LoginWithGoogleUseCase {
  final AuthService _authService;
  final UserRepository _userRepository;

  LoginWithGoogleUseCase(this._authService, this._userRepository);

  Future<UserCredential?> execute() async {
    // 1. 구글 로그인 시도
    final credential = await _authService.signInWithGoogle();

    // 2. 로그인 성공 시 사용자 정보 초기화/동기화
    if (credential?.user != null) {
      // UserRepository를 통해 Firestore에 사용자 정보 저장/업데이트
      await _userRepository.initializeUser(credential!.user!);
    }

    return credential;
  }
}
