import 'package:firebase_auth/firebase_auth.dart';
import '../../../../repositories/user_repository.dart';
import '../../../../services/auth_service.dart';

class LinkWithGoogleUseCase {
  final AuthService _authService;
  final UserRepository _userRepository;

  LinkWithGoogleUseCase(this._authService, this._userRepository);

  Future<UserCredential?> execute() async {
    final credential = await _authService.linkWithGoogle();
    if (credential != null && credential.user != null) {
      // 링크 성공 시 유저 정보(특히 loginType) 동기화
      await _userRepository.initializeUser(credential.user!);
    }
    return credential;
  }
}
