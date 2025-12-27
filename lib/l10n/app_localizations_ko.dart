// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'OnMyBehalf';

  @override
  String get splashTagline => '혼자서 지키지 못했던 계획을, 함께';

  @override
  String get loginWithGoogle => 'Google로 시작하기';

  @override
  String get loginWithApple => 'Apple로 시작하기';

  @override
  String get privacyMessage => '강요하지 않아요. 기록은 둘만 봅니다.';

  @override
  String get connectHeadline => '이번 달, 누군가에게 맡겨볼래요?';

  @override
  String get connectSubtitle => '계획은 내가 세우고, 관리는 상대가 해주는 방식이에요.';

  @override
  String get createInviteCode => '초대 코드 만들기';

  @override
  String get enterInviteCode => '초대 코드 입력';

  @override
  String get inviteCode => '초대 코드';

  @override
  String get copyCode => '코드 복사';

  @override
  String get shareCode => '공유하기';

  @override
  String get codeCopied => '코드가 복사되었어요';

  @override
  String get codeShareMessage => '이 코드를 상대에게 공유해주세요';

  @override
  String get enterCodeBelow => '아래에 코드를 입력해주세요';

  @override
  String get sendConnectionRequest => '연결 요청 보내기';

  @override
  String get waitingForConnection => '상대가 연결을 확인 중이에요';
}
