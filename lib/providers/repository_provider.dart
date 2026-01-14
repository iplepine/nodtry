import '../features/plan/domain/usecases/create_new_plan_use_case.dart';
import '../features/plan/domain/usecases/setting_alarm_use_case.dart';
import '../usecases/set_alarm_use_case.dart';
import '../usecases/show_instant_notification_use_case.dart';
import '../usecases/cancel_all_notifications_use_case.dart';
import '../services/notification_service.dart' as local_notifications;
import '../features/now/domain/usecases/get_now_cards_use_case.dart';
import '../features/history/domain/usecases/get_history_use_case.dart';
import '../features/plan/domain/usecases/get_plan_history_use_case.dart';
import '../models/plan_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/record_repository.dart';
import '../repositories/mock_record_repository.dart';
import '../repositories/real_record_repository.dart';
import '../repositories/connect_repository.dart';
import '../repositories/mock_connect_repository.dart';
import '../repositories/real_connect_repository.dart';
import '../models/user_model.dart';
import '../models/connected_user.dart';
import '../repositories/user_repository.dart';
import '../repositories/mock_user_repository.dart';
import '../repositories/real_user_repository.dart';
import '../usecases/update_profile_use_case.dart';
import '../features/auth/domain/usecases/auto_login_use_case.dart';
import '../features/auth/domain/usecases/link_with_google_use_case.dart';
import '../features/auth/domain/usecases/link_with_email_use_case.dart';
import '../features/auth/domain/usecases/sign_up_with_email_use_case.dart';
import '../features/auth/domain/usecases/login_with_google_use_case.dart';
import '../features/auth/domain/usecases/withdraw_use_case.dart';

import '../features/auth/domain/usecases/guest_login_use_case.dart';
import '../usecases/get_my_profile_use_case.dart';
import '../usecases/get_connected_profiles_use_case.dart';
import '../usecases/disconnect_connection_use_case.dart';
import '../services/auth_service.dart';
import '../datasources/user_local_data_source.dart';

// ... (ConnectRepository related imports and providers kept below)

/// SharedPreferences Provider (Main에서 Override 필요)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

/// UserLocalDataSource Provider
final userLocalDataSourceProvider = Provider<UserLocalDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserLocalDataSource(prefs);
});

/// AuthService Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// UserRepository Provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final typeAsync = ref.watch(repositoryTypeProvider);
  // 로딩 중이거나 에러 발생 시 기본값(Real) 사용 - 운영 환경 안전성 확보
  final type = typeAsync.asData?.value ?? RepositoryType.real;

  if (type == RepositoryType.real) {
    return RealUserRepository();
  }
  return MockUserRepository();
});

/// GetMyProfileUseCase Provider
final getMyProfileUseCaseProvider = Provider<GetMyProfileUseCase>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  final userLocalDataSource = ref.watch(userLocalDataSourceProvider);
  return GetMyProfileUseCase(repository, userLocalDataSource);
});

/// My Profile Provider (Stream)
final myProfileProvider = StreamProvider<UserModel?>((ref) {
  // 인증 상태 변화를 감시하여 상태 변경 시 스트림 재구성
  ref.watch(authStateChangesProvider);

  final useCase = ref.watch(getMyProfileUseCaseProvider);
  return useCase.execute();
});

/// 인증 상태 스트림 프로바이더
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// GuestLoginUseCase Provider
final guestLoginUseCaseProvider = Provider<GuestLoginUseCase>((ref) {
  final authService = ref.watch(authServiceProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  final userLocalDataSource = ref.watch(userLocalDataSourceProvider);
  return GuestLoginUseCase(authService, userRepository, userLocalDataSource);
});

/// UpdateProfileUseCase Provider
final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  final userLocalDataSource = ref.watch(userLocalDataSourceProvider);
  return UpdateProfileUseCase(repository, userLocalDataSource);
});

/// 현재 사용할 Repository 타입
enum RepositoryType { mock, real }

final getConnectedProfilesUseCaseProvider =
    Provider<GetConnectedProfilesUseCase>((ref) {
      return GetConnectedProfilesUseCase(
        ref.watch(connectRepositoryProvider),
        ref.watch(userRepositoryProvider),
        ref.watch(authServiceProvider),
      );
    });

/// 연결된 프로필 목록 Provider (Future)
final connectedProfilesProvider = FutureProvider<List<ConnectedUser>>((ref) {
  // 연결 상태 변화를 감시하여 상태 변경 시 데이터 재조회
  ref.watch(connectionStatusStreamProvider);

  final useCase = ref.watch(getConnectedProfilesUseCaseProvider);
  return useCase.execute();
});

/// Repository 타입 상태 관리 Provider
class RepositoryTypeNotifier extends AsyncNotifier<RepositoryType> {
  static const _key = 'repository_type';

  @override
  Future<RepositoryType> build() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    // 개발 모드에서 명시적으로 'mock'으로 설정한 경우에만 Mock 사용
    if (value == 'mock') {
      return RepositoryType.mock;
    }
    // 기본값은 Real (배포 시 안전을 위해)
    return RepositoryType.real;
  }

  Future<void> setType(RepositoryType type) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        type == RepositoryType.real ? 'real' : 'mock',
      );
      return type;
    });
  }
}

