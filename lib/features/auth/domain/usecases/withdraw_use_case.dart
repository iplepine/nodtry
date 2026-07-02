import '../../../../repositories/record_repository.dart';
import '../../../../repositories/connect_repository.dart';
import '../../../../services/auth_service.dart';
import '../../../../repositories/user_repository.dart';
import '../../../../datasources/user_local_data_source.dart';
import '../../../../usecases/cancel_all_notifications_use_case.dart';
import '../../../../utils/analytics.dart';

class WithdrawUseCase {
  final AuthService _authService;
  final UserRepository _userRepository;
  final UserLocalDataSource _userLocalDataSource;
  final RecordRepository _recordRepository;
  final ConnectRepository _connectRepository;
  final CancelAllNotificationsUseCase _cancelAllNotificationsUseCase;

  WithdrawUseCase(
    this._authService,
    this._userRepository,
    this._userLocalDataSource,
    this._recordRepository,
    this._connectRepository,
    this._cancelAllNotificationsUseCase,
  );

  Future<void> execute() async {
    final user = _authService.currentUser;
    if (user != null) {
      // 0. 모든 알림 제거
      await _cancelAllNotificationsUseCase.execute();

      // 1. 연관 데이터 삭제 (Cascade)
      // plans, relations 삭제
      await _recordRepository.deletePlansByUserId(user.uid);
      await _connectRepository.deleteAllRelationsByUserId(user.uid);

      // 1. 데이터 삭제 (Firestore)
      await _userRepository.deleteUser(user.uid);
      // 2. 로컬 데이터 삭제
      await _userLocalDataSource.clearUser();
      // 3. 계정 삭제 (Auth)
      AnalyticsService.log(AnalyticsEvent.accountDeleted);
      await _authService.deleteAccount();
    }
  }
}
