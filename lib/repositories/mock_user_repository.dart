import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'user_repository.dart';

class MockUserRepository implements UserRepository {
  UserModel? _mockUser;

  @override
  Future<void> initializeUser(User user) async {
    // Mock에서는 별도 초기화 로직 불필요 (생성자에서 이미 더미 설정됨) or 더미 업데이트
    await Future.delayed(const Duration(milliseconds: 300));
  }

  MockUserRepository() {
    // 초기 더미 데이터
    _mockUser = UserModel(
      uid: 'mock-uid-1234',
      displayName: '나(Mock)',
      statusMessage: '오늘도 힘내자!',
      inviteCode: 'TEST0123',
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
  Future<List<UserModel>> getUsersByIds(List<String> uids) async {
    if (_mockUser != null) {
      return [_mockUser!];
    }
    return [];
  }

  @override
  Future<UserModel?> getUserByInviteCode(String code) async {
    if (_mockUser != null && code == _mockUser!.inviteCode) {
      return _mockUser;
    }
    return null;
  }

  @override
  Stream<UserModel?> watchMyProfile() {
    // Mock에서는 단순히 현재 Mock 유저를 한 번 방출하는 Stream 반환
    // 실제 앱처럼 동작하려면 StreamController 등을 써야 하지만,
    // 간단한 테스트용으로는 현재 상태를 리턴.
    return Stream.value(_mockUser);
  }

  @override
  Future<void> updateProfile({
    String? name,
    String? statusMessage,
    File? image,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Ensure _mockUser is not null before calling copyWith
    if (_mockUser == null) return;
    _mockUser = _mockUser!.copyWith(
      displayName: name,
      statusMessage: statusMessage,
      // 이미지는 Mock이라 별도 처리 안함 (필요시 로컬 경로 할당 등)
      updatedAt: DateTime.now(),
    );
  }
}
