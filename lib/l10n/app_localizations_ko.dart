// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '그래, 해봐';

  @override
  String get splashTagline => '혼자서 지키지 못했던 계획을, 함께';

  @override
  String get loginWithGoogle => 'Google로 시작하기';

  @override
  String get loginWithApple => 'Apple로 시작하기';

  @override
  String get loginGuest => '로그인 없이 시작하기';

  @override
  String get privacyMessage => '강요하지 않아요. 기록은 둘만 봅니다.';

  @override
  String get connectHeadline => '혼자서는 지키기 힘든 약속,';

  @override
  String get connectSubtitle => '누군가 지켜봐준다면 해낼 수 있을 거예요.';

  @override
  String get createInviteCode => '초대 코드 만들기';

  @override
  String get enterInviteCode => '초대 코드 입력';

  @override
  String get startSolo => '혼자 시작하기';

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
  String get homeNowTask => '지금 할 약속이 있어요';

  @override
  String get homeDidIt => '했어';

  @override
  String get homeReceivedMessage => '이렇게 할게요';

  @override
  String get homeCheckIt => '그래, 해봐';

  @override
  String get homeSentWaiting => '실천 내역을 보냈어요';

  @override
  String get homeWaitingForCheck => '확인을 기다리고 있어요';

  @override
  String get homeQuietDay => '오늘은 여유로운 날이에요';

  @override
  String get homeChecked => '그래';

  @override
  String get homeThankYou => '응원해요 💜';

  @override
  String get timePassedActorMessage => '조금 늦었지만 괜찮아요';

  @override
  String get timePassedManagerMessage => '아직 전달된 말이 없어요';

  @override
  String get timePassedActorSubMessage => '지금 선택해도 돼요';

  @override
  String get timePassedManagerSubMessage => '오늘은 조용히 지나가고 있어요';

  @override
  String get pastUncompletedMessage => '조금 늦었지만 괜찮아요';

  @override
  String get pastUncompletedSubMessage => '지금 선택해도 돼요';

  @override
  String get pastUncompletedTimeChip => '조금 전';

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
  String get usMeTitle => '나';

  @override
  String get usDefaultNameMe => '나';

  @override
  String get usYouTitle => '너';

  @override
  String get usProfileEdit => '편집';

  @override
  String get usStatusMessagePlaceholder => '상태 메시지 설정';

  @override
  String get usMyIntroduction => '내 소개';

  @override
  String get usMyInviteCode => '내 초대 코드';

  @override
  String get usBadgeSupported => '지지받는 중';

  @override
  String get usBadgeCheering => '응원하는 중';

  @override
  String get usGuestWarningMessage => '휴대폰을 바꾸거나 앱/데이터를 삭제하면 기록을 잃을 수 있어요.';

  @override
  String get usGuestWarningAction => '계정 연결하고 기록 지키기';

  @override
  String get usLinkSuccess => '구글 계정이 성공적으로 연결되었습니다!';

  @override
  String usLinkError(String error) {
    return '계정 연결 실패: $error';
  }

  @override
  String get usLoadError => '연결 정보를 불러오는 중 오류가 발생했습니다.';

  @override
  String get usNoInviteCode => '코드 없음';

  @override
  String get usNoName => '이름 없음';

  @override
  String get usUnknownUser => '상대방';

  @override
  String get usDisconnectDialogTitle => '연결 해제';

  @override
  String usDisconnectDialogContent(String name) {
    return '$name님과의 연결을 해제하시겠습니까?';
  }

  @override
  String get usDisconnectConfirm => '해제';

  @override
  String get usDisconnectSuccess => '연결이 해제되었습니다.';

  @override
  String usDisconnectError(String error) {
    return '연결 해제 실패: $error';
  }

  @override
  String get usDisconnectTooltip => '연결 해제';

  @override
  String get usCropImageTitle => '프로필 사진 자르기';

  @override
  String get cancel => '취소';

  @override
  String get usProfileEditImageLabel => '프로필 사진 변경';

  @override
  String get usAddConnectionLabel => '새 연결 추가';

  @override
  String get usBadgeMutual => '함께하는 중';

  @override
  String get usEmptyMatesTitle => '아직 연결된 메이트가 없어요';

  @override
  String get usEmptyMatesSubtitle => '초대 코드를 보내서 서로의 안전 기지가 되어주세요';

  @override
  String get usConnectedPeople => 'Connected People';

  @override
  String get usManaging => 'Managing';

  @override
  String get usEntrusted => 'Entrusted';

  @override
  String get usInviteNew => 'Invite New Person';

  @override
  String get usNoConnections => 'No connections yet';

  @override
  String headerWeekProgress(int week, int total) {
    return '$total주 중 · $week주차';
  }

  @override
  String get headerNoPlan => '아직 계획이 없어요';

  @override
  String get headerPlanEnded => '4주가 끝났어요';

  @override
  String get nowNoPlan => '지금은 약속이 없어요';

  @override
  String get nowCreatePlan => '+ 새 약속 정하기';

  @override
  String nowNextActionIn(String time) {
    return '다음 행동까지 $time 남았어요';
  }

  @override
  String nowNextActionDays(int days) {
    return '다음 일정까지 D-$days예요';
  }

  @override
  String get nowQuietRest => '오늘은 여유로운 날이에요';

  @override
  String get nowQuietNoAction => '당분간 신경 쓸 일은 없어요';

  @override
  String get nowNoPlanSubtitle => '한 가지 약속만 정해볼까요?';

  @override
  String get nowTodayDone => '오늘은 다 챙겼어요 🙌';

  @override
  String get nowPartnerProposed => '이런 약속을 제안했어요';

  @override
  String get nowPartnerAdjusting => '약속을 조금 조정하고 있어요';

  @override
  String get nowPartnerDidIt => '나 했어요!';

  @override
  String get nowActionPass => '그냥 넘기기';

  @override
  String get nowActionSkipToday => '오늘은 넘어가자';

  @override
  String recordGazeWeekCount(int count) {
    return '이번 주 약속 중 $count번째';
  }

  @override
  String recordGazeWeekProgress(int week, int total) {
    return '$total주 중 $week주차';
  }

  @override
  String recordGazeDoneCount(int count) {
    return '이미 $count번은 했어요';
  }

  @override
  String get managerSuggestionTitle => '이 약속, 누군가에게 맡기면';

  @override
  String get managerSuggestionSubtitle => '조금 쉬워질지도 몰라요';

  @override
  String get managerSuggestionAlternative => '혼자 지키기 버거우면, 같이 해볼 수도 있어요';

  @override
  String get managerSuggestionButton => '맡아줄 사람 찾기';

  @override
  String get managerSuggestionQuestion => '이 약속을 맡아줄 사람이 있나요?';

  @override
  String get planProposal => '내가 정한 약속';

  @override
  String get planPreparing => '약속 준비 중';

  @override
  String get planWhatToPromise => '무엇을 약속할까요?';

  @override
  String get planPromiseHint => '지킬 수 있을 것 같은 정도면 좋아요';

  @override
  String get planMyPromise => '내가 나에게 한 말';

  @override
  String get planKeepWatching => '지켜보고 싶은 약속';

  @override
  String get planActionHint => 'ex) 아이랑 시간 보내기, 책 읽는 시간 만들기';

  @override
  String get planOneLineEnough => '한 줄만 적어도 돼요';

  @override
  String get planNext => '다음';

  @override
  String get planFrequencyTitle => '요 정도면 어떨까요?';

  @override
  String get planFrequencySubtitle => '완벽하게 안 지켜도 괜찮아요';

  @override
  String get planDescriptionTitle => '원하면, 구체적으로 적어도 괜찮아요';

  @override
  String get planDescriptionSubtitle => '나중에 바꿀 수 있어요';

  @override
  String get planDescriptionLabel => '구체적으로 뭘 할지 적어볼까요?';

  @override
  String get planDescriptionExample => '예: 집에서 스쿼트랑 스트레칭';

  @override
  String get planDescriptionHint => '예: 집에서 스쿼트랑 스트레칭, 헬스장 가서 하체 운동...';

  @override
  String get planDescriptionSkip => '건너뛰기';

  @override
  String get planDescriptionOptional => '이 단계는 건너뛰어도 괜찮아요';

  @override
  String get planDayTitle => '요일은 안 정해도 돼요';

  @override
  String get planDaySubtitle => '정해두면 기억하기가 조금 더 쉬워요';

  @override
  String get planDaySkip => '그냥 그날 컨디션 보고 할게요';

  @override
  String get planSummaryTitle => '이렇게 제안할 거예요';

  @override
  String get planSummaryFrequency => '빈도';

  @override
  String get planSummaryDay => '요일';

  @override
  String get planSummaryDescription => '설명';

  @override
  String get planSummaryDayConditional => '컨디션 보고 결정';

  @override
  String get planSummaryInfo => '이건 제안이에요. 상대가 보고 같이 정해요.';

  @override
  String get planSummaryAdjustable => '부담되면 언제든 조정할 수 있어요';

  @override
  String get planSummarySend => '이렇게 할게요';

  @override
  String get planSummarySent => '계획 제안이 전송되었어요';

  @override
  String get planFrequencyLight => '가볍게';

  @override
  String get planFrequencyModerate => '적당히';

  @override
  String get planFrequencyMore => '조금 더';

  @override
  String get planFrequencyWeekly2 => '주 2회';

  @override
  String get planFrequencyWeekly3 => '주 3회';

  @override
  String get planFrequencyWeekly4 => '주 4회';

  @override
  String get planFrequencyLightWithCount => '가볍게 (주 2회)';

  @override
  String get planFrequencyModerateWithCount => '적당히 (주 3회)';

  @override
  String get planFrequencyMoreWithCount => '조금 더 (주 4회)';

  @override
  String get connectConnected => '연결되었어요';

  @override
  String get connectGoToHome => '홈으로 가기';

  @override
  String get usPlanSection => '계획';

  @override
  String get usNoPlanMessage => '현재 계획이 없어요';

  @override
  String get usNoPlanSubtitle => '새로운 약속을 시작해볼까요?';

  @override
  String get usStartNewPlan => '새 계획 시작';

  @override
  String get dayMonday => '월';

  @override
  String get dayTuesday => '화';

  @override
  String get dayWednesday => '수';

  @override
  String get dayThursday => '목';

  @override
  String get dayFriday => '금';

  @override
  String get daySaturday => '토';

  @override
  String get daySunday => '일';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsLanguageKorean => '한국어';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsTheme => '색상 테마';

  @override
  String get settingsThemeSmokyPlum => 'Smoky Plum × Warm Stone';

  @override
  String get settingsThemeDeepOlive => 'Deep Olive × Sand';

  @override
  String get developerTitle => '개발자 화면';

  @override
  String get developerScreenNavigation => '화면 이동';

  @override
  String get developerScreenNavigationDesc => '각 화면으로 바로 이동할 수 있습니다';

  @override
  String get developerAuthSection => '인증 & 연결';

  @override
  String get developerMainSection => '메인 화면';

  @override
  String get developerPlanSection => '계획 생성';

  @override
  String get developerDeepLink => '딥링크';

  @override
  String get developerDeepLinkFormat => '딥링크 URL 형식:';

  @override
  String get developerScreenSplash => '스플래시';

  @override
  String get developerScreenLogin => '로그인';

  @override
  String get developerScreenConnect => '연결';

  @override
  String get developerScreenHome => '홈';

  @override
  String get developerScreenDeveloper => '개발자';

  @override
  String get developerScreenSettings => '설정';

  @override
  String get developerScreenSplashDesc => '앱 시작 화면';

  @override
  String get developerScreenLoginDesc => 'Google/Apple 로그인';

  @override
  String get developerScreenConnectDesc => '커플 연결 화면';

  @override
  String get developerScreenHomeDesc => '지금/기록/우리 탭';

  @override
  String get developerScreenSettingsDesc => '언어 및 테마 설정';

  @override
  String get developerScreenActionSelection => '행동 선택';

  @override
  String get developerScreenFrequency => '빈도 설정';

  @override
  String get developerScreenDaySelection => '요일 선택';

  @override
  String get developerScreenDescription => '설명';

  @override
  String get developerScreenSummary => '요약';

  @override
  String get developerScreenActionSelectionDesc => 'Screen 1: 행동 선택';

  @override
  String get developerScreenFrequencyDesc => 'Screen 2: 반복 빈도';

  @override
  String get developerScreenDaySelectionDesc => 'Screen 3: 요일 선택';

  @override
  String get developerScreenDescriptionDesc => 'Screen 3: 구체 행동 설명';

  @override
  String get developerScreenSummaryDesc => 'Screen 5: 계획 제안 요약';

  @override
  String get settingsPlanCreation => '계획 생성';

  @override
  String get settingsPlanCreationTitle => '새 약속 만들기';

  @override
  String get settingsPlanCreationDesc => '모든 단계를 한 화면에서';

  @override
  String get settingsDeveloper => '개발자 메뉴';

  @override
  String get settingsDeveloperDesc => '디버그 메뉴';

  @override
  String get settingsAccount => '계정 관리';

  @override
  String get settingsDeleteAccount => '회원 탈퇴';

  @override
  String get settingsDeleteAccountDesc => '계정과 모든 데이터를 영구적으로 삭제합니다';

  @override
  String get settingsDeleteAccountDialogTitle => '회원 탈퇴';

  @override
  String get settingsDeleteAccountDialogContent =>
      '정말로 탈퇴하시겠습니까? 이 작업은 되돌릴 수 없습니다.';

  @override
  String get settingsCancel => '취소';

  @override
  String get settingsDelete => '탈퇴';

  @override
  String get loginWithEmail => '이메일로 계속하기';

  @override
  String get email => '이메일';

  @override
  String get password => '비밀번호';

  @override
  String get login => '로그인';

  @override
  String get signUp => '회원가입';

  @override
  String get emailStartMessage => '이메일로 시작하기';

  @override
  String get passwordHint => '비밀번호를 입력해주세요';

  @override
  String get emailHint => '이메일을 입력해주세요';

  @override
  String get invalidEmail => '유효한 이메일 형식이 아닙니다';

  @override
  String get weakPassword => '비밀번호는 6자 이상이어야 합니다';

  @override
  String get accountExistsWithDifferentCredential => '이미 가입된 이메일입니다.';

  @override
  String get userNotFound => '가입되지 않은 이메일입니다.';

  @override
  String get wrongPassword => '비밀번호가 일치하지 않습니다.';

  @override
  String get settingsAccountDeletedSuccess => '계정이 삭제되었습니다';

  @override
  String get settingsAuthServiceNotFound => '인증 서비스를 찾을 수 없습니다';

  @override
  String settingsDeleteAccountFailed(Object error) {
    return '계정 삭제 실패: $error';
  }

  @override
  String get reconcileTitle => '정리하기';

  @override
  String get reconcileActuallyDone => '사실 했어요';

  @override
  String get reconcileTookRest => '오늘은 쉬어갔어요';

  @override
  String get reconcileSkip => '넘어갈게요';

  @override
  String get reconcileDoneMessage => '기록이 정리되었습니다.';

  @override
  String get historyFilterAll => '모두';

  @override
  String get historyFilterMe => '내 실천';

  @override
  String get historyFilterPartner => '파트너의 실천';

  @override
  String get historyMyActionVerified => '파트너가 봤어요';

  @override
  String get historyPartnerActionVerified => '봤어요';

  @override
  String get historyPartnerActionWaiting => '아직 안 봤어요...';

  @override
  String get historyActionSawIt => '봤어요 👍';

  @override
  String get historyActionCheer => '응원할게 💜';

  @override
  String get timeChipStillActionable => '아직 할 수 있어요';

  @override
  String get timeChipPassed => '지나갔어요';

  @override
  String get nowStatusActuallyDone => '사실 했어요';

  @override
  String get nowLateCompletion => '뒤늦게라도 완료!';

  @override
  String get nowLateJustInTime => '조금 늦게 했어요';

  @override
  String get nowWithinToday => '오늘 안에 했어요';

  @override
  String get timeChipNow => '지금!';

  @override
  String get timeChipJustNow => '방금 전';

  @override
  String timeChipMinutesAgo(int minutes) {
    return '$minutes분 지남';
  }

  @override
  String timeChipHoursAgo(int hours) {
    return '$hours시간 지남';
  }

  @override
  String timeChipMinutesLeft(int minutes) {
    return '$minutes분 전';
  }

  @override
  String timeChipHoursLeft(int hours) {
    return '$hours시간 전';
  }

  @override
  String get timeChipYesterday => '어제';

  @override
  String timeChipDaysAgo(int days) {
    return '$days일 지남';
  }

  @override
  String get timeChipTomorrow => '내일';

  @override
  String get timeChipDayAfterTomorrow => '모레';

  @override
  String timeChipDaysLeft(int days) {
    return '$days일 뒤';
  }

  @override
  String timeChipNextWeek(String weekday) {
    return '다음주 $weekday';
  }

  @override
  String timeChipDate(int month, int day) {
    return '$month월 $day일';
  }

  @override
  String get vagueTimeMorning => '아침에';

  @override
  String get vagueTimeLunch => '점심쯤';

  @override
  String get vagueTimeAfternoon => '오후에';

  @override
  String get vagueTimeEvening => '저녁에';

  @override
  String get vagueTimeNight => '밤에';

  @override
  String get vagueTimeLateNight => '새벽에';

  @override
  String get weekdayMon => '월';

  @override
  String get weekdayTue => '화';

  @override
  String get weekdayWed => '수';

  @override
  String get weekdayThu => '목';

  @override
  String get weekdayFri => '금';

  @override
  String get weekdaySat => '토';

  @override
  String get weekdaySun => '일';
}
