import 'user_model.dart';

/// 연결된 사용자 도메인 모델
///
/// UseCase에서 반환하며, UI에서 나와의 관계를 쉽게 파악할 수 있도록 함.
class ConnectedUser {
  final UserModel user;
  final bool isSupported; // 내가 이 사람에게 지지받고 있음 (User is Manager)
  final bool isCheering; // 내가 이 사람을 응원하고 있음 (User is Executor)

  ConnectedUser({
    required this.user,
    required this.isSupported,
    required this.isCheering,
  });

  bool get isMutual => isSupported && isCheering;
}
