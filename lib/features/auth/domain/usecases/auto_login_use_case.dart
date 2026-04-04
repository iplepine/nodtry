import 'package:flutter/foundation.dart';
import '../../../../models/user_model.dart';
import '../../../../services/auth_service.dart';
import '../../../../repositories/user_repository.dart';
import '../../../../repositories/record_repository.dart';
import '../../../../datasources/user_local_data_source.dart';
import '../../../../usecases/cancel_all_notifications_use_case.dart';
import '../../../plan/domain/usecases/setting_alarm_use_case.dart';

class AutoLoginUseCase {
  final AuthService _authService;
  final UserRepository _userRepository;
  final UserLocalDataSource _userLocalDataSource;
  final CancelAllNotificationsUseCase _cancelAllNotificationsUseCase;
  final RecordRepository _recordRepository;
  final SettingAlarmUseCase _settingAlarmUseCase;

  AutoLoginUseCase(
    this._authService,
    this._userRepository,
    this._userLocalDataSource,
    this._cancelAllNotificationsUseCase,
    this._recordRepository,
    this._settingAlarmUseCase,
  );

  Future<UserModel?> execute() async {
    final user = _authService.currentUser;
    if (user == null) {
      return null;
    }

    try {
      // 1. 유저 존재 여부 확인 (10초 타임아웃 추가)
      var userModel = await _userRepository.getMyProfile().timeout(
        const Duration(seconds: 10),
      );

      if (userModel == null) {
        // Auth에는 있지만 DB에 없는 경우 -> 서버에서 삭제된 계정으로 간주
        debugPrint(
          '[AutoLoginUseCase] User not found in Firestore. Clearing local data...',
        );
        await _cancelAllNotificationsUseCase.execute();
        await _userLocalDataSource.clearUser();
        await _authService.signOut();
        return null;
      }

      // 2. 데이터 동기화 및 백필 (InviteCode 등)
      //    이미 존재하는 유저임이 확인되었으므로 안심하고 업데이트 수행
      await _userRepository
          .initializeUser(user)
          .timeout(const Duration(seconds: 10));

      // 3. 최신 데이터 다시 조회 (동기화된 필드 반영)
      userModel = await _userRepository.getMyProfile().timeout(
        const Duration(seconds: 5),
      );

      if (userModel != null) {
        // 4. 로컬 캐시 갱신
        await _userLocalDataSource.saveUser(userModel);

        // 5. 알림 복구: 기존 로컬 알림 전부 취소 후, 서버 설정 기반 재등록
        await _restoreNotifications(user.uid);
      }

      return userModel;
    } catch (e) {
      debugPrint('[AutoLoginUseCase] Error during auto-login check: $e');
      // 타임아웃이나 다른 에러 발생 시 로그아웃 처리하여 무한 로딩 방지
      if (!user.isAnonymous) {
        await _cancelAllNotificationsUseCase.execute();
        await _authService.signOut();
      }
      return null; // 에러 발생 시 null 반환하여 호출 측에서 로딩 상태를 해제하게 함
    }
  }

  /// 서버에 저장된 알림 설정을 기반으로 로컬 알림을 복구
  Future<void> _restoreNotifications(String userId) async {
    try {
      // 1. 기존 로컬 알림 전부 취소 (중복 방지)
      await _cancelAllNotificationsUseCase.execute();

      // 2. Firestore에서 플랜 목록 조회
      final plans = await _recordRepository.getPlansByUserId(userId);

      // 3. 알림이 ON인 플랜만 재등록
      for (final plan in plans) {
        final item = plan.items.firstOrNull;
        if (item == null) continue;

        final notificationTime = item.notificationTime;
        if (notificationTime != null && notificationTime.type != 'none') {
          await _settingAlarmUseCase.execute(plan);
          debugPrint('[AutoLoginUseCase] Restored notification for plan: ${item.title}');
        }
      }

      debugPrint('[AutoLoginUseCase] Notification restore complete. ${plans.length} plans checked.');
    } catch (e) {
      debugPrint('[AutoLoginUseCase] Failed to restore notifications: $e');
      // 알림 복구 실패해도 로그인 자체는 차단하지 않음
    }
  }
}