/// Repository 타입 상태 관리 Provider
final repositoryTypeProvider =
    AsyncNotifierProvider<RepositoryTypeNotifier, RepositoryType>(() {
      return RepositoryTypeNotifier();
    });

/// RecordRepository Provider
final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  final typeAsync = ref.watch(repositoryTypeProvider);
  // 기본값 Real
  final type = typeAsync.asData?.value ?? RepositoryType.real;

  if (type == RepositoryType.real) {
    return RealRecordRepository();
  }
  return MockRecordRepository();
});

/// ConnectRepository Provider
final connectRepositoryProvider = Provider<ConnectRepository>((ref) {
  final typeAsync = ref.watch(repositoryTypeProvider);
  // 기본값 Real
  final type = typeAsync.asData?.value ?? RepositoryType.real;

  if (type == RepositoryType.real) {
    return RealConnectRepository();
  }
  return MockConnectRepository();
});

/// Mock Repository 제어용 Provider (타입 캐스팅 편의)
final mockRecordRepositoryProvider = Provider<MockRecordRepository?>((ref) {
  final repository = ref.watch(recordRepositoryProvider);
  if (repository is MockRecordRepository) {
    return repository;
  }
  return null;
});

/// 연결 상태 스트림 Provider
final connectionStatusStreamProvider = StreamProvider<ConnectionStatus>((ref) {
  final repository = ref.watch(connectRepositoryProvider);
  return repository.watchConnectionStatus();
});

final disconnectConnectionUseCaseProvider =
    Provider<DisconnectConnectionUseCase>((ref) {
      final repository = ref.watch(connectRepositoryProvider);
      return DisconnectConnectionUseCase(repository);
    });

final createNewPlanUseCaseProvider = Provider<CreateNewPlanUseCase>((ref) {
  final repository = ref.watch(recordRepositoryProvider);
  return CreateNewPlanUseCase(repository);
});
final autoLoginUseCaseProvider = Provider<AutoLoginUseCase>((ref) {
  final authService = ref.watch(authServiceProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  final userLocalDataSource = ref.watch(userLocalDataSourceProvider);
  return AutoLoginUseCase(authService, userRepository, userLocalDataSource);
});

final linkWithGoogleUseCaseProvider = Provider<LinkWithGoogleUseCase>((ref) {
  final authService = ref.watch(authServiceProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  return LinkWithGoogleUseCase(authService, userRepository);
});

final linkWithEmailUseCaseProvider = Provider<LinkWithEmailUseCase>((ref) {
  final authService = ref.watch(authServiceProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  return LinkWithEmailUseCase(authService, userRepository);
});

final signUpWithEmailUseCaseProvider = Provider<SignUpWithEmailUseCase>((ref) {
  final authService = ref.watch(authServiceProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  return SignUpWithEmailUseCase(authService, userRepository);
});

final loginWithGoogleUseCaseProvider = Provider<LoginWithGoogleUseCase>((ref) {
  final authService = ref.watch(authServiceProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  return LoginWithGoogleUseCase(authService, userRepository);
});

final withdrawUseCaseProvider = Provider<WithdrawUseCase>((ref) {
  final authService = ref.watch(authServiceProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  final localDataSource = ref.watch(userLocalDataSourceProvider);
  final recordRepository = ref.watch(recordRepositoryProvider);
  final connectRepository = ref.watch(connectRepositoryProvider);
  return WithdrawUseCase(
    authService,
    userRepository,
    localDataSource,
    recordRepository,
    connectRepository,
  );
});

final setAlarmUseCaseProvider = Provider<SetAlarmUseCase>((ref) {
  return SetAlarmUseCase(local_notifications.NotificationService());
});

final showInstantNotificationUseCaseProvider =
    Provider<ShowInstantNotificationUseCase>((ref) {
      return ShowInstantNotificationUseCase(
        local_notifications.NotificationService(),
      );
    });

final cancelAllNotificationsUseCaseProvider =
    Provider<CancelAllNotificationsUseCase>((ref) {
      return CancelAllNotificationsUseCase(
        local_notifications.NotificationService(),
      );
    });

final settingAlarmUseCaseProvider = Provider<SettingAlarmUseCase>((ref) {
  return SettingAlarmUseCase(local_notifications.NotificationService());
});

final getNowCardsUseCaseProvider = Provider<GetNowCardsUseCase>((ref) {
  return GetNowCardsUseCase(ref.watch(recordRepositoryProvider));
});

final getHistoryUseCaseProvider = Provider<GetHistoryUseCase>((ref) {
  return GetHistoryUseCase(ref.watch(recordRepositoryProvider));
});

final getPlanHistoryUseCaseProvider = Provider<GetPlanHistoryUseCase>((ref) {
  return GetPlanHistoryUseCase(ref.watch(recordRepositoryProvider));
});

final getPlansByUserIdStreamProvider =
    StreamProvider.family<List<Plan>, String>((ref, userId) {
      final repository = ref.watch(recordRepositoryProvider);
      return repository.getPlansByUserIdStream(userId);
    });
