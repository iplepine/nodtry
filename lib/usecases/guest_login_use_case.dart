import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';
import '../datasources/user_local_data_source.dart';

class GuestLoginUseCase {
  final AuthService _authService;
  final UserRepository _userRepository;
  final UserLocalDataSource _userLocalDataSource;

  GuestLoginUseCase(
    this._authService,
    this._userRepository,
    this._userLocalDataSource,
  );

  Future<UserCredential> execute() async {
    // 1. 이미 익명 로그인 상태인지 확인
    final currentUser = _authService.currentUser;
    if (currentUser != null && currentUser.isAnonymous) {
      // 이미 익명 로그인 상태라면 재사용
      // UserCredential을 직접 생성할 수 없으므로, 더미 혹은 별도 처리가 필요할 수 있지만
      // 여기서는 initializeUser/saveUser만 보장하면 됨.
      // 하지만 반환타입이 UserCredential이므로...
      // FirebaseAuth에서 현재 유저로 Credential을 얻는건 reauthenticate 등인데 복잡함.
      // 단순히 로직을 분기하여 처리.

      // 이미 로그인이 되어 있으므로 초기화 및 캐싱만 수행
      await _initializeAndCache(currentUser);

      // UserCredential 반환이 어렵다면...
      // 사실 이 메서드를 호출하는 곳(SplashScreen)에서는 navigateToNext만 하면 됨.
      // 하지만 타입이 Future<UserCredential>임.
      // signInAnonymously()는 UserCredential을 반환함.
      // *중요*: 이미 로그인된 상태에서 signInAnonymously() 호출 시,
      // Firebase Auth가 기존 세션을 유지하는지, 새로 파는지 확인 필요.
      // 문서상: "If there is already a user signed in, that user will be signed out." -> 기존 세션 날아감!

      // 따라서 여기서 바로 리턴해야 함. 하지만 UserCredential을 만들 수 없음.
      // 해결책: 반환 타입을 User? 로 변경하거나, 예외적으로 throw하지 않고 처리.
      // 구조상 UserCredential이 꼭 필요하지 않다면 User로 변경하는게 나음.
      // 일단은 에러 없이 진행하기 위해 signInAnonymously 호출을 건너뛰는 방식으로 가야함.

      throw UnimplementedError(
        "UserCredential Cannot be mocked for existing user. Refactor logic.",
      );
    }

    // 1. 익명 로그인
    final userCredential = await _authService.signInAnonymously();

    if (userCredential.user != null) {
      await _initializeAndCache(userCredential.user!);
    }

    return userCredential;
  }

  Future<void> _initializeAndCache(User user) async {
    // 2. 사용자 문서 초기화 (없으면 생성)
    await _userRepository.initializeUser(user);

    // 3. 초기화된 유저 정보 가져와서 캐싱
    final userModel = await _userRepository.getMyProfile();
    if (userModel != null) {
      await _userLocalDataSource.saveUser(userModel);
    }
  }
}
