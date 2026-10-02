import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../features/connect/domain/invite_code.dart';
import '../features/connect/domain/partner_label.dart';
import '../models/user_model.dart';
import 'connect_repository.dart';
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
      inviteCode: 'TEST2345',
      loginType: LoginType.guest,
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
    await Future.delayed(const Duration(milliseconds: 300));
    final normalized = normalizeInviteCode(code);
    if (_mockUser != null && _mockUser!.inviteCode == normalized) {
      // Like resolveInviteCode's `self_code`.
      throw const InviteCodeIsMineException();
    }
    // Any other well-formed code belongs to a mock partner, so the confirm
    // sheet can be exercised in mock mode.
    if (isValidInviteCode(normalized)) {
      final now = DateTime.now();
      return UserModel(
        uid: 'mock_manager_id_123',
        displayName: '지민',
        inviteCode: normalized,
        createdAt: now,
        updatedAt: now,
      );
    }
    return null;
  }

  @override
  Future<void> deleteUser(String uid) async {
    if (_mockUser != null && _mockUser!.uid == uid) {
      _mockUser = null;
    }
  }

  @override
  Stream<UserModel?> watchMyProfile() {
    return Stream.value(_mockUser);
  }

  @override
  Future<void> updateProfile({
    String? name,
    String? statusMessage,
    String? imagePath,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Ensure _mockUser is not null before calling copyWith
    if (_mockUser == null) return;

    _mockUser = _mockUser!.copyWith(
      displayName: name,
      statusMessage: statusMessage,
      profileImageUrl: imagePath,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> updateFcmToken(String uid, String token) async {
    // Mock implementation - do nothing or log
    debugPrint('MockUserRepository: FCM token updated for $uid: $token');
  }

  @override
  Future<void> clearFcmToken(String uid) async {
    debugPrint('MockUserRepository: FCM token cleared for $uid');
  }

  @override
  Future<void> updatePartnerNickname(String? nickname) async {
    final user = _mockUser;
    if (user == null) return;
    final value = normalizePartnerNickname(nickname);
    _mockUser = value == null
        ? user.copyWith(clearPartnerNickname: true)
        : user.copyWith(partnerNickname: value);
  }

  @override
  Future<void> markPivotNoticeSeen() async {
    final user = _mockUser;
    if (user == null) return;
    _mockUser = user.copyWith(pivotNoticeSeen: true);
  }

  @override
  Future<void> markTermsAccepted() async {}
}
