import 'package:firebase_auth/firebase_auth.dart';
import '../../../../repositories/user_repository.dart';
import '../../../../services/auth_service.dart';

class SignUpWithEmailUseCase {
  final AuthService _authService;
  final UserRepository _userRepository;

  SignUpWithEmailUseCase(this._authService, this._userRepository);

  Future<UserCredential> execute(String email, String password) async {
    // 1. Firebase Auth 회원가입
    final credential = await _authService.signUpWithEmailAndPassword(
      email,
      password,
    );

    // 2. User 데이터 초기화 (Firestore 등)
    if (credential.user != null) {
      await _userRepository.initializeUser(credential.user!);
    }

    return credential;
  }
}
