import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

abstract class UserRepository {
  /// 앱 시작/로그인 시 사용자 데이터 동기화 (없으면 생성)
  Future<void> initializeUser(User user);

  /// 내 프로필 조회
  Future<UserModel?> getMyProfile();

  /// 내 프로필 실시간 감지 (Stream)
  Stream<UserModel?> watchMyProfile();

  /// 여러 사용자 프로필 조회 (Batch)
  Future<List<UserModel>> getUsersByIds(List<String> uids);

  /// 초대 코드로 사용자 조회
  Future<UserModel?> getUserByInviteCode(String code);

  /// 프로필 업데이트 (이름, 상태 메시지, 이미지)
  /// null 파라미터는 업데이트하지 않음을 의미 (일부 필드만 수정 가능)
  Future<void> updateProfile({
    String? name,
    String? statusMessage,
    String? imagePath,
  });

  /// 회원 탈퇴 (데이터 삭제)
  Future<void> deleteUser(String uid);

  /// FCM 토큰 업데이트
  Future<void> updateFcmToken(String uid, String token);

  /// FCM 토큰 제거 (알림 권한 거부/철회 시, 죽은 토큰으로의 전송 방지)
  Future<void> clearFcmToken(String uid);
}
