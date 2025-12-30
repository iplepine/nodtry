import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final type = ref.watch(repositoryTypeProvider);
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
/// Repository 타입 상태 관리 Notifier
class RepositoryTypeNotifier extends Notifier<RepositoryType> {
  @override
  RepositoryType build() {
    return RepositoryType.mock; // 기본값: Mock
  }

  void setType(RepositoryType type) {
    state = type;
  }
}

/// Repository 타입 상태 관리 Provider
final repositoryTypeProvider =
    NotifierProvider<RepositoryTypeNotifier, RepositoryType>(() {
      return RepositoryTypeNotifier();
    });

/// RecordRepository Provider
///
/// repositoryTypeProvider 상태에 따라 Mock 또는 Real 구현체를 반환합니다.
final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  final type = ref.watch(repositoryTypeProvider);
  if (type == RepositoryType.real) {
    return RealRecordRepository();
  }
  // Default to Mock
  return MockRecordRepository();
});

/// ConnectRepository Provider
final connectRepositoryProvider = Provider<ConnectRepository>((ref) {
  final type = ref.watch(repositoryTypeProvider);
  if (type == RepositoryType.real) {
    return RealConnectRepository();
  }
  // Default to Mock
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
