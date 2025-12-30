import 'dart:io';
import '../models/user_model.dart';

abstract class UserRepository {
  /// 내 프로필 조회
  Future<UserModel?> getMyProfile();

  /// 프로필 업데이트 (이름, 상태 메시지, 이미지)
  /// null 파라미터는 업데이트하지 않음을 의미 (일부 필드만 수정 가능)
  Future<void> updateProfile({
    String? name,
    String? statusMessage,
    File? image,
  });
}
