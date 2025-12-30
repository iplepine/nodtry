import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'get_my_profile_use_case.dart';

class AutoLoginUseCase {
  final AuthService _authService;
  final GetMyProfileUseCase _getMyProfileUseCase;

  AutoLoginUseCase(this._authService, this._getMyProfileUseCase);

  /// 자동 로그인 시도
  /// 로그인 성공 시 UserModel 반환, 실패 하거나 타임아웃 시 Exception/null
  Future<UserModel?> execute() async {
    final user = _authService.currentUser;
    if (user == null) {
      return null;
    }

    try {
      // 타임아웃 5초 적용 (스플래시 화면 요구사항)
      final profileFn = _getMyProfileUseCase.execute();
      final userModel = await profileFn
          .firstWhere((user) => user != null)
          .timeout(const Duration(seconds: 5));

      return userModel;
    } catch (e) {
      // 게스트인 경우 타임아웃/에러 시에도 로그아웃 하지 않음 (세션 유지)
      // 사용자가 다시 시도(Guest Login 버튼)할 때 재사용할 수 있도록.
      // 단, 계정이 삭제된 경우(null 반환됨)는 위에서 걸러짐.
      // 여기가 호출되는건 TimeoutException 등임.
      if (user.isAnonymous) {
        // 로그아웃 안함
        debugPrint(
          "AutoLogin failed due to error ($e), but keeping Guest session.",
        );
      } else {
        // 일반 유저(구글 등)는 로그아웃 하여 재로그인 유도
        await _authService.signOut();
      }
      rethrow;
    }
  }
}
