// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '그래,해봐';

  @override
  String get splashTagline => '혼자서 지키지 못했던 계획을, 함께';

  @override
  String get loginWithGoogle => 'Google 계정으로 계속하기';

  @override
  String get loginWithApple => 'Apple로 계속하기';

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
  String get historyEmpty => '아직 기록된 약속이 없어요';

  @override
  String get usMeTitle => '나';

  @override
  String get usDefaultNameMe => '나';

  @override
  String get usYouTitle => '파트너';

  @override
  String get usHeroSubtitle => '함께 만들어가는 약속들';

  @override
  String get usCheerSent => '응원을 보냈어요 ⚡';

  @override
  String get usCheerTooltip => '응원하기';

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
  String get nowTodayDone => '오늘 약속은 다 챙겼어요 🙌';

  @override
  String nowTodayAllDone(int count) {
    return '오늘 $count개 다 챙겼어요 🙌';
  }

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
  String get nowDeferMenuTooltip => '넘기기';

  @override
  String get nowDeferLaterTitle => '잠시 후에 할게';

  @override
  String get nowDeferLaterSubtitle => '다음 실천을 먼저 보고, 잠시 후 다시 알려드릴게요';

  @override
  String get nowSkipTodayTitle => '오늘은 안 할게';

  @override
  String get nowSkipTodaySubtitle => '오늘 이 약속은 넘어가요';

  @override
  String get nowSkipTodayDone => '오늘은 넘어갔어요';

  @override
  String get nowDeferLaterDone => '잠시 후에 다시 알려드릴게요';

  @override
  String get nowDeferReminderTitle => '다시 알려드려요';

  @override
  String get nowDeferReminderBody => '잠시 후에 하기로 한 약속이 있어요';

  @override
  String get nowAddMorePlan => '다른 약속도 만들어볼까요?';

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
  String get settingsThemeSmokyPlum => 'Mint × Orange';

  @override
  String get settingsThemeDeepOlive => 'Deep Olive × Sand';

  @override
  String get settingsThemePacific => 'Pacific';

  @override
  String get settingsThemeRoseMocha => 'Rose Mocha';

  @override
  String get settingsThemeLavenderDusk => 'Lavender Dusk';

  @override
  String get developerTitle => '개발자 화면';

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
  String get usLinkEmailAction => '이메일로 연결하기';

  @override
  String get usLinkEmailTitle => '이메일 계정 연결';

  @override
  String get usLinkEmailContent => '로그인에 사용할 이메일과 비밀번호를 입력해주세요.';

  @override
  String get usEmailLabel => '이메일';

  @override
  String get usPasswordLabel => '비밀번호';

  @override
  String get usLinkConfirm => '연결';

  @override
  String headerWithPartner(String name) {
    return '$name님과 함께';
  }

  @override
  String get usLinkEmailSuccess => '이메일 계정이 성공적으로 연결되었습니다!';

  @override
  String get historyPartnerVerified => '파트너가 확인했어요';

  @override
  String get historyMeVerified => '내가 확인했어요';

  @override
  String get frequencyEveryday => '매일';

  @override
  String get planNotificationTimeOptional => '알림 시간 (선택)';

  @override
  String get usMyPlanTitle => '나의 약속';

  @override
  String usPartnerPlanTitle(String name) {
    return '$name님의 약속';
  }

  @override
  String get vagueTimeDinner => '저녁';

  @override
  String get vagueTimeBedtime => '자기 전';

  @override
  String get cheerSimple => '그래';

  @override
  String get cheerMore => '더보기';

  @override
  String get cheerSheetTitle => '어떻게 응원할까요?';

  @override
  String get cheerMessageHint => '직접 응원 메시지를 남겨보세요';

  @override
  String get cheerSend => '보내기';

  @override
  String get doneSheetTitle => '완료 소감을 남겨보세요';

  @override
  String get doneMessageHint => '짧은 메모를 남겨주세요';

  @override
  String get doneButton => '완료하기';

  @override
  String get settingsDeveloperDesc => '디버그 메뉴';

  @override
  String get settingsAccount => '계정 관리';

  @override
  String get settingsLogout => '로그아웃';

  @override
  String get settingsLogoutDesc => '현재 계정에서 로그아웃합니다';

  @override
  String get settingsLogoutDialogTitle => '로그아웃';

  @override
  String get settingsLogoutDialogContent => '정말로 로그아웃하시겠습니까?';

  @override
  String get settingsLogoutConfirm => '로그아웃';

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
  String get reconcileActuallyDone => '했어';

  @override
  String get reconcileTookRest => '오늘은 쉬어갔어요';

  @override
  String get reconcileSkip => '넘어갈게요';

  @override
  String get reconcileDoneMessage => '기록이 정리되었습니다.';

  @override
  String get historyFilterAll => '모두';

  @override
  String get historyFilterMe => '나';

  @override
  String get historyFilterPartner => '너';

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
  String get nowStatusActuallyDone => '했어';

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

  @override
  String get planTimeQuestion => '몇 시쯤 알려드릴까요?';

  @override
  String get comfortingFuture => '오늘 하루도 수고했어요';

  @override
  String get comfortingLate => '늦어도 괜찮아요';

  @override
  String get comfortingJustDoIt => '오늘 안에만 하면 돼요';

  @override
  String get nowDoEarly => '미리 할게';

  @override
  String get nowDoAnytime => '오늘 할게';

  @override
  String get timeChipAnytime => '오늘 아무 때나';

  @override
  String get nowNextActionLater => '아직 시간 전이에요. 이따 해도 괜찮아요.';

  @override
  String get nowNextActionAnytime => '오늘 중 아무 때나 하면 돼요.';

  @override
  String get settingsNotifications => '알림 설정';

  @override
  String get notificationSettingsTitle => '알림 관리';

  @override
  String get noActiveAlarms => '설정된 알림이 없어요';

  @override
  String get historyTapToChange => '탭해서 상태 변경하기';

  @override
  String get settingsBuyDeveloperCoffee => '개발자에게 커피 사주기';

  @override
  String get settingsCoffeeSubtitle => '따뜻한 커피 한 잔이 큰 힘이 됩니다!';

  @override
  String get settingsCoffeePurchasing => '결제 처리 중...';

  @override
  String get settingsStoreUnavailable => '스토어와 연결할 수 없어요. (설정 확인 필요)';

  @override
  String get planMostlyProcrastinated => '주로 미루는 약속';

  @override
  String get planRecommendedPromises => '추천 약속';

  @override
  String get planMine => '내 약속';

  @override
  String get planClearAction => '비우기';

  @override
  String get planRecommendedFrequency => '추천 빈도';

  @override
  String get planNoDayMeansDaily => '요일을 선택하지 않으면 매일 하는 약속이 돼요.';

  @override
  String get planPartnerFallback => '파트너';

  @override
  String get planActionFallback => '내 약속';

  @override
  String get planPartnerPreviewLabel => '파트너에게 이렇게 보여요';

  @override
  String planPartnerPreviewWith(String name, String promise) {
    return '$name님에게 \"$promise\"를 28일 동안 놓치지 않게 당겨달라고 보냅니다.';
  }

  @override
  String get planPartnerPreviewWithout =>
      '파트너 없이 시작하면 똑똑을 받을 사람이 없어요. 저장 전 파트너를 연결하면 압박이 강해져요.';

  @override
  String get planConnectPartner => '파트너 연결하기';

  @override
  String get planDayEveryDay => '매일';

  @override
  String get planDayWeekdays => '평일';

  @override
  String planDayCountFormat(int count) {
    return '주 $count일';
  }

  @override
  String planPreviewMeta(String days, String time) {
    return '$days · $time · 28일';
  }

  @override
  String get planTimeAM => '오전';

  @override
  String get planTimePM => '오후';

  @override
  String planTimeFormatNoMinute(String period, int hour) {
    return '$period $hour시';
  }

  @override
  String planTimeFormatWithMinute(String period, int hour, String minute) {
    return '$period $hour시 $minute분';
  }

  @override
  String planTemplatePerWeek(String label, int count) {
    return '$label · 주 $count';
  }

  @override
  String get planCategoryStudyLabel => '공부';

  @override
  String get planCategoryStudyDescription => '영어, 자격증, 코딩처럼 혼자 미루는 학습';

  @override
  String get planCategoryExerciseLabel => '운동';

  @override
  String get planCategoryExerciseDescription => '걷기, 헬스장, 스트레칭처럼 시작이 어려운 움직임';

  @override
  String get planCategoryVerifiedLabel => '검증된 루틴';

  @override
  String get planCategoryVerifiedDescription => '신경과학·수면 연구 기반 일상 습관';

  @override
  String get planCategoryCustomLabel => '직접 입력';

  @override
  String get planCategoryCustomDescription => '추천 없이 내 약속을 직접 쓰기';

  @override
  String get planTemplateEnglishLabel => '영어';

  @override
  String get planTemplateEnglishAction => '영어 문장 10개 소리내어 읽기';

  @override
  String get planTemplateEnglishDescription => '부담 없이 매일 영어에 노출되는 것을 목표로 해요.';

  @override
  String get planTemplateCertificateLabel => '자격증';

  @override
  String get planTemplateCertificateAction => '기출 10문제 풀기';

  @override
  String get planTemplateCertificateDescription =>
      '많이 풀기보다 정해진 문제 수를 끊기지 않게 반복해요.';

  @override
  String get planTemplateCodingLabel => '코딩';

  @override
  String get planTemplateCodingAction => '30분 코딩 공부 또는 문제 1개';

  @override
  String get planTemplateCodingDescription => '과한 목표 대신 손을 대는 날을 먼저 확보해요.';

  @override
  String get planTemplateReadingLabel => '독서';

  @override
  String get planTemplateReadingAction => '10쪽 읽고 한 줄 기록';

  @override
  String get planTemplateReadingDescription =>
      '읽은 흔적을 한 줄로 남겨 파트너가 확인하기 쉽게 해요.';

  @override
  String get planTemplateWritingLabel => '글쓰기';

  @override
  String get planTemplateWritingAction => '15분 쓰기 또는 300자 작성';

  @override
  String get planTemplateWritingDescription => '완성보다 쓰기 시작한 날을 만드는 데 집중해요.';

  @override
  String get planTemplateWalkingLabel => '걷기';

  @override
  String get planTemplateWalkingAction => '30분 걷기';

  @override
  String get planTemplateWalkingDescription =>
      '운동복을 갖추는 것보다 밖에 나가는 약속을 먼저 만들어요.';

  @override
  String get planTemplateGymLabel => '헬스장';

  @override
  String get planTemplateGymAction => '헬스장 가서 30분 운동하기';

  @override
  String get planTemplateGymDescription => '완벽한 운동보다 헬스장에 도착하는 날을 늘려요.';

  @override
  String get planTemplateStretchingLabel => '스트레칭';

  @override
  String get planTemplateStretchingAction => '10분 스트레칭하기';

  @override
  String get planTemplateStretchingDescription =>
      '짧게라도 몸을 푸는 약속을 파트너에게 보이게 해요.';

  @override
  String get planTemplateMorningLightLabel => '아침 햇빛';

  @override
  String get planTemplateMorningLightAction => '아침 햇빛 5~10분 보기';

  @override
  String get planTemplateMorningLightDescription =>
      '아침 햇빛이 눈에 들어오면 뇌가 \'하루 시작\'을 인식해 저녁 멜라토닌 분비 타이밍이 맞춰져요. 그 결과 밤에 더 빨리, 더 깊이 잠들어요. 야외 5~10분이면 충분하고, 흐린 날엔 10~20분, 비 오는 날엔 20~30분으로 늘리세요. 창문 너머는 핵심 파장이 차단돼 효과가 약하고, 선글라스를 쓰면 빛 감지 세포가 충분히 활성화되지 않아요 (태양을 직접 쳐다보지는 마세요)';

  @override
  String get planTemplateCaffeineDelayLabel => '카페인 90분 뒤';

  @override
  String get planTemplateCaffeineDelayAction => '기상 90분 후 첫 카페인 마시기';

  @override
  String get planTemplateCaffeineDelayDescription =>
      '기상 직후 마시면 졸음 신호(아데노신)가 나중에 한꺼번에 몰려와 오후에 갑자기 졸려요. 90분 기다린 뒤 마시면 효과도 오래 갑니다';

  @override
  String get planTemplatePhysioSighLabel => '생리적 한숨';

  @override
  String get planTemplatePhysioSighAction => '5분 생리적 한숨 호흡하기';

  @override
  String get planTemplatePhysioSighDescription =>
      '코로 짧게 한 번, 이어서 한 번 더 들이쉬어 폐를 완전히 부풀린 뒤 입으로 길고 천천히 내쉬어요. 폐포에 갇힌 이산화탄소를 한꺼번에 비워서 심박수가 즉시 내려가요. 111명 대상 RCT에서 명상보다 스트레스·기분 개선 효과가 컸어요. 긴장될 때 한두 번만 해도 좋고, 예방 차원에서 매일 5분 권장';

  @override
  String get planTemplateFocus90Label => '90분 집중';

  @override
  String get planTemplateFocus90Action => '90분 집중 1세션';

  @override
  String get planTemplateFocus90Description =>
      '뇌는 약 90분 주기로 집중력이 오르내려요(울트라디안 사이클). 오전엔 도파민·노르에피네프린이 가장 풍부해 깊은 몰입이 잘 일어나고, 90분이 지나면 자연스럽게 떨어지니 끝나면 10~30분 쉬는 게 다음 사이클에 좋아요. 사이클 중엔 알림·SNS를 끄고 한 가지에만 집중하세요';

  @override
  String get planTemplateSleepEnvLabel => '수면 환경';

  @override
  String get planTemplateSleepEnvAction => '자기 1시간 전 침실 정리';

  @override
  String get planTemplateSleepEnvDescription =>
      '잠들기 1시간 전부터 머리 위 밝은 조명을 끄고 간접 조명으로 바꾸면 멜라토닌이 빨리 분비돼 입면이 빨라져요. 침실 온도는 18~20도가 적정 — 잠들 땐 체온이 살짝 떨어져야 깊은 잠과 REM이 늘어요. 자기 직전 뜨거운 샤워는 오히려 체온을 올려 입면을 늦추니, 잠 1~2시간 전에 끝내세요';

  @override
  String get planTemplateStrength2xLabel => '주 2회 근력운동';

  @override
  String get planTemplateStrength2xAction => '전신 근력운동 1세션';

  @override
  String get planTemplateStrength2xDescription =>
      '근력운동은 주 2회만 해도 근육·근력과 뼈 건강을 지키는 \'최소 효과 용량\'으로, WHO·미국 신체활동 지침이 권장하는 기준이에요. 나이가 들수록 자연히 줄어드는 근육량은 물론 대사·혈당 조절, 자세와 낙상 예방까지 폭넓게 도와요. 스쿼트·힌지(데드리프트)·밀기·당기기 같은 복합 동작 위주로 6~10회 3~4세트, 매주 무게나 횟수를 조금씩 올리세요(점진적 과부하). 같은 부위는 48시간 이상 회복이 필요하니 두 세션은 2~3일 간격을 두고, 충분한 단백질과 수면으로 회복을 채우세요';

  @override
  String get planDayPresetThreeDaysLabel => '주 3일';

  @override
  String get planDayPresetWeekdaysLabel => '평일';

  @override
  String get planDayPresetEveryDayLabel => '매일';

  @override
  String get planDayPresetWeekendLabel => '주말';

  @override
  String get planDayPresetStudyThreeDaysDesc => '첫 주 3회 성공을 먼저 만들기';

  @override
  String get planDayPresetStudyWeekdaysDesc => '공부 흐름을 주중에 묶기';

  @override
  String get planDayPresetStudyEveryDayDesc => '짧게라도 매일 파트너에게 보이기';

  @override
  String get planDayPresetExerciseThreeDaysDesc => '월수금 리듬으로 시작하기';

  @override
  String get planDayPresetExerciseWeekendDesc => '주말에 움직임을 남기기';

  @override
  String get planDayPresetExerciseEveryDayDesc => '짧은 스트레칭처럼 매일 확인받기';

  @override
  String get planDayPresetCustomThreeDaysDesc => '부담을 낮추는 기본값';

  @override
  String get planDayPresetCustomWeekdaysDesc => '주중 루틴으로 고정하기';

  @override
  String get planDayPresetCustomEveryDayDesc => '작은 행동을 매일 남기기';

  @override
  String planStepHeader(int current, int total) {
    return '약속 준비 중 · $current/$total';
  }

  @override
  String get planTellUsActionFirst => '어떤 약속을 할지 알려주세요!';

  @override
  String get planProposalSaved => '계획 제안이 완료되었습니다.\n상대방과 대화해보세요!';

  @override
  String planSaveError(String error) {
    return '저장 중 오류가 발생했습니다: $error';
  }

  @override
  String get focusTimerPickerTitle => '얼마나 집중할까요?';

  @override
  String get focusTimerPickerSubtitle => '타이머가 끝나면 자동으로 \"했어\" 노트가 떠요.';

  @override
  String focusTimerPresetMin(int minutes) {
    return '$minutes분';
  }

  @override
  String focusTimerCustomHint(int min, int max) {
    return '직접 입력 ($min~$max분)';
  }

  @override
  String get focusTimerMinuteUnit => '분';

  @override
  String get focusTimerPickFirst => '시간을 골라주세요';

  @override
  String focusTimerStart(int minutes) {
    return '$minutes분 시작하기';
  }

  @override
  String get focusTimerGiveUpTitle => '타이머를 그만둘까요?';

  @override
  String get focusTimerGiveUpBody => '진행 기록은 따로 남지 않아요. 약속은 미처리 상태로 남아요.';

  @override
  String get focusTimerKeepGoing => '계속하기';

  @override
  String get focusTimerGiveUp => '그만두기';

  @override
  String get focusTimerGiveUpShort => '포기';

  @override
  String focusTimerHeader(int minutes) {
    return '$minutes분 집중';
  }

  @override
  String focusTimerHeaderWithPlan(String title, int minutes) {
    return '$title · $minutes분';
  }

  @override
  String get focusTimerPaused => '잠시 멈춤';

  @override
  String get focusTimerDoneNow => '했어! 지금 끝낼게';

  @override
  String get focusTimerResume => '재개';

  @override
  String get focusTimerPause => '잠시 멈춤';

  @override
  String get actionNoteHintDefault => '실천 소감을 남겨보세요 (선택)';

  @override
  String get planTimeUnset => '시간 미정';

  @override
  String get planDaysEveryday => '매일';

  @override
  String get planDaysWeekdays => '평일';

  @override
  String get planDaysWeekend => '주말';

  @override
  String get planStateActive => '진행 중';

  @override
  String get planStateDraft => '작성 중';

  @override
  String get planStatePending => '수락 대기';

  @override
  String get planStateRejected => '거절됨';

  @override
  String get planStateCompleted => '종료됨';

  @override
  String get planStateStopped => '중단됨';

  @override
  String get planDescriptionTip => 'Tip: \"만약 ~하면, ~한다\" 로 적어보세요';

  @override
  String get planDescriptionExamples =>
      '예) \"퇴근하고 집에 도착하면, 바로 운동복으로 갈아입는다\"\n예) \"아이가 잠들면, 책을 30분 읽는다\"';

  @override
  String get planDescriptionTipFooter => '구체적인 상황을 정하면 실천 확률이 2~3배 높아져요!';

  @override
  String get notifyEditorTitle => '알림 설정';

  @override
  String get notifyEditorSubtitleOn => '똑똑이 살아날 시간을 정해요.';

  @override
  String get notifyEditorSubtitleOff => '알림 없이 기록만 할게요.';

  @override
  String get notifyEditorPromiseTime => '파트너에게 보일 약속 시간';

  @override
  String get notifyEditorDefaultTimeHint =>
      '기본 저녁 9시는 하루가 묻히기 전에 파트너가 확인하기 좋은 시간이에요.';

  @override
  String get notifyEditorPrealert => '알림 미리받기';

  @override
  String get notifyEditorOnTime => '제 시간에';

  @override
  String get notifyEditor5MinBefore => '5분 전';

  @override
  String get notifyEditor10MinBefore => '10분 전';

  @override
  String get notifyEditor30MinBefore => '30분 전';

  @override
  String get notifyEditor1HourBefore => '1시간 전';

  @override
  String get notifyEditorRepeatModeLabel => '반복 방식';

  @override
  String get notifyEditorRepeatDaily => '하루 한 번';

  @override
  String get notifyEditorRepeatHourly => '시간마다';

  @override
  String get notifyEditorIntervalLabel => '반복 간격';

  @override
  String notifyEditorIntervalHours(int count) {
    return '$count시간마다';
  }

  @override
  String get notifyEditorWindowStart => '시작 시각';

  @override
  String get notifyEditorWindowEnd => '종료 시각';

  @override
  String notifyEditorHourlyHint(int interval, int start, int end) {
    return '$start시부터 $end시까지 $interval시간마다 알려드려요.';
  }

  @override
  String planTimeHourlyRange(int start, int end, int interval) {
    return '$start시–$end시 · $interval시간마다';
  }

  @override
  String promiseChipPenaltyTriggered(String description) {
    return '벌칙 발동 확정 — $description';
  }

  @override
  String promiseChipPenaltyImminentOne(String description) {
    return '한 번만 더 실패하면 벌칙 — $description';
  }

  @override
  String promiseChipPenaltyImminent(int count, String description) {
    return '$count번만 더 실패하면 벌칙 — $description';
  }

  @override
  String promiseChipRewardAchieved(String description) {
    return '보상 달성! — $description';
  }

  @override
  String promiseChipRewardImminent(int days, String description) {
    return '보상까지 $days일 더 성공하면 — $description';
  }

  @override
  String promiseChipSafeBoth(int rewardDays, int penaltyBuffer) {
    return '보상까지 $rewardDays일 · 벌칙까지 $penaltyBuffer번 여유';
  }

  @override
  String promiseChipSafeRewardOnly(int days, String description) {
    return '보상까지 $days일 — $description';
  }

  @override
  String promiseChipSafePenaltyOnly(int buffer, String description) {
    return '벌칙까지 $buffer번 여유 — $description';
  }

  @override
  String get promiseSheetTitle => '약속 조건';

  @override
  String promiseSheetSubtitle(int success, int failed, int remaining) {
    return '플랜 종료 시 정산돼요. 현재 성공 $success일 · 실패 $failed일 · 남은 예정 $remaining일.';
  }

  @override
  String get promiseSheetRewardLabel => '보상';

  @override
  String get promiseSheetPenaltyLabel => '벌칙';

  @override
  String promiseSheetRewardTarget(int target, int success) {
    return '$target일 성공하면 달성 — 지금 $success일';
  }

  @override
  String promiseSheetPenaltyImpossible(int target) {
    return '$target일 성공이 필요한데 더 이상 도달할 수 없어요 — 벌칙 발동 확정';
  }

  @override
  String promiseSheetPenaltyJustOne(int target) {
    return '$target일 성공 미만 시 발동 — 한 번도 더 실패할 수 없음';
  }

  @override
  String promiseSheetPenaltyBuffer(int target, int buffer) {
    return '$target일 성공 미만 시 발동 — $buffer번 더 실패해도 안전';
  }

  @override
  String get promiseSheetClose => '닫기';

  @override
  String splashLoginFailed(String error) {
    return '로그인 실패: $error';
  }

  @override
  String get splashLoggingIn => '로그인 중...';

  @override
  String get emailLoginToggleSignUp => '계정이 없으신가요? 회원가입';

  @override
  String get emailLoginToggleLogin => '이미 계정이 있으신가요? 로그인';

  @override
  String get settingsSupport => '지원';

  @override
  String get notificationSettingsNoAlarm => '알림 없음';

  @override
  String notificationSettingsAlarmOff(String timeString) {
    return '알림 꺼짐 ($timeString)';
  }

  @override
  String get notificationSettingsSaveFailed =>
      '알림 설정을 저장하지 못했어요. 이전 설정으로 되돌렸어요.';

  @override
  String get historyCardFeedbackHint => '따뜻한 피드백을 남겨주세요 (선택)';

  @override
  String get historyCardFeedbackButton => '그래';

  @override
  String get historyCardAcknowledgePractice => '실천 인정';

  @override
  String get planSummaryMyDone => '나의 완료';

  @override
  String get planSummaryPartnerVerified => '파트너 확인';

  @override
  String planSummaryCount(int count) {
    return '$count회';
  }

  @override
  String get connectInviteCodeDetectedTitle => '초대 코드 감지';

  @override
  String connectInviteCodeDetectedBody(String code) {
    return '클립보드에서 초대 코드($code)를 발견했습니다.\n붙여넣으시겠습니까?';
  }

  @override
  String get connectCancel => '취소';

  @override
  String get connectPaste => '붙여넣기';

  @override
  String get connectNotice => '알림';

  @override
  String get connectAlreadyConnectedBody =>
      '현재 연결된 파트너가 있어요.\n더 많은 파트너와의 연결은 추후 지원될 예정이에요.';

  @override
  String get connectOk => '확인';

  @override
  String get connectSuccess => '연결되었습니다!';

  @override
  String get allPlansTitleMine => '나의 모든 약속';

  @override
  String get allPlansTitlePartner => '파트너의 모든 약속';

  @override
  String get allPlansEmpty => '등록된 약속이 없어요';

  @override
  String get allPlansDeleteTitle => '약속을 삭제할까요?';

  @override
  String get allPlansDeleteBody => '삭제하면 되돌릴 수 없어요.';

  @override
  String get allPlansDeleted => '약속이 삭제되었습니다.';

  @override
  String allPlansDeleteFailed(String error) {
    return '삭제 실패: $error';
  }

  @override
  String get allPlansDelete => '삭제';

  @override
  String get allPlansCancel => '취소';

  @override
  String get historyErrorUnknown => '알 수 없는 오류가 발생했습니다.';

  @override
  String get historyErrorIndexMissing =>
      '데이터 조회에 필요한 인덱스가 없습니다.\n개발자에게 이 화면을 캡처해서 보내주세요.';

  @override
  String get historyErrorAlreadyDeleted => '이미 삭제된 기록이거나 약속이라\n리액션을 남길 수 없어요.';

  @override
  String get historyErrorTitle => '오류 발생';

  @override
  String get historyErrorCreationLink => '생성 링크:';

  @override
  String get historyOk => '확인';

  @override
  String get historySectionActive => '진행 중인 약속';

  @override
  String get historySectionFinished => '종료된 약속';

  @override
  String get historyToday => '오늘';

  @override
  String get historyYesterday => '어제';

  @override
  String get historyDatePattern => 'M월 d일 (E)';

  @override
  String get historyCardDatePattern => 'M/d (E)';

  @override
  String get historyWeeklyPulseTitle => '이번 주';

  @override
  String get historyWeeklyMeLabel => '나';

  @override
  String get historyWeeklyPartnerLabel => '파트너';

  @override
  String get historyReconcileTitle => '지난 기록 소명하기';

  @override
  String get historyReconcileSubtitle => '이 날의 약속, 사실 어땠나요?';

  @override
  String get historyReconcileHold => '보류할게요';

  @override
  String get usNoticeTitle => '안내';

  @override
  String get usOk => '확인';

  @override
  String usProfileSaveFailed(String error) {
    return '프로필 저장 실패: $error';
  }

  @override
  String get usEditProfile => '프로필 편집';

  @override
  String get usNameLabel => '이름';

  @override
  String get usStatusLabel => '상태 메시지';

  @override
  String get usCancel => '취소';

  @override
  String get usSave => '저장';

  @override
  String get usSeeAll => '전체보기 >';

  @override
  String get usEmptyMine => '아직 등록된 약속이 없어요';

  @override
  String get usEmptyPartner => '파트너가 진행 중인 약속이 없어요';

  @override
  String get usCreatePlanShort => '+ 새 약속 정하기';

  @override
  String get usCreatePlan => '새 약속 정하기';

  @override
  String get usDeletePlanTitle => '약속을 삭제할까요?';

  @override
  String get usDeletePlanBody => '삭제하면 되돌릴 수 없어요.';

  @override
  String get usPlanDeleted => '약속이 삭제되었습니다.';

  @override
  String usDeleteFailed(String error) {
    return '삭제 실패: $error';
  }

  @override
  String get usDelete => '삭제';

  @override
  String get planDetailPracticeHistory => '실천 기록';

  @override
  String planDetailLoadFailed(String error) {
    return '기록을 불러오지 못했어요.\n$error';
  }

  @override
  String get planDetailNoRecords => '아직 기록이 없어요.';

  @override
  String get planDetailNotSavedPlan => '저장된 계획이 아닙니다.';

  @override
  String get planDetailRecordDone => '완료';

  @override
  String get planDetailRecordSkipped => '건너뜀';

  @override
  String get planDetailRecordRested => '휴식';

  @override
  String get planDetailRecordRescued => '실천 인정';

  @override
  String get planDetailPokeSent => '똑똑, 문을 두드렸어요!';

  @override
  String planDetailPokeFailed(String error) {
    return '전송 실패: $error';
  }

  @override
  String get planDetailPokeDoneToday => '오늘의 똑똑 완료';

  @override
  String get planDetailPokeSending => '전송 중...';

  @override
  String get planDetailPokeAsk => '똑똑... 혹시 잊으셨나요?';

  @override
  String get planDetailPokeAlreadyDone => '오늘은 이미 실천했어요';

  @override
  String get planDetailDayMon => '월';

  @override
  String get planDetailDayTue => '화';

  @override
  String get planDetailDayWed => '수';

  @override
  String get planDetailDayThu => '목';

  @override
  String get planDetailDayFri => '금';

  @override
  String get planDetailDaySat => '토';

  @override
  String get planDetailDaySun => '일';

  @override
  String get planDetailEveryDay => '매일';

  @override
  String get planDetailTimeUnset => '시간 미정';

  @override
  String get planDetailNotificationSaved => '알림 설정이 저장되었어요.';

  @override
  String get planDetailNotificationSaveFailed =>
      '알림 설정을 저장하지 못했어요. 이전 설정으로 되돌렸어요.';

  @override
  String get planDetailSave => '저장';

  @override
  String get planDetailStopTitle => '약속을 그만할까요?';

  @override
  String get planDetailStopBody => '그만하더라도 지금까지의 실천 기록은 유지돼요.';

  @override
  String get planDetailCancel => '취소';

  @override
  String get planDetailStopped => '약속이 중단되었습니다.';

  @override
  String planDetailActionFailed(String error) {
    return '처리 실패: $error';
  }

  @override
  String get planDetailStop => '그만하기';

  @override
  String get planDetailRestartTitle => '같은 약속으로 다시 시작할까요?';

  @override
  String get planDetailRestartBody => '이전 약속 내용을 그대로 가져와요.\n시작 전에 수정할 수 있어요.';

  @override
  String get planDetailRestart => '다시 시작';

  @override
  String get planDetailReplaceBody =>
      '현재 약속은 중단 처리되고\n새로운 약속 만들기로 이동해요.\n기존 기록은 안전하게 보관돼요.';

  @override
  String get planDetailReport => '실천 리포트';

  @override
  String get planDetailReportPeriod => '총 기간';

  @override
  String planDetailReportDays(int count) {
    return '$count일';
  }

  @override
  String get planDetailReportCompleted => '완료 횟수';

  @override
  String planDetailReportCount(int count) {
    return '$count회';
  }

  @override
  String get planDetailReportRate => '달성률';

  @override
  String get planDetailRestartWithScheduleTitle => '새 스케줄로 다시 시작할까요?';

  @override
  String get nowFocusNoteDoneJustNow => '집중해서 완료했어요!';

  @override
  String nowFocusNoteDoneFor(String duration) {
    return '$duration 동안 집중해서 완료했어요!';
  }

  @override
  String nowFocusDurationMinSec(int minutes, int seconds) {
    return '$minutes분 $seconds초';
  }

  @override
  String nowFocusDurationMin(int minutes) {
    return '$minutes분';
  }

  @override
  String nowFocusDurationSec(int seconds) {
    return '$seconds초';
  }

  @override
  String get nowTodayPromiseFallback => '오늘 약속';

  @override
  String get nowSkipDialogTitle => '오늘은 패스할까요?';

  @override
  String nowSkipDialogBody(String title) {
    return '$title 약속을 오늘은 건너뜀으로 정리합니다.';
  }

  @override
  String get nowCancel => '취소';

  @override
  String get nowSkipToday => '오늘은 패스';

  @override
  String get nowSkippedSnackbar => '오늘 약속을 건너뛰었어요.';

  @override
  String get nowApproveCheering => '시작을 응원해요!';

  @override
  String get nowApproveFailed => '승인에 실패했어요.';

  @override
  String get nowVerifyDone => '실천을 확인했어요!';

  @override
  String get nowVerifyFailed => '확인 처리에 실패했어요.';

  @override
  String get nowRejectDialogTitle => '조금 더 조율해볼까요?';

  @override
  String get nowRejectLessFrequent => '빈도를 조금 줄여보자';

  @override
  String get nowRejectDifferentTime => '다른 시간대가 좋을 것 같아';

  @override
  String get nowRejectCustom => '직접 입력하기';

  @override
  String get nowRejectRequested => '조율을 요청했어요';

  @override
  String get nowRejectCustomDialogTitle => '어떤 점을 조율할까요?';

  @override
  String get nowRejectCustomHint => '예: 주 3회로 시작해보는 건 어때?';

  @override
  String get nowSend => '보내기';

  @override
  String get nowCheerExcited => '열정적인 응원을 보냈어요! 🔥';

  @override
  String get nowCheerLove => '사랑을 담아 응원했어요! ❤️';

  @override
  String get nowCheerProud => '멋지다고 전했어요! 👍';

  @override
  String get nowCheerStrength => '힘내라고 응원했어요! 💪';

  @override
  String get nowCheerFailed => '응원 전송에 실패했어요.';

  @override
  String get nowPokeNoActivityMessage => '똑똑! 약속을 기다리는 사람이 있어요. 오늘 약속을 만들어볼까요?';

  @override
  String get nowPokeSent => '똑똑 신호를 보냈어요.';

  @override
  String get nowPokeFailed => '똑똑 전송에 실패했어요.';

  @override
  String get nowPokeAgainMessage => '똑똑! 파트너가 기다리고 있어요. 지금 약속을 정리해볼까요?';

  @override
  String get nowPokeAgainSent => '똑똑, 약속을 다시 당겼어요.';

  @override
  String get nowSettlementSaved => '4주 정산을 남겼어요.';

  @override
  String get nowExitDialogTitle => '이번 4주를 여기서 마무리할까요?';

  @override
  String get nowExitReasonWeakPoke => '똑똑 압박이 약했어요';

  @override
  String get nowExitReasonTooBig => '목표가 너무 컸어요';

  @override
  String get nowExitReasonPartnerBurden => '파트너 확인이 부담됐어요';

  @override
  String get nowExitReasonCustomLabel => '직접 입력';

  @override
  String get nowExitReasonCustomHint => '마무리하는 이유를 짧게 남기기 (선택)';

  @override
  String get nowExitReasonNoCustom => '직접 사유 없음';

  @override
  String get nowExitSubmit => '남기기';

  @override
  String get nowRestPassTitle => '휴식권 사용';

  @override
  String get nowRestPassBody => '이번 주 1회 휴식권을 사용합니다.\n스트릭이 유지됩니다.';

  @override
  String get nowRestPassConfirm => '사용하기';

  @override
  String get nowRestPassUsed => '오늘은 편히 쉬세요. 스트릭은 유지됩니다!';

  @override
  String get nowRestPassAlreadyUsed => '이번 주 휴식권을 이미 사용했어요.';

  @override
  String get nowRestPassError => '오류가 발생했습니다.';

  @override
  String get nowRescuedSnackbar => '실천을 인정해줬어요! 스트릭이 유지됩니다.';

  @override
  String get nowRescueFailed => '실천 인정에 실패했어요.';

  @override
  String get nowPromiseAccepted => '약속을 수락했어요!';

  @override
  String get nowPromiseDeclined => '약속을 거절했어요.';

  @override
  String get nowPromiseResponseFailed => '약속 응답에 실패했어요.';

  @override
  String get nowPromiseProposed => '약속을 제안했어요!';

  @override
  String get nowPromiseProposeFailed => '약속 제안에 실패했어요.';

  @override
  String nowTimeMinBeforeAlert(int minutes) {
    return '$minutes분 전 알림';
  }

  @override
  String nowTimeHourBeforeAlert(int hours) {
    return '$hours시간 전 알림';
  }

  @override
  String nowTimeMinAfterAlert(int minutes) {
    return '$minutes분 후 알림';
  }

  @override
  String nowTimeHourAfterAlert(int hours) {
    return '$hours시간 후 알림';
  }

  @override
  String get nowKeepFlowing => '대단해요! 이 흐름을 이어가봐요';

  @override
  String get nowGuideWhen => '\"언제 할지\" 정하면 실천 확률이 올라가요';

  @override
  String get nowGuideSmallStart => '작게 시작해도 괜찮아요. 꾸준함이 힘이에요';

  @override
  String get nowGuideBetterToday => '어제보다 나은 오늘이면 충분해요';

  @override
  String get nowErrorTitle => '오류 발생';

  @override
  String get nowErrorCreationLink => '생성 링크:';

  @override
  String get nowOk => '확인';

  @override
  String get nowRetryLater => '잠시 후 다시 시도해주세요';

  @override
  String get nowPartnerActionFallback => '파트너의 실천';

  @override
  String get nowActionNoteHint => '따뜻한 피드백을 남겨주세요 (선택)';

  @override
  String get nowVerifyAndSend => '확인하고 보내기';

  @override
  String nowStreakCount(int count) {
    return '$count회 연속 달성!';
  }

  @override
  String get nowHeaderAdjustNeeded => '조율이 필요해요';

  @override
  String get nowHeaderPromiseProposed => '약속 제안이 도착했어요';

  @override
  String get nowHeaderPromiseSettled => '약속 결과가 나왔어요';

  @override
  String get nowPromiseAckButton => '결과 확인하기';

  @override
  String get nowPromiseAckWithNote => '한마디 남기고 닫기';

  @override
  String get nowPromiseAckDialogTitle => '약속 결과 확인';

  @override
  String get nowPromiseAckDialogHint => '상대에게 짧게 한마디 남겨주세요 (선택)';

  @override
  String get nowPromiseAckDialogConfirm => '확인했어';

  @override
  String get nowPromiseAckSnackbar => '결과를 확인했어요';

  @override
  String get nowPromiseAckFailed => '결과 확인에 실패했어요';

  @override
  String get planDetailViewList => '목록';

  @override
  String get planDetailViewCalendar => '캘린더';

  @override
  String get planDetailViewGraph => '그래프';

  @override
  String get planDetailLegendDone => '실천';

  @override
  String get planDetailLegendRested => '휴식';

  @override
  String get planDetailLegendRescued => '인정';

  @override
  String get planDetailLegendSkipped => '건너뜀';

  @override
  String get planDetailLegendMissed => '놓침';

  @override
  String get planDetailLegendScheduled => '예정';

  @override
  String planDetailWeekLabel(int week) {
    return '$week주차';
  }

  @override
  String get planDetailGraphCompletionRate => '주별 실천율';

  @override
  String get planDetailGraphEmpty => '표시할 기록이 없어요.';

  @override
  String get planDetailProgressTitle => '진행 현황';

  @override
  String get planDetailProgressSuccessRate => '성공률';

  @override
  String planDetailProgressFractionDays(int done, int total) {
    return '$done/$total일';
  }

  @override
  String get planDetailProgressStreakLabel => '연속 달성';

  @override
  String get planDetailProgressDoneLabel => '실천';

  @override
  String get planDetailProgressRemainingLabel => '남음';

  @override
  String get planDetailProgressMissedLabel => '놓침';

  @override
  String planDetailProgressDayUnit(int n) {
    return '$n일';
  }

  @override
  String planDetailProgressCountUnit(int n) {
    return '$n회';
  }

  @override
  String get planDetailProgressNoVerdictYet => '아직 결과 나온 날이 없어요';

  @override
  String get planDetailPromiseProgressTitle => '약속 진행률';

  @override
  String get planDetailPromiseRewardLabel => '🏆 보상';

  @override
  String get planDetailPromisePenaltyLabel => '⚡ 벌칙';

  @override
  String planDetailPromiseRewardNeed(int days) {
    return '보상까지 $days일 더 필요';
  }

  @override
  String get planDetailPromiseRewardAchieved => '🎉 보상 달성!';

  @override
  String planDetailPromisePenaltyBuffer(int buffer) {
    return '벌칙까지 $buffer번 여유';
  }

  @override
  String get planDetailPromisePenaltyImminent => '이번에 또 놓치면 벌칙';

  @override
  String get planDetailPromisePenaltyTriggered => '⚡ 벌칙 발동 확정';

  @override
  String get planDetailMoreMenu => '더보기';

  @override
  String get planDetailMenuRestartCompleted => '이 약속으로 다시 만들기';

  @override
  String get planDetailMenuRestartActive => '새 스케줄로 다시 시작';

  @override
  String get planDetailMenuStop => '약속 중단';

  @override
  String planDetailPromiseSuccessFailBreakdown(int success, int fail) {
    return '성공 $success일 · 실패 $fail일';
  }

  @override
  String get nowHeaderSettlementNeeded => '4주 정산이 필요해요';

  @override
  String get nowHeaderSettlementSub => '똑똑이 실제로 약속을 당겼는지 확인하고 다음 4주를 정해요.';

  @override
  String get nowMetricCompleted => '완료';

  @override
  String get nowMetricPartnerReact => '파트너 반응';

  @override
  String get nowMetricMissed => '놓친 날';

  @override
  String nowMetricDaysSuffix(int count) {
    return '$count일';
  }

  @override
  String nowMetricCountSuffix(int count) {
    return '$count회';
  }

  @override
  String get nowSettlementWinMessage =>
      '약속한 목표를 채웠어요. 잘하셨어요! 다음 4주를 이어갈지 정할 차례예요.';

  @override
  String get nowSettlementLoseMessage =>
      '이번엔 목표까지 닿지 못했지만, 함께한 4주는 그대로 남아요. 다음 4주를 어떻게 바꿔볼지 정해요.';

  @override
  String get nowSettlementNeutralMessage =>
      '4주를 끝까지 함께했어요. 이제 다음 4주를 이어갈지 정할 차례예요.';

  @override
  String nowRewardCondition(int days, String description) {
    return '$days일 성공 시: $description';
  }

  @override
  String nowPenaltyCondition(int days, String description) {
    return '$days일 실패 시: $description';
  }

  @override
  String nowPromiseResult(int success, int fail) {
    return '성공 $success일 / 실패 $fail일';
  }

  @override
  String get nowAchieved => '달성!';

  @override
  String get nowTriggered => '발동!';

  @override
  String get nowNotMet => '미달';

  @override
  String get nowDecline => '거절';

  @override
  String get nowAccept => '수락';

  @override
  String get nowContinueNext4Weeks => '다음 4주 시작하기';

  @override
  String get nowStopHere => '이번 4주는 여기서 마무리하기';

  @override
  String get nowModify => '수정하기';

  @override
  String get nowStartFocusTimer => '지금 할게! (집중 타이머)';

  @override
  String get nowRestToday => '오늘은 쉬어갈게요 (휴식권)';

  @override
  String get nowMissedPlanFallback => '지나간 약속';

  @override
  String get nowVerifyingDeadline => '확인 대기 · 응원 필요';

  @override
  String get nowHeaderTodayAllDone => '오늘 약속을 다 지켰어요';

  @override
  String get nowHeaderConfirmAndPull => '확인하고 응원할 차례';

  @override
  String get nowHeaderWaiting => '기다리는 중';

  @override
  String get nowHeaderWaitingAccept => '약속 수락을 기다리는 중';

  @override
  String get nowHeaderPromiseResult => '약속 결과가 나왔어요';

  @override
  String get nowAdjust => '조율하기';

  @override
  String get nowApprove => '승인하기';

  @override
  String get nowPartnerNoNewPlanGuide =>
      '상대방이 아직 새로운 약속을 만들지 않았어요. 약속이 묻히기 전에 똑똑으로 불러볼까요?';

  @override
  String get nowKnockMakePlan => '똑똑! 약속 만들라고 하기';

  @override
  String nowPartnerMissedPokeBody(String name) {
    return '$name님의 약속이 놓친 약속으로 남았어요. 똑똑으로 다시 당겨주세요.';
  }

  @override
  String nowPartnerQuietPokeBody(String name) {
    return '$name님의 약속이 아직 조용해요. 묻히기 전에 똑똑으로 당겨주세요.';
  }

  @override
  String get nowKnockPull => '똑똑! 당기기';

  @override
  String get nowRescueYesterday => '어제 실천 인정해주기';

  @override
  String get nowVerifyAndCheer => '확인하고 응원하기';

  @override
  String get nowMakePromise => '약속 걸기';

  @override
  String get nowPartnerFallback2 => '파트너';

  @override
  String nowPartnerAllDone(String name) {
    return '$name님이 오늘 약속을 다 지켰어요.';
  }

  @override
  String get nowQuickCheckHelp => '짧게 확인해주면 내일도 이어가기 쉬워요.';

  @override
  String nowLastAction(String title) {
    return '마지막 실천: $title';
  }

  @override
  String nowRewardLine(int days, String description) {
    return '🏆 $days일 성공 시: $description';
  }

  @override
  String nowPenaltyLine(int days, String description) {
    return '⚡ $days일 실패 시: $description';
  }

  @override
  String nowResultLine(int success, int fail) {
    return '결과: 성공 $success일 / 실패 $fail일';
  }

  @override
  String get nowWaitingApproval => '수락 대기 중...';

  @override
  String get nowRewardAchievedTitle => '🎉 보상 달성!';

  @override
  String get nowPenaltyTriggeredTitle => '⚡ 벌칙 발동!';

  @override
  String get nowBothTitle => '🎉 보상 달성! + ⚡ 벌칙 발동!';

  @override
  String get nowConditionNotMet => '조건 미달';

  @override
  String nowTotalDaysOnly(int days) {
    return '총 $days일짜리 약속이에요';
  }

  @override
  String nowTotalDaysScheduled(int days, int scheduled) {
    return '총 $days일짜리 약속 · 실천 예정 $scheduled일';
  }

  @override
  String get nowMakePromiseTitle => '약속 걸기';

  @override
  String get nowMakePromiseSubtitle => '상대가 수락하면 약속이 시작돼요';

  @override
  String nowProgressLine(int success, int failed, int remaining) {
    return '현재 성공 $success일 · 실패 $failed일 · 남은 예정 $remaining일';
  }

  @override
  String nowMaxLimitsLine(int reward, int penalty) {
    return '보상은 최대 $reward일, 벌칙은 최대 $penalty일까지 정할 수 있어요.';
  }

  @override
  String get nowRewardTitle => '🏆 보상 (당근)';

  @override
  String get nowRewardHint => '예: 치킨 사주기, 맛집 가기';

  @override
  String get nowRewardTargetLabel => '성공 목표';

  @override
  String get nowPenaltyTitle => '⚡ 벌칙 (채찍)';

  @override
  String get nowPenaltyHint => '예: 설거지 일주일, 커피 쏘기';

  @override
  String get nowPenaltyTargetLabel => '실패 한도';

  @override
  String get nowProposePromise => '약속 제안하기';

  @override
  String nowDaysSuffix(int count) {
    return '$count일';
  }

  @override
  String nowMaxDaysLabel(int days) {
    return '최대 $days일';
  }

  @override
  String get nowPokeReceived => '파트너가 똑똑을 보냈어요';

  @override
  String nowPokeReceivedFromName(String name) {
    return '$name님이 똑똑을 보냈어요';
  }

  @override
  String get nowYesterday => '어제';

  @override
  String get nowNoteDateToday => '오늘';

  @override
  String get connectErrorSelfCode => '본인의 초대 코드는 사용할 수 없습니다.';

  @override
  String get connectErrorFailed => '코드가 올바르지 않거나 연결에 실패했습니다.';

  @override
  String get connectErrorDisconnectFailed => '연결을 해제하지 못했어요. 다시 시도해 주세요.';

  @override
  String get accountLinkErrorAlreadyInUse => '이 계정은 이미 다른 사용자와 연결되어 있습니다.';

  @override
  String get accountLinkErrorInvalidCredential => '유효하지 않은 인증 정보입니다.';

  @override
  String get accountLinkErrorNotAllowed => '허용되지 않은 작업입니다.';

  @override
  String get accountLinkErrorGeneric => '계정 연동 중 오류가 발생했습니다.';

  @override
  String get planCreateErrorNoUser => '사용자 정보를 찾을 수 없어요. 다시 로그인해 주세요.';
}
