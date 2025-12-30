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

// ... (ConnectRepository related imports and providers kept below)

/// UserRepository Provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final typeAsync = ref.watch(repositoryTypeProvider);
  // 로딩 중이거나 에러 발생 시 기본값(Mock) 사용
  final type = typeAsync.asData?.value ?? RepositoryType.mock;

  if (type == RepositoryType.real) {
    return RealUserRepository();
  }
  return MockUserRepository();
});

/// My Profile Provider (Future)
final myProfileProvider = FutureProvider<UserModel?>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getMyProfile();
});

/// UpdateProfileUseCase Provider
final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return UpdateProfileUseCase(repository);
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
    if (value == 'real') {
      return RepositoryType.real;
    }
    return RepositoryType.mock;
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
  final type = typeAsync.asData?.value ?? RepositoryType.mock;

  if (type == RepositoryType.real) {
    return RealRecordRepository();
  }
  return MockRecordRepository();
});

/// ConnectRepository Provider
final connectRepositoryProvider = Provider<ConnectRepository>((ref) {
  final typeAsync = ref.watch(repositoryTypeProvider);
  final type = typeAsync.asData?.value ?? RepositoryType.mock;

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
