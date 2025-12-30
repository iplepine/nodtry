import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

abstract class UserRepository {
  /// 앱 시작/로그인 시 사용자 데이터 동기화 (없으면 생성)
  Future<void> initializeUser(User user);

  /// 내 프로필 조회
  Future<UserModel?> getMyProfile();

  /// 여러 사용자 프로필 조회 (Batch)
  Future<List<UserModel>> getUsersByIds(List<String> uids);

  /// 초대 코드로 사용자 조회
  Future<UserModel?> getUserByInviteCode(String code);

  /// 프로필 업데이트 (이름, 상태 메시지, 이미지)
  /// null 파라미터는 업데이트하지 않음을 의미 (일부 필드만 수정 가능)
  Future<void> updateProfile({
    String? name,
    String? statusMessage,
    File? image,
  });
}
