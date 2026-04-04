import 'package:firebase_auth/firebase_auth.dart';
import '../../../../repositories/user_repository.dart';
import '../../../../services/auth_service.dart';

class LoginWithEmailUseCase {
  final AuthService _authService;
  final UserRepository _userRepository;

  LoginWithEmailUseCase(this._authService, this._userRepository);

  Future<UserCredential?> execute(String email, String password) async {
    final credential = await _authService.signInWithEmailAndPassword(
      email,
      password,
    );
    
    if (credential.user != null) {
      // 로그인 성공 시 유저 정보 초기화/동기화 (Firestore)
      await _userRepository.initializeUser(credential.user!);
    }
    
    return credential;
  }
}
