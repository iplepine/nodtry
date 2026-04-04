import 'package:firebase_auth/firebase_auth.dart';
import '../../../../repositories/user_repository.dart';
import '../../../../services/auth_service.dart';

class LoginWithAppleUseCase {
  final AuthService _authService;
  final UserRepository _userRepository;

  LoginWithAppleUseCase(this._authService, this._userRepository);

  Future<UserCredential?> execute() async {
    final credential = await _authService.signInWithApple();
    if (credential != null && credential.user != null) {
      await _userRepository.initializeUser(credential.user!);
    }
    return credential;
  }
}
