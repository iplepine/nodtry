import 'dart:io';
import '../models/user_model.dart';
import 'user_repository.dart';

class MockUserRepository implements UserRepository {
  UserModel? _mockUser;

  MockUserRepository() {
    // 초기 더미 데이터
    _mockUser = UserModel(
      uid: 'mock-uid-1234',
      displayName: '나(Mock)',
      statusMessage: '오늘도 힘내자!',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<UserModel?> getMyProfile() async {
    await Future.delayed(const Duration(milliseconds: 500)); // 지연 시뮬레이션
    return _mockUser;
  }

  @override
  Future<void> updateProfile({
    String? name,
    String? statusMessage,
    File? image,
  }) async {
    await Future.delayed(const Duration(seconds: 1)); // 저장 지연 시뮬레이션

    if (_mockUser == null) return;

    _mockUser = _mockUser!.copyWith(
      displayName: name ?? _mockUser!.displayName,
      statusMessage: statusMessage ?? _mockUser!.statusMessage,
      // 이미지는 로컬 mock에서 파일 경로 저장 혹은 무시 (여기선 무시)
      updatedAt: DateTime.now(),
    );
  }
}
