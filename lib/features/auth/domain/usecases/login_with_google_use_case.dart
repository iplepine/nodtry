import 'package:firebase_auth/firebase_auth.dart';
import '../../../../repositories/user_repository.dart';
import '../../../../services/auth_service.dart';

class LoginWithGoogleUseCase {
  final AuthService _authService;
  final UserRepository _userRepository;

  LoginWithGoogleUseCase(this._authService, this._userRepository);

  Future<UserCredential?> execute() async {
    final credential = await _authService.signInWithGoogle();
    if (credential != null && credential.user != null) {
      // 로그인 성공 시 유저 정보 초기화/동기화
      await _userRepository.initializeUser(credential.user!);
    }
    return credential;
  }
}
