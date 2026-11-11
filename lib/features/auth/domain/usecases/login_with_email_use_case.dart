import '../../../../repositories/user_repository.dart';
import '../../../../services/auth_service.dart';
import '../auth_login_result.dart';

class LoginWithEmailUseCase {
  final AuthService _authService;
  final UserRepository _userRepository;

  LoginWithEmailUseCase(this._authService, this._userRepository);

  Future<AuthLoginResult> execute(String email, String password) async {
    final credential = await _authService.signInWithEmailAndPassword(
      email,
      password,
    );

    final user = credential.user;
    if (user == null) throw StateError('Email sign-in returned no user');
    return completeAuthenticatedLogin(
      () => _userRepository.initializeUser(user),
      cleanUpSession: () => _authService.signOutIfCurrentUser(user.uid),
    );
  }
}
