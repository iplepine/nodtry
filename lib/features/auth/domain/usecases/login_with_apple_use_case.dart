import '../../../../repositories/user_repository.dart';
import '../../../../services/auth_service.dart';
import '../auth_login_result.dart';

class LoginWithAppleUseCase {
  final AuthService _authService;
  final UserRepository _userRepository;

  LoginWithAppleUseCase(this._authService, this._userRepository);

  Future<AuthLoginResult> execute() async {
    final credential = await _authService.signInWithApple();
    if (credential == null) return const AuthLoginResult.cancelled();
    final user = credential.user;
    if (user == null) throw StateError('Apple sign-in returned no user');
    return completeAuthenticatedLogin(
      () => _userRepository.initializeUser(user),
      cleanUpSession: () => _authService.signOutIfCurrentUser(user.uid),
    );
  }
}
