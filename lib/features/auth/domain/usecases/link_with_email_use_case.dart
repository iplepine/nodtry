import 'package:firebase_auth/firebase_auth.dart';
import '../../../../repositories/user_repository.dart';
import '../../../../services/auth_service.dart';

class LinkWithEmailUseCase {
  final AuthService _authService;
  final UserRepository _userRepository;

  LinkWithEmailUseCase(this._authService, this._userRepository);

  Future<UserCredential?> execute(String email, String password) async {
    final credential = await _authService.linkWithEmailAndPassword(
      email,
      password,
    );
    if (credential != null && credential.user != null) {
      // 링크 성공 시 유저 정보 동기화 (특히 loginType 등 메타데이터 업데이트 필요 시)
      await _userRepository.initializeUser(credential.user!);
    }
    return credential;
  }
}
