import '../../services/auth_service.dart';
import '../../repositories/user_repository.dart';
import '../../datasources/user_local_data_source.dart';

class WithdrawUseCase {
  final AuthService _authService;
  final UserRepository _userRepository;
  final UserLocalDataSource _userLocalDataSource;

  WithdrawUseCase(
    this._authService,
    this._userRepository,
    this._userLocalDataSource,
  );

  Future<void> execute() async {
    final user = _authService.currentUser;
    if (user != null) {
      // 1. 데이터 삭제 (Firestore)
      await _userRepository.deleteUser(user.uid);
      // 2. 로컬 데이터 삭제
      await _userLocalDataSource.clearUser();
      // 3. 계정 삭제 (Auth)
      await _authService.deleteAccount();
    }
  }
}
