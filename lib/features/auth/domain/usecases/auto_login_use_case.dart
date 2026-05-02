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

        // 5. 서버 상태 정리 후 알림 복구
        await _syncPlansAndNotifications(user.uid);
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

  /// 앱 시작 시 서버 플랜 상태를 먼저 정리하고, 정리된 서버값 기준으로 로컬 알림을 재구성
  Future<void> _syncPlansAndNotifications(String userId) async {
    try {
      final completedPlanIds = await _recordRepository
          .completeOverduePlans()
          .timeout(const Duration(seconds: 10));

      for (final planId in completedPlanIds) {
        await _settingAlarmUseCase.cancelById(planId);
      }

      debugPrint(
        '[AutoLoginUseCase] Startup plan sync complete. ${completedPlanIds.length} plans completed.',
      );
    } catch (e) {
      debugPrint('[AutoLoginUseCase] Failed to sync overdue plans: $e');
      // 서버 정리에 실패해도 알림 복구는 시도한다. 오프라인/타임아웃 상황에서 앱 진입을 막지 않기 위함.
    }

    await _restoreNotifications(userId);
  }

  /// 서버에 저장된 알림 설정을 기반으로 로컬 알림을 복구
  Future<void> _restoreNotifications(String userId) async {
    try {
      final plans = await _recordRepository.getPlansByUserId(userId);
      final restorablePlans = plans.where((plan) {
        final item = plan.items.firstOrNull;
        final notificationTime = item?.notificationTime;
        return item != null &&
            notificationTime != null &&
            notificationTime.type != 'none';
      }).toList();

      // 1. 복구 가능한 플랜을 확인한 뒤에만 기존 로컬 알림을 정리한다.
      await _cancelAllNotificationsUseCase.execute();

      // 2. 저장된 알림 설정이 살아 있는 플랜만 재등록한다.
      for (final plan in restorablePlans) {
        final item = plan.items.first;
        await _settingAlarmUseCase.execute(plan);
        debugPrint(
          '[AutoLoginUseCase] Restored notification for plan: ${item.title}',
        );
      }

      debugPrint(
        '[AutoLoginUseCase] Notification restore complete. ${restorablePlans.length} plans restored from ${plans.length} plans.',
      );
    } catch (e) {
      debugPrint('[AutoLoginUseCase] Failed to restore notifications: $e');
      // 알림 복구 실패해도 로그인 자체는 차단하지 않음
    }
  }
}
