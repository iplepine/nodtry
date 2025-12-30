import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../repositories/user_repository.dart';

class LinkWithGoogleUseCase {
  final AuthService _authService;
  final UserRepository _userRepository;

  LinkWithGoogleUseCase(this._authService, this._userRepository);

  Future<UserCredential?> execute() async {
    // 1. 구글 계정 연결
    final credential = await _authService.linkWithGoogle();

    // 2. 연결 성공 시 사용자 정보 업데이트
    if (credential?.user != null) {
      await _userRepository.initializeUser(credential!.user!);
    }

    return credential;
  }
}
