import '../models/connected_user.dart';

import '../repositories/connect_repository.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';

class GetConnectedProfilesUseCase {
  final ConnectRepository _connectRepository;
  final UserRepository _userRepository;
  final AuthService _authService;

  GetConnectedProfilesUseCase(
    this._connectRepository,
    this._userRepository,
    this._authService,
  );

  Future<List<ConnectedUser>> execute() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return [];

    // 1. 연결 목록 조회 (내가 Executor거나 Manager인 경우 모두)
    final connections = await _connectRepository.getConnections();
    if (connections.isEmpty) return [];

    // 2. 파트너 ID 추출
    final partnerIds = <String>{};
    for (var conn in connections) {
      if (conn.executorId == currentUser.uid) {
        partnerIds.add(conn.managerId); // 나를 지지해주는 사람
      } else if (conn.managerId == currentUser.uid) {
        partnerIds.add(conn.executorId); // 내가 응원하는 사람
      }
    }

    if (partnerIds.isEmpty) return [];

    // 3. 파트너 프로필 조회 (Batch)
    final partners = await _userRepository.getUsersByIds(partnerIds.toList());
    final partnerMap = {for (var user in partners) user.uid: user};

    // 4. 도메인 모델 매핑 (Relation + User)
    final result = <String, ConnectedUser>{}; // uid -> ConnectedUser

    for (var conn in connections) {
      String partnerId;
      bool isSupported = false;
      bool isCheering = false;

      if (conn.executorId == currentUser.uid) {
        partnerId = conn.managerId;
        isSupported = true; // 매니저가 나를 지지함
      } else {
        partnerId = conn.executorId;
        isCheering = true; // 내가 실행자를 응원함
      }

      final user = partnerMap[partnerId];
      if (user == null) continue;

      if (result.containsKey(partnerId)) {
        // 이미 존재하면 플래그 병합 (상호 연결 케이스)
        final existing = result[partnerId]!;
        result[partnerId] = ConnectedUser(
          user: user,
          isSupported: existing.isSupported || isSupported,
          isCheering: existing.isCheering || isCheering,
        );
      } else {
        result[partnerId] = ConnectedUser(
          user: user,
          isSupported: isSupported,
          isCheering: isCheering,
        );
      }
    }

    return result.values.toList();
  }
}
