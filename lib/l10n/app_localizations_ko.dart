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

  @override
  String get homeNowTask => '지금 할 일이 있어요';

  @override
  String get homeDidIt => '했어';

  @override
  String get homeReceivedMessage => '전달받은 말이 있어요';

  @override
  String get homeCheckIt => '확인하기';

  @override
  String get homeSentWaiting => '전달했어요';

  @override
  String get homeWaitingForCheck => '확인을 기다리고 있어요';

  @override
  String get homeQuietDay => '지금은 잠시 쉬어도 돼요';

  @override
  String get homeChecked => '확인됐어요';

  @override
  String get homeThankYou => '고마워요';

  @override
  String homeContextWeek(int week, int total) {
    return '$total주 중 · $week주차';
  }

  @override
  String homeContextEntrusted(String name) {
    return '$name에게 맡긴 중';
  }

  @override
  String homeContextManaging(String name) {
    return '$name를 관리 중';
  }

  @override
  String get tabNow => '지금';

  @override
  String get tabHistory => '기록';

  @override
  String get tabUs => '우리';

  @override
  String get historyEmpty => '아직 기록이 없어요';

  @override
  String get usConnectedPeople => '연결된 사람';

  @override
  String get usManaging => '관리 중';

  @override
  String get usEntrusted => '맡긴 중';

  @override
  String get usInviteNew => '새 사람 초대';

  @override
  String get usNoConnections => '아직 연결된 사람이 없어요';

  @override
  String headerWeekProgress(int week, int total) {
    return '$total주 중 · $week주차';
  }

  @override
  String get headerNoPlan => '아직 계획이 없어요';

  @override
  String get headerPlanEnded => '4주가 끝났어요';

  @override
  String get nowNoPlan => '이번 달 계획이 아직 없어요';

  @override
  String get nowCreatePlan => '계획 짜기';

  @override
  String nowNextActionIn(String time) {
    return '다음 행동까지 $time 남았어요';
  }

  @override
  String nowNextActionDays(int days) {
    return '다음 일정까지 D-$days예요';
  }

  @override
  String get nowQuietRest => '지금은 잠시 쉬어도 돼요';

  @override
  String get nowQuietNoAction => '당분간 신경 쓸 일은 없어요';
}
