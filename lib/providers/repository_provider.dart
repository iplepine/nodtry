import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/record_repository.dart';
import '../repositories/mock_record_repository.dart';
import '../repositories/real_record_repository.dart';
import '../repositories/connect_repository.dart';
import '../repositories/mock_connect_repository.dart';
import '../repositories/real_connect_repository.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../repositories/mock_user_repository.dart';
import '../repositories/real_user_repository.dart';
import '../usecases/update_profile_use_case.dart';
import '../usecases/guest_login_use_case.dart';
import '../usecases/get_my_profile_use_case.dart';
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
  final useCase = ref.watch(getMyProfileUseCaseProvider);
  return useCase.execute();
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
