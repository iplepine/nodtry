import '../../../../repositories/user_repository.dart';
import '../../../../services/auth_service.dart';
import '../auth_login_result.dart';

class SignUpWithEmailUseCase {
  final AuthService _authService;
  final UserRepository _userRepository;
  String? _pendingUserUid;

  SignUpWithEmailUseCase(this._authService, this._userRepository);

  Future<AuthLoginResult> execute(String email, String password) async {
    // Profile setup can fail after Firebase Auth has already created the
    // account. Reuse that same session when the user taps Sign up again.
    var user = _authService.currentUser;
    final isSamePendingAccount =
        _pendingUserUid != null &&
        user?.uid == _pendingUserUid &&
        user?.email?.toLowerCase() == email.trim().toLowerCase();
    if (!isSamePendingAccount) {
      _pendingUserUid = null;
      final credential = await _authService.signUpWithEmailAndPassword(
        email,
        password,
      );
      user = credential.user;
      _pendingUserUid = user?.uid;
    }

    final authenticatedUser = user;
    if (authenticatedUser == null) {
      throw StateError('Email sign-up returned no user');
    }
    final result = await completeAuthenticatedLogin(
      () => _userRepository.initializeUser(authenticatedUser),
    );
    if (result.outcome == AuthLoginOutcome.success) {
      _pendingUserUid = null;
    }
    return result;
  }
}
