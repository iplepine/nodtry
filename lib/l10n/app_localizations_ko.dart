// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '둘운완';

  @override
  String get splashTagline => '둘이 보면, 진짜 하게 돼요.';

  @override
  String get loginWithGoogle => 'Google 계정으로 계속하기';

  @override
  String get loginWithApple => 'Apple로 계속하기';

  @override
  String get loginGuest => '로그인 없이 시작하기';

  @override
  String get privacyMessage => '서로 동의해야 연결되고, 인증샷은 짝꿍만 봐요.';

  @override
  String get connectHeadline => '짝꿍을 초대해요';

  @override
  String get connectSubtitle => '코드를 보내면 서로의 운동 약속을 봐줄 수 있어요.';

  @override
  String get enterInviteCode => '짝꿍한테 받은 코드 입력';

  @override
  String get startSolo => '나중에 연결할게요';

  @override
  String get codeCopied => '코드가 복사되었어요';

  @override
  String get enterCodeBelow => '아래에 코드를 입력해 주세요';

  @override
  String get sendConnectionRequest => '짝꿍 연결하기';

  @override
  String get homeDidIt => '했어';

  @override
  String get homeReceivedMessage => '짝꿍 소식이 왔어요';

  @override
  String get homeChecked => '인정';

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
  String get usYouTitle => '짝꿍';

  @override
  String get usHeroSubtitle => '서로의 운동 약속을 봐주는 사이';

  @override
  String get usCheerTooltip => '응원하기';

  @override
  String get usProfileEdit => '편집';

  @override
  String get usStatusMessagePlaceholder => '상태 메시지 설정';

  @override
  String get usMyInviteCode => '내 초대 코드';

  @override
  String get usGuestWarningMessage => '휴대폰을 바꾸거나 앱/데이터를 삭제하면 기록을 잃을 수 있어요.';

  @override
  String get usGuestWarningAction => '계정 연결하고 기록 지키기';

  @override
  String get usLoadError => '연결 정보를 불러오지 못했어요.';

  @override
  String get usNoInviteCode => '코드 없음';

  @override
  String get usUnknownUser => '짝꿍';

  @override
  String get usDisconnectDialogTitle => '연결 끊기';

  @override
  String usDisconnectDialogContent(String name) {
    return '$name하고 짝꿍 연결을 끊을까요?';
  }

  @override
  String get usDisconnectConfirm => '끊기';

  @override
  String get usDisconnectSuccess => '짝꿍 연결을 끊었어요.';

  @override
  String get usDisconnectError => '연결을 끊지 못했어요. 다시 시도해 주세요.';

  @override
  String get usDisconnectTooltip => '연결 끊기';

  @override
  String get usCropImageTitle => '프로필 사진 자르기';

  @override
  String get cancel => '취소';

  @override
  String get usProfileEditImageLabel => '프로필 사진 변경';

  @override
  String get usAddConnectionLabel => '짝꿍 연결하기';

  @override
  String get usBadgeMutual => '함께하는 중';

  @override
  String get usEmptyMatesTitle => '아직 짝꿍이 없어요';

  @override
  String get usEmptyMatesSubtitle => '짝꿍을 초대하고 서로의 운동 약속을 봐줘요';

  @override
  String get nowNoPlan => '아직 운동 약속이 없어요';

  @override
  String get nowCreatePlan => '+ 운동 약속 걸기';

  @override
  String get nowQuietRest => '오늘은 쉬는 날이에요';

  @override
  String get nowNoPlanSubtitle => '운동 하나만 정해서 약속을 걸어 봐요';

  @override
  String get nowTodayDone => '오늘 약속은 다 지켰어요 🙌';

  @override
  String nowTodayAllDone(int count) {
    return '오늘 약속 $count개 다 지켰어요 🙌';
  }

  @override
  String nowPartnerProposed(String name) {
    return '$name의 새 약속이 왔어요';
  }

  @override
  String get nowPartnerAdjusting => '짝꿍이 약속을 조금 바꿨어요';

  @override
  String get nowActionSkipToday => '오늘은 패스할게';

  @override
  String get nowDeferMenuTooltip => '미루기';

  @override
  String get nowDeferLaterTitle => '잠시 후에 할게';

  @override
  String get nowDeferLaterSubtitle => '다음 약속을 먼저 보여 드리고, 잠시 후 다시 알려 드릴게요';

  @override
  String get nowSkipTodayTitle => '오늘은 패스할게';

  @override
  String get nowSkipTodaySubtitle => '놓친 날로 남아요 (연속 기록이 끊길 수 있어요)';

  @override
  String get nowDeferRestSubtitle => '휴식권을 써요 — 연속 기록은 그대로예요';

  @override
  String get nowSkipTodayDone => '오늘은 넘어갔어요';

  @override
  String get nowDeferLaterDone => '잠시 후에 다시 알려 드릴게요';

  @override
  String get nowDeferReminderTitle => '다시 알려 드려요';

  @override
  String get nowDeferReminderBody => '잠시 후에 하기로 한 약속이 있어요';

  @override
  String get nowAddMorePlan => '운동 약속 하나 더 걸어 볼까요?';

  @override
  String get planWhatToPromise => '어떤 운동을 약속할까요?';

  @override
  String get planPromiseHint => '지킬 수 있을 것 같은 정도면 좋아요';

  @override
  String get planActionHint => '예) 헬스장 가서 30분, 저녁 먹고 만 보 걷기';

  @override
  String get planDescriptionHint => '예: 집에서 스쿼트랑 스트레칭, 헬스장 가서 하체 운동...';

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
  String get developerScreenConnectDesc => '짝꿍 연결 화면';

  @override
  String get developerScreenHomeDesc => '지금/기록/우리 탭';

  @override
  String get developerScreenSettingsDesc => '언어 및 테마 설정';

  @override
  String get developerScreenActionSelection => '행동 선택';

  @override
  String get developerScreenActionSelectionDesc => 'Screen 1: 행동 선택';

  @override
  String get settingsDeveloper => '개발자 메뉴';

  @override
  String get usLinkEmailAction => '이메일로 연결하기';

  @override
  String get usLinkEmailTitle => '이메일 계정 연결';

  @override
  String get usLinkEmailContent => '로그인에 쓸 이메일과 비밀번호를 입력해 주세요.';

  @override
  String get usEmailLabel => '이메일';

  @override
  String get usPasswordLabel => '비밀번호';

  @override
  String get usLinkConfirm => '연결';

  @override
  String headerWithPartner(String name) {
    return '$name하고 함께하는 중';
  }

  @override
  String get usLinkEmailSuccess => '이메일 계정을 연결했어요!';

  @override
  String get historyPartnerVerified => '짝꿍이 인정했어요';

  @override
  String get historyMeVerified => '내가 인정했어요';

  @override
  String get frequencyEveryday => '매일';

  @override
  String get usMyPlanTitle => '내 약속';

  @override
  String usPartnerPlanTitle(String name) {
    return '$name의 약속';
  }

  @override
  String get settingsDeveloperDesc => '디버그 메뉴';

  @override
  String get settingsAccount => '계정 관리';

  @override
  String get settingsLogout => '로그아웃';

  @override
  String get settingsLogoutDesc => '지금 계정에서 로그아웃해요';

  @override
  String get settingsLogoutDialogTitle => '로그아웃';

  @override
  String get settingsLogoutDialogContent => '로그아웃할까요?';

  @override
  String get settingsLogoutConfirm => '로그아웃';

  @override
  String get settingsDeleteAccount => '회원 탈퇴';

  @override
  String get settingsDeleteAccountDesc => '계정과 모든 기록을 영구적으로 지워요';

  @override
  String get settingsDeleteAccountDialogTitle => '회원 탈퇴';

  @override
  String get settingsDeleteAccountDialogContent =>
      '정말 탈퇴할까요? 계정과 기록, 인증샷이 모두 지워지고 되돌릴 수 없어요. 본인 확인을 위해 한 번 더 로그인할 수 있어요.';

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
  String get passwordHint => '비밀번호를 입력해 주세요';

  @override
  String get emailHint => '이메일을 입력해 주세요';

  @override
  String get invalidEmail => '이메일 형식이 올바르지 않아요';

  @override
  String get weakPassword => '비밀번호는 6자 이상이어야 해요';

  @override
  String get userNotFound => '가입되지 않은 이메일이에요.';

  @override
  String get settingsAccountDeletedSuccess => '계정을 삭제했어요';

  @override
  String get settingsDeleteAccountFailed => '계정을 삭제하지 못했어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get settingsDeleteAccountReauthCancelled =>
      '다시 로그인해야 탈퇴할 수 있어요. 아무것도 지워지지 않았어요.';

  @override
  String get settingsDeleteAccountWrongPassword => '비밀번호가 맞지 않아요. 다시 시도해 주세요.';

  @override
  String get settingsDeleteAccountPasswordTitle => '비밀번호 확인';

  @override
  String get settingsDeleteAccountPasswordHint => '비밀번호';

  @override
  String get reconcileTookRest => '쉬어갔어요';

  @override
  String get timeChipPassed => '지나갔어요';

  @override
  String get nowStatusActuallyDone => '했어';

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
  String get comfortingFuture => '오늘 하루도 수고했어요';

  @override
  String get comfortingLate => '늦어도 괜찮아요';

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
  String get settingsCoffeeSubtitle => '따뜻한 커피 한 잔이 큰 힘이 돼요!';

  @override
  String get settingsCoffeePurchasing => '결제 처리 중...';

  @override
  String get settingsStoreUnavailable => '스토어와 연결할 수 없어요. (설정 확인 필요)';

  @override
  String get planMine => '약속 한 줄';

  @override
  String get planClearAction => '비우기';

  @override
  String get planPartnerPreviewWithout =>
      '혼자 시작해도 돼요. 짝꿍과 연결하면 서로 인정해 주고 똑똑을 주고받아요.';

  @override
  String get planConnectPartner => '짝꿍 연결하기';

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
  String get planDayPresetThreeDaysLabel => '주 3일';

  @override
  String get planDayPresetWeekdaysLabel => '평일';

  @override
  String get planDayPresetEveryDayLabel => '매일';

  @override
  String get planDayPresetWeekendLabel => '주말';

  @override
  String get planTellUsActionFirst => '어떤 운동을 할지 알려 주세요!';

  @override
  String get planSaveError => '약속을 저장하지 못했어요. 다시 시도해 주세요.';

  @override
  String get planCreateTitle => '운동 약속 걸기';

  @override
  String get planEditTitle => '약속 수정하기';

  @override
  String planCreateHeaderWithPartner(String name) {
    return '$name한테 어떤 운동을 약속할까요?';
  }

  @override
  String get planCreateDaysTitle => '어느 요일에 할까요?';

  @override
  String get planCreateDaysRequired => '하루 이상 골라 주세요';

  @override
  String planCreateDaysFromPartner(String name) {
    return '$name 운동 요일에 맞춰 뒀어요';
  }

  @override
  String get planCreateDeadlineTitle => '몇 시까지 할까요?';

  @override
  String get planCreateDeadlineHint => '이 시각에 알림으로 챙겨 드려요';

  @override
  String get planCreateDeadlineRequired => '마감 시각을 골라 주세요';

  @override
  String get planDeadlineMorning => '아침 7시';

  @override
  String get planDeadlineNoon => '점심 12시';

  @override
  String get planDeadlineEvening => '저녁 7시';

  @override
  String get planDeadlineNight => '밤 9시';

  @override
  String get planDeadlineLateNight => '밤 10시';

  @override
  String get planDeadlineCustom => '직접';

  @override
  String get planCreateMemoToggle => '메모 남기기 (선택)';

  @override
  String planCreatePartnerNotice(String name) {
    return '못 하면 $name한테 알려져요';
  }

  @override
  String planCreateCtaWithPartner(String name, String nameWithParticle) {
    return '🤙 $nameWithParticle 손가락 걸기';
  }

  @override
  String get planCreateCtaSolo => '약속 시작하기';

  @override
  String get planEditCta => '저장하기';

  @override
  String planSavedWithPartner(String name) {
    return '$name한테 운동 약속을 걸었어요 🤙';
  }

  @override
  String get planSavedSolo => '운동 약속을 시작했어요 💪';

  @override
  String get planEditSaved => '약속을 수정했어요';

  @override
  String get planDayPresetTwoDaysLabel => '주 2일';

  @override
  String get workoutTypeGymLabel => '헬스';

  @override
  String get workoutTypeGymAction => '헬스장 가서 운동하기';

  @override
  String get workoutTypeRunningLabel => '러닝';

  @override
  String get workoutTypeRunningAction => '30분 달리기';

  @override
  String get workoutTypeHomeTrainingLabel => '홈트';

  @override
  String get workoutTypeHomeTrainingAction => '홈트 20분 하기';

  @override
  String get workoutTypeWalkingLabel => '걷기';

  @override
  String get workoutTypeWalkingAction => '30분 걷기';

  @override
  String get workoutTypePilatesLabel => '필라테스';

  @override
  String get workoutTypePilatesAction => '필라테스 수업 가기';

  @override
  String get workoutTypeYogaLabel => '요가';

  @override
  String get workoutTypeYogaAction => '요가 30분 하기';

  @override
  String get workoutTypeStretchingLabel => '스트레칭';

  @override
  String get workoutTypeStretchingAction => '자기 전 10분 스트레칭';

  @override
  String get workoutTypeSwimmingLabel => '수영';

  @override
  String get workoutTypeSwimmingAction => '수영 다녀오기';

  @override
  String get workoutTypeClimbingLabel => '클라이밍';

  @override
  String get workoutTypeClimbingAction => '클라이밍 다녀오기';

  @override
  String get workoutTypeCyclingLabel => '자전거';

  @override
  String get workoutTypeCyclingAction => '자전거 40분 타기';

  @override
  String get workoutTypeHikingLabel => '등산';

  @override
  String get workoutTypeHikingAction => '등산 다녀오기';

  @override
  String get workoutTypeStrengthLabel => '근력 운동';

  @override
  String get workoutTypeStrengthAction => '근력 운동 30분 하기';

  @override
  String get workoutTypeDietLabel => '식단·야식 참기';

  @override
  String get workoutTypeDietAction => '야식 참기';

  @override
  String get workoutTypeDietName => '식단';

  @override
  String get workoutTypeOtherLabel => '직접 입력';

  @override
  String get workoutTypeOtherName => '운동';

  @override
  String get workoutTypeCyclingName => '자전거 타기';

  @override
  String get workoutTypeStrengthName => '근력 운동';

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
  String get focusTimerPickFirst => '시간을 골라 주세요';

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
  String get actionNoteHintDefault => '어땠는지 한마디 (선택)';

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
  String get planCardMenuTooltip => '약속 메뉴';

  @override
  String get planCardEdit => '수정';

  @override
  String get planCardDelete => '삭제';

  @override
  String get notifyEditorTitle => '알림 설정';

  @override
  String get notifyEditorSubtitleOn => '약속 시간에 맞춰 알려 드려요.';

  @override
  String get notifyEditorSubtitleOff => '알림 없이 기록만 할게요.';

  @override
  String get notifyEditorPromiseTime => '짝꿍한테 보이는 약속 시간';

  @override
  String get notifyEditorDefaultTimeHint =>
      '기본값 밤 9시는 하루가 끝나기 전에 서로 인정해 주기 좋은 시간이에요.';

  @override
  String get notifyEditorOffWarningTitle => '알림을 끌까요?';

  @override
  String notifyEditorOffWarningBody(String name) {
    return '알림을 끄면 마감도 없어져서, 기록이 없어도 $name한테 알려지지 않아요.';
  }

  @override
  String get notifyEditorOffWarningConfirm => '끄기';

  @override
  String get notifyEditorPrealert => '미리 알림';

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
    return '$start시부터 $end시까지 $interval시간마다 알려 드려요.';
  }

  @override
  String planTimeHourlyRange(int start, int end, int interval) {
    return '$start시–$end시 · $interval시간마다';
  }

  @override
  String promiseChipPenaltyTriggered(String description) {
    return '못 지켰어요 — $description';
  }

  @override
  String promiseChipPenaltyImminentOne(String description) {
    return '한 번 더 놓치면 — $description';
  }

  @override
  String promiseChipRewardAchieved(String description) {
    return '지켰어요! — $description';
  }

  @override
  String promiseChipRewardImminent(int days, String description) {
    return '$days일만 더 지키면 — $description';
  }

  @override
  String promiseChipSafeBoth(int rewardDays, int penaltyBuffer) {
    return '성공까지 $rewardDays일 · $penaltyBuffer번 더 놓치면 내기';
  }

  @override
  String promiseChipSafeRewardOnly(int days, String description) {
    return '성공까지 $days일 — $description';
  }

  @override
  String promiseChipSafePenaltyOnly(int buffer, String description) {
    return '$buffer번 더 놓치면 — $description';
  }

  @override
  String get promiseSheetTitle => '내기';

  @override
  String promiseSheetSubtitle(int success, int failed, int remaining) {
    return '약속이 끝나면 결과가 나와요. 지금까지 지킨 날 $success일 · 놓친 날 $failed일 · 남은 날 $remaining일.';
  }

  @override
  String get promiseSheetRewardLabel => '지키면';

  @override
  String get promiseSheetPenaltyLabel => '못 지키면';

  @override
  String promiseSheetRewardTarget(int target, int success) {
    return '$target일 지키면 성공 — 지금 $success일';
  }

  @override
  String promiseSheetPenaltyImpossible(int target) {
    return '$target일 놓쳤어요 — 내기 확정';
  }

  @override
  String promiseSheetPenaltyJustOne(int target) {
    return '놓친 날이 $target일이 되면 확정 — 한 번만 더 놓쳐도 내기예요';
  }

  @override
  String promiseSheetPenaltyBuffer(int target, int buffer) {
    return '놓친 날이 $target일이 되면 확정 — $buffer번 더 놓치면 내기예요';
  }

  @override
  String get promiseSheetClose => '닫기';

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
  String get historyCardFeedbackHint => '한마디 남기기 (선택)';

  @override
  String get historyCardFeedbackButton => '인정!';

  @override
  String get historyCardAcknowledgePractice => '짝꿍 인정';

  @override
  String get planSummaryMyDone => '내가 한 날';

  @override
  String get planSummaryPartnerVerified => '짝꿍 인정';

  @override
  String planSummaryCount(int count) {
    return '$count회';
  }

  @override
  String get connectInviteCodeDetectedTitle => '복사해 둔 초대 코드를 찾았어요';

  @override
  String get connectCancel => '취소';

  @override
  String get connectNotice => '안내';

  @override
  String get connectAlreadyConnectedBody =>
      '이미 짝꿍과 연결되어 있어요.\n둘운완은 한 사람과만 연결할 수 있어요.';

  @override
  String get connectOk => '확인';

  @override
  String get allPlansTitleMine => '내 약속 전체';

  @override
  String get allPlansTitlePartner => '짝꿍의 약속 전체';

  @override
  String get allPlansEmpty => '등록된 약속이 없어요';

  @override
  String get allPlansDeleteTitle => '약속을 삭제할까요?';

  @override
  String get allPlansDeleteBody => '삭제하면 되돌릴 수 없어요.';

  @override
  String get allPlansDeleted => '약속을 삭제했어요.';

  @override
  String get allPlansDeleteFailed => '삭제하지 못했어요. 다시 시도해 주세요.';

  @override
  String get allPlansDelete => '삭제';

  @override
  String get allPlansCancel => '취소';

  @override
  String get historyErrorUnknown => '알 수 없는 문제가 생겼어요.';

  @override
  String get historyErrorIndexMissing =>
      '데이터를 불러오는 데 필요한 설정이 빠져 있어요.\n이 화면을 캡처해서 개발자에게 보내 주세요.';

  @override
  String get historyErrorAlreadyDeleted => '이미 삭제된 기록이거나 약속이라\n리액션을 남길 수 없어요.';

  @override
  String get historyErrorTitle => '문제가 생겼어요';

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
  String get historyWeeklyPartnerLabel => '짝꿍';

  @override
  String get historyReconcileTitle => '지난 기록 바로잡기';

  @override
  String get historyReconcileSubtitle => '이 날의 약속, 사실 어땠나요?';

  @override
  String get historyReconcileHold => '보류할게요';

  @override
  String get usNoticeTitle => '안내';

  @override
  String get usOk => '확인';

  @override
  String get usProfileSaveFailed => '프로필을 저장하지 못했어요. 다시 시도해 주세요.';

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
  String get usEmptyPartner => '짝꿍이 진행 중인 약속이 없어요';

  @override
  String get usCreatePlanShort => '+ 운동 약속 걸기';

  @override
  String get usCreatePlan => '운동 약속 걸기';

  @override
  String get usDeletePlanTitle => '약속을 삭제할까요?';

  @override
  String get usDeletePlanBody => '삭제하면 되돌릴 수 없어요.';

  @override
  String get usPlanDeleted => '약속을 삭제했어요.';

  @override
  String get usDeleteFailed => '삭제하지 못했어요. 다시 시도해 주세요.';

  @override
  String get usDelete => '삭제';

  @override
  String get planDetailPracticeHistory => '약속 기록';

  @override
  String get planDetailLoadFailed => '기록을 불러오지 못했어요. 다시 시도해 주세요.';

  @override
  String get planDetailNoRecords => '아직 기록이 없어요.';

  @override
  String get planDetailNotSavedPlan => '아직 저장되지 않은 약속이에요.';

  @override
  String get planDetailRecordDone => '완료';

  @override
  String get planDetailRecordSkipped => '건너뜀';

  @override
  String get planDetailRecordRested => '휴식권';

  @override
  String get planDetailRecordRescued => '짝꿍 인정';

  @override
  String get planDetailPokeSent => '짝꿍한테 똑똑을 보냈어요.';

  @override
  String get planDetailPokeFailed => '전송하지 못했어요. 다시 시도해 주세요.';

  @override
  String get planDetailPokeDoneToday => '오늘 똑똑 보냈어요';

  @override
  String get planDetailPokeSending => '전송 중...';

  @override
  String get planDetailPokeAsk => '똑똑 보내기';

  @override
  String get planDetailPokeAlreadyDone => '오늘은 이미 했어요';

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
  String get planDetailNotificationSaved => '알림 설정을 저장했어요.';

  @override
  String get planDetailNotificationSaveFailed =>
      '알림 설정을 저장하지 못했어요. 이전 설정으로 되돌렸어요.';

  @override
  String get planDetailSave => '저장';

  @override
  String get planDetailStopTitle => '약속을 그만할까요?';

  @override
  String get planDetailStopBody => '그만해도 지금까지의 기록은 남아요.';

  @override
  String get planDetailCancel => '취소';

  @override
  String get planDetailStopped => '약속을 그만뒀어요.';

  @override
  String get planDetailActionFailed => '문제가 생겼어요. 잠시 후 다시 시도해 주세요.';

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
    return '오늘 \'$title\' 약속은 놓친 날로 남고, 짝꿍한테도 알려져요. 둘이 함께 연속 기록이 끊길 수 있어요.';
  }

  @override
  String get nowCancel => '취소';

  @override
  String get nowSkipToday => '오늘은 패스';

  @override
  String get nowSkippedSnackbar => '오늘 약속을 건너뛰었어요.';

  @override
  String get nowApproveCheering => '좋아요, 시작해요!';

  @override
  String get nowApproveFailed => '수락하지 못했어요.';

  @override
  String get nowRejectDialogTitle => '조금 바꿔 볼까요?';

  @override
  String get nowRejectLessFrequent => '빈도를 조금 줄여보자';

  @override
  String get nowRejectDifferentTime => '다른 시간대가 좋을 것 같아';

  @override
  String get nowRejectCustom => '직접 쓸게';

  @override
  String get nowRejectRequested => '바꿔 보자고 보냈어요';

  @override
  String get nowRejectCustomDialogTitle => '어떻게 바꾸면 좋을까요?';

  @override
  String get nowRejectCustomHint => '예: 주 3회로 시작해보는 건 어때?';

  @override
  String get nowSend => '보내기';

  @override
  String get nowCheerFailed => '응원을 보내지 못했어요.';

  @override
  String get nowPokeNoActivityMessage => '똑똑! 운동 약속 하나 걸어 줘. 내가 봐줄게 🙂';

  @override
  String get nowPokeSent => '똑똑을 보냈어요.';

  @override
  String get nowPokeFailed => '똑똑을 보내지 못했어요.';

  @override
  String get nowPokeAgainMessage => '똑똑! 오늘 약속 기다리고 있어 🙂';

  @override
  String get nowPokeAgainSent => '짝꿍한테 똑똑을 보냈어요.';

  @override
  String get nowSettlementSaved => '4주 돌아보기를 남겼어요.';

  @override
  String get nowExitDialogTitle => '이번 4주를 여기서 마무리할까요?';

  @override
  String get nowExitReasonWeakPoke => '똑똑이 별로 도움이 안 됐어요';

  @override
  String get nowExitReasonTooBig => '목표가 너무 컸어요';

  @override
  String get nowExitReasonPartnerBurden => '서로 봐주는 게 부담됐어요';

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
  String get nowRestPassBody => '이번 주 휴식권 1장을 써요.\n연속 기록은 그대로 이어져요.';

  @override
  String get nowRestPassConfirm => '사용하기';

  @override
  String get nowRestPassUsed => '오늘은 푹 쉬어요. 연속 기록은 그대로예요!';

  @override
  String get nowRestPassAlreadyUsed => '이번 주 휴식권을 이미 사용했어요.';

  @override
  String get nowRestPassError => '문제가 생겼어요.';

  @override
  String get nowRescuedSnackbar => '인정해 줬어요! 연속 기록이 이어져요.';

  @override
  String get nowRescueFailed => '인정하지 못했어요.';

  @override
  String get nowPromiseAccepted => '내기 성립! 🤝';

  @override
  String get nowPromiseDeclined => '이번 내기는 패스했어요.';

  @override
  String get nowPromiseResponseFailed => '내기에 답하지 못했어요.';

  @override
  String get nowPromiseProposed => '내기를 제안했어요!';

  @override
  String get nowPromiseProposeFailed => '내기를 제안하지 못했어요.';

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
  String get nowErrorTitle => '문제가 생겼어요';

  @override
  String get nowErrorCreationLink => '생성 링크:';

  @override
  String get nowOk => '확인';

  @override
  String get nowRetryLater => '잠시 후 다시 시도해 주세요';

  @override
  String get nowPartnerActionFallback => '짝꿍의 약속';

  @override
  String get nowActionNoteHint => '한마디 남기기 (선택)';

  @override
  String get nowVerifyAndSend => '인정하고 보내기';

  @override
  String nowStreakCount(int count) {
    return '$count번 연속 지켰어요!';
  }

  @override
  String get nowHeaderAdjustNeeded => '조율이 필요해요';

  @override
  String get nowHeaderPromiseProposed => '내기 제안이 왔어요';

  @override
  String get nowHeaderPromiseSettled => '내기 결과가 나왔어요';

  @override
  String get nowPromiseAckButton => '결과 확인하기';

  @override
  String get nowPromiseAckDialogTitle => '내기 결과';

  @override
  String get nowPromiseAckDialogHint => '짝꿍한테 한마디 (선택)';

  @override
  String get nowPromiseAckDialogConfirm => '확인했어';

  @override
  String get nowPromiseAckSnackbar => '결과를 확인했어요';

  @override
  String get nowPromiseAckFailed => '결과를 확인하지 못했어요';

  @override
  String get planDetailViewList => '목록';

  @override
  String get planDetailViewCalendar => '캘린더';

  @override
  String get planDetailViewGraph => '그래프';

  @override
  String get planDetailLegendDone => '완료';

  @override
  String get planDetailLegendRested => '휴식권';

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
  String get planDetailGraphCompletionRate => '주별 달성률';

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
  String get planDetailProgressDoneLabel => '완료';

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
  String get planDetailPromiseProgressTitle => '내기 진행';

  @override
  String get planDetailPromiseRewardLabel => '🏆 지키면';

  @override
  String get planDetailPromisePenaltyLabel => '⚡ 못 지키면';

  @override
  String planDetailPromiseRewardNeed(int days) {
    return '$days일 더 지키면 성공';
  }

  @override
  String get planDetailPromiseRewardAchieved => '🎉 지켰어요!';

  @override
  String planDetailPromisePenaltyBuffer(int buffer) {
    return '$buffer번 더 놓치면 내기 확정';
  }

  @override
  String get planDetailPromisePenaltyImminent => '한 번 더 놓치면 내기 확정';

  @override
  String get planDetailPromisePenaltyTriggered => '⚡ 못 지켰어요 · 내기 확정';

  @override
  String get planDetailMoreMenu => '더보기';

  @override
  String get planDetailMenuRestartCompleted => '이 약속으로 다시 걸기';

  @override
  String get planDetailMenuRestartActive => '새 스케줄로 다시 시작';

  @override
  String get planDetailMenuStop => '약속 그만하기';

  @override
  String planDetailPromiseSuccessFailBreakdown(int success, int fail) {
    return '지킨 날 $success일 · 놓친 날 $fail일';
  }

  @override
  String get nowHeaderSettlementNeeded => '4주를 마쳤어요';

  @override
  String get nowHeaderSettlementSub => '4주 동안 어땠는지 돌아보고 다음 4주를 정해요.';

  @override
  String get nowMetricCompleted => '완료';

  @override
  String get nowMetricPartnerReact => '짝꿍 인정';

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
  String get nowSettlementWinMessage => '약속한 목표를 채웠어요. 멋져요! 다음 4주도 이어갈지 정해요.';

  @override
  String get nowSettlementLoseMessage =>
      '이번엔 목표에 닿지 못했지만, 함께한 4주는 그대로 남아요. 다음 4주를 어떻게 바꿔 볼지 정해요.';

  @override
  String get nowSettlementNeutralMessage =>
      '4주를 끝까지 함께했어요. 이제 다음 4주를 이어갈지 정해요.';

  @override
  String nowRewardCondition(int days, String description) {
    return '$days일 지키면: $description';
  }

  @override
  String nowPenaltyCondition(int days, String description) {
    return '$days일 놓치면: $description';
  }

  @override
  String nowPromiseResult(int success, int fail) {
    return '지킨 날 $success일 / 놓친 날 $fail일';
  }

  @override
  String get nowAchieved => '달성!';

  @override
  String get nowTriggered => '확정!';

  @override
  String get nowNotMet => '미달';

  @override
  String get nowDecline => '이번엔 패스';

  @override
  String get nowAccept => '좋아, 콜!';

  @override
  String get nowContinueNext4Weeks => '다음 4주 시작하기';

  @override
  String get nowStopHere => '이번 4주는 여기서 마무리하기';

  @override
  String get nowModify => '수정하기';

  @override
  String get nowStartFocusTimer => '지금 할게! (집중 타이머)';

  @override
  String get nowRestToday => '오늘은 쉴게 (휴식권)';

  @override
  String get nowHeaderTodayAllDone => '오늘 할 일 끝 🎉';

  @override
  String nowHeaderConfirmAndPull(String name) {
    return '$name 오늘 했대요! 인정해 줄래요?';
  }

  @override
  String nowHeaderWaiting(String name) {
    return '$name의 약속을 기다리는 중';
  }

  @override
  String get nowHeaderWaitingAccept => '내기 수락을 기다리는 중';

  @override
  String get nowHeaderPromiseResult => '내기 결과가 나왔어요';

  @override
  String get nowAdjust => '바꿔 보자';

  @override
  String get nowApprove => '좋아!';

  @override
  String get nowPartnerNoNewPlanGuide =>
      '짝꿍이 아직 운동 약속을 걸지 않았어요. 똑똑으로 같이 시작해 볼까요?';

  @override
  String get nowKnockMakePlan => '똑똑! 같이 하자';

  @override
  String nowPartnerMissedPokeBody(String name) {
    return '$name 오늘 약속을 아직 못 했어요. 응원을 보내 볼까요?';
  }

  @override
  String nowPartnerQuietPokeBody(String name) {
    return '$name의 약속이 아직 조용해요. 기다리고 있다고 똑똑을 보내 볼까요?';
  }

  @override
  String get nowKnockPull => '똑똑 보내기';

  @override
  String get nowRescueYesterday => '어제 것도 인정해 주기';

  @override
  String get nowVerifyAndCheer => '인정하기';

  @override
  String get nowMakePromise => '내기 걸기';

  @override
  String get nowPartnerFallback2 => '짝꿍';

  @override
  String nowPartnerAllDone(String name) {
    return '$name 오늘 약속을 다 지켰어요 🎉';
  }

  @override
  String get nowQuickCheckHelp => '인정 한 번이면 내일도 힘이 나요.';

  @override
  String nowLastAction(String title) {
    return '마지막 기록: $title';
  }

  @override
  String nowRewardLine(int days, String description) {
    return '🏆 $days일 지키면: $description';
  }

  @override
  String nowPenaltyLine(int days, String description) {
    return '⚡ $days일 놓치면: $description';
  }

  @override
  String nowResultLine(int success, int fail) {
    return '결과: 지킨 날 $success일 / 놓친 날 $fail일';
  }

  @override
  String get nowWaitingApproval => '수락 대기 중...';

  @override
  String get nowRewardAchievedTitle => '🎉 지켰어요!';

  @override
  String get nowPenaltyTriggeredTitle => '⚡ 내기 확정!';

  @override
  String get nowBothTitle => '🎉 지켰어요! + ⚡ 내기 확정!';

  @override
  String get nowConditionNotMet => '조건 미달';

  @override
  String nowTotalDaysOnly(int days) {
    return '총 $days일짜리 약속이에요';
  }

  @override
  String nowTotalDaysScheduled(int days, int scheduled) {
    return '총 $days일짜리 약속 · 할 날 $scheduled일';
  }

  @override
  String get nowMakePromiseTitle => '내기 걸기';

  @override
  String get nowMakePromiseSubtitle => '짝꿍이 받으면 내기가 시작돼요. 돈 말고 밥·커피·설거지로 걸어요.';

  @override
  String nowProgressLine(int success, int failed, int remaining) {
    return '지금 지킨 날 $success일 · 놓친 날 $failed일 · 남은 날 $remaining일';
  }

  @override
  String nowMaxLimitsLine(int reward, int penalty) {
    return '지킬 날은 최대 $reward일, 놓칠 날은 최대 $penalty일까지 정할 수 있어요.';
  }

  @override
  String get nowRewardTitle => '🏆 지키면';

  @override
  String get nowRewardHint => '예: 🍣 같이 오마카세, 영화 고르기';

  @override
  String get nowRewardTargetLabel => '지킬 날';

  @override
  String get nowPenaltyTitle => '⚡ 못 지키면';

  @override
  String get nowPenaltyHint => '예: 🍗 치킨 쏘기, 설거지 일주일';

  @override
  String get nowPenaltyTargetLabel => '놓친 날 기준';

  @override
  String get nowProposePromise => '내기 제안하기';

  @override
  String nowDaysSuffix(int count) {
    return '$count일';
  }

  @override
  String nowMaxDaysLabel(int days) {
    return '최대 $days일';
  }

  @override
  String get nowPokeReceived => '짝꿍이 똑똑을 보냈어요';

  @override
  String nowPokeReceivedFromName(String name) {
    return '$name한테서 똑똑이 왔어요';
  }

  @override
  String get nowNoteDateToday => '오늘';

  @override
  String get connectErrorSelfCode => '내 초대 코드는 쓸 수 없어요.';

  @override
  String get connectErrorFailed => '코드가 맞지 않거나 연결하지 못했어요.';

  @override
  String get connectErrorDisconnectFailed => '연결을 끊지 못했어요. 다시 시도해 주세요.';

  @override
  String get accountLinkErrorAlreadyInUse => '이 계정은 이미 다른 사용자와 연결되어 있어요.';

  @override
  String get accountLinkErrorInvalidCredential => '인증 정보가 올바르지 않아요.';

  @override
  String get accountLinkErrorNotAllowed => '허용되지 않은 작업이에요.';

  @override
  String get accountLinkErrorGeneric => '계정을 연결하는 중 문제가 생겼어요.';

  @override
  String get planCreateErrorNoUser => '사용자 정보를 찾을 수 없어요. 다시 로그인해 주세요.';

  @override
  String get notifyBannerTitle => '알림이 꺼져 있어요';

  @override
  String get notifyBannerBody => '짝꿍의 인정과 똑똑을 놓치지 않게 알림을 켜 주세요.';

  @override
  String get notifyBannerAction => '켜기';

  @override
  String get nowActionFailed => '문제가 생겼어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get usNameRequired => '이름을 입력해 주세요.';

  @override
  String get usImagePickFailed => '이 이미지를 쓸 수 없어요. 다른 이미지를 골라 주세요.';

  @override
  String get settingsLogoutFailed => '로그아웃하지 못했어요. 다시 시도해 주세요.';

  @override
  String get settingsDeletingAccount => '계정을 삭제하는 중이에요…';

  @override
  String get authErrorInvalidCredential => '이메일 또는 비밀번호가 올바르지 않아요.';

  @override
  String get authErrorUserNotFound => '해당 계정을 찾을 수 없어요.';

  @override
  String get authErrorEmailInUse => '이미 가입된 이메일이에요.';

  @override
  String get authErrorInvalidEmail => '이메일 주소 형식이 올바르지 않아요.';

  @override
  String get authErrorWeakPassword => '비밀번호는 6자 이상으로 입력해 주세요.';

  @override
  String get authErrorTooManyRequests => '시도가 너무 많아요. 잠시 후 다시 시도해 주세요.';

  @override
  String get authErrorNetwork => '네트워크 연결을 확인한 뒤 다시 시도해 주세요.';

  @override
  String get authErrorGeneric => '로그인에 실패했어요. 다시 시도해 주세요.';

  @override
  String get tutorialSkip => '건너뛰기';

  @override
  String get tutorialClose => '닫기';

  @override
  String get tutorialNext => '다음';

  @override
  String get tutorialStart => '시작하기';

  @override
  String get tutorialFooter => '운동 약속 하나면 시작할 수 있어요.';

  @override
  String get tutorialPage1Title => '운동 약속을 걸어요';

  @override
  String get tutorialPage1Body =>
      '헬스, 러닝, 홈트… 할 운동과 요일을 정해 짝꿍한테 약속해요. 혼자 다짐할 때보다 훨씬 덜 미루게 돼요.';

  @override
  String get tutorialPage2Title => '짝꿍이 보고 인정해요';

  @override
  String get tutorialPage2Body =>
      '운동하고 인증샷을 올리면 짝꿍한테 바로 보여요. 짝꿍은 탭 한 번으로 인정해 주고, 깜빡한 날엔 똑똑으로 알려 줘요.';

  @override
  String get tutorialPage3Title => '둘 다 하면, 둘운완';

  @override
  String get tutorialPage3Body => '오늘 둘 다 운동했다면 둘운완이에요. 둘이 함께 쌓아 가는 날들을 같이 봐요.';

  @override
  String get appUpdateRequiredTitle => '업데이트가 필요해요';

  @override
  String get appUpdateRequiredBody =>
      '지금 버전은 더 이상 지원하지 않아요. 최신 버전으로 업데이트하고 계속 이용해 주세요.';

  @override
  String get appUpdateButton => '업데이트하기';

  @override
  String get appUpdateSoftTitle => '새 버전이 나왔어요';

  @override
  String get appUpdateSoftBody => '업데이트하고 새로워진 기능을 만나 보세요.';

  @override
  String get appUpdateLater => '나중에';

  @override
  String get appUpdateStoreOpenFailed => '스토어를 열지 못했어요. 스토어 앱에서 직접 업데이트해 주세요.';

  @override
  String get nowHeaderPartnerAskedAdjust => '짝꿍이 약속을 조금 바꿔 보자고 했어요';

  @override
  String get nowHeaderPokeWaiting => '똑똑! 짝꿍이 기다리고 있어요';

  @override
  String nowHeaderMissedNotice(String name) {
    return '오늘 약속 기록이 없어서 $name한테 알려졌어요';
  }

  @override
  String nowHeaderPartnerMissed(String name) {
    return '$name의 오늘 약속이 아직이에요';
  }

  @override
  String get nowHeaderPokeTurn => '똑똑 보낼 차례예요';

  @override
  String get promiseUntitledFallback => '약속';

  @override
  String planSummaryWeeks(int count) {
    return '$count주간';
  }

  @override
  String get settingsTutorialTitle => '앱 사용법';

  @override
  String get settingsTutorialDesc => '운동 약속을 걸고 짝꿍한테 인정받는 흐름을 다시 봐요';

  @override
  String get notifActionDidIt => '했어';

  @override
  String get notifActionSkipToday => '오늘은 패스';

  @override
  String get notifActionSnooze => '10분 뒤에 다시 알려 줘';

  @override
  String get notifReminderBody => '인증 한 번이면 오늘 기록 끝이에요 📸';

  @override
  String get notifFallbackTitle => '둘운완';

  @override
  String get notifChannelRemindersName => '약속 알림';

  @override
  String get notifChannelRemindersDesc => '정해 둔 시간에 오늘 약속을 알려 줘요';

  @override
  String get notifChannelGeneralName => '짝꿍 소식';

  @override
  String get notifChannelGeneralDesc => '짝꿍의 인정, 똑똑, 응원을 알려 줘요';

  @override
  String get notifChannelScheduledName => '예약 알림';

  @override
  String get notifChannelScheduledDesc => '정해 둔 시각에 보내는 알림';

  @override
  String get notifChannelDebugName => '테스트 알림';

  @override
  String get notifChannelDebugDesc => '알림 테스트용';

  @override
  String nowHeroQuestion(String emoji, String workout) {
    return '오늘 $emoji $workout 했어?';
  }

  @override
  String nowHeroQuestionDiet(String emoji, String workout) {
    return '오늘 $emoji $workout 지켰어?';
  }

  @override
  String nowHeroQuestionLegacy(String title) {
    return '오늘 \'$title\' 했어?';
  }

  @override
  String get nowProofTakePhoto => '📸 인증샷 찍기';

  @override
  String get nowHeroVerifyLegacy => '인증하기';

  @override
  String get nowDidItNoPhoto => '사진 없이 했어';

  @override
  String get proofSourceSheetTitle => '인증샷 올리기';

  @override
  String get proofSourceCamera => '📸 카메라로 찍기';

  @override
  String get proofSourceCameraHint => '\'방금 찍음\'으로 보여요';

  @override
  String get proofSourceGallery => '🖼️ 앨범에서 고르기';

  @override
  String get proofSourceGalleryHint => '\'앨범\' 표시와 촬영 날짜가 함께 보여요';

  @override
  String get proofConsentTitle => '첫 인증샷 전에 알려 드려요';

  @override
  String get proofConsentOnlyPartner => '연결된 짝꿍 한 명만 볼 수 있어요.';

  @override
  String get proofConsentLocationRemoved => '위치 정보 같은 사진 정보는 지우고 올려요.';

  @override
  String get proofConsentAfterDisconnect => '연결을 끊으면 앱에서 더 이상 볼 수 없어요.';

  @override
  String get proofConsentNoInappropriate => '부적절한 사진은 올리지 말아 주세요.';

  @override
  String get proofConsentAgree => '알겠어요';

  @override
  String get proofPreviewTitle => '이 사진으로 인증할까요?';

  @override
  String get proofPreviewSubmit => '인증하기';

  @override
  String get proofUploadDone => '인증샷을 보냈어요 📸';

  @override
  String get proofUploadFailed => '사진은 못 올렸지만 오늘 기록은 남겼어요.';

  @override
  String get proofPhotoPrepareFailed => '이 사진은 쓸 수 없어요. 다른 사진으로 해 주세요.';

  @override
  String get proofPickFailed => '카메라나 앨범을 열지 못했어요.';

  @override
  String proofBadgeCamera(String time) {
    return '📸 방금 찍음 · $time';
  }

  @override
  String get proofBadgeCameraJustNow => '📸 방금 찍음';

  @override
  String proofBadgeCameraOn(String when) {
    return '📸 카메라 · $when';
  }

  @override
  String proofBadgeGalleryTaken(String date) {
    return '🖼️ 앨범 · $date 촬영';
  }

  @override
  String get proofBadgeGallery => '🖼️ 앨범';

  @override
  String get proofPhotoLoadFailed => '사진을 불러오지 못했어요';

  @override
  String get proofPhotoRetry => '다시 불러오기';

  @override
  String get proofPhotoSemantics => '인증샷';

  @override
  String get proofViewerMenu => '더보기';

  @override
  String get proofViewerReport => '신고하기';

  @override
  String get proofViewerDelete => '사진 삭제';

  @override
  String get proofDeleteConfirmTitle => '이 인증샷을 지울까요?';

  @override
  String get proofDeleteConfirmBody => '짝꿍도 더 이상 볼 수 없어요. 기록은 그대로 남아요.';

  @override
  String get proofDeleteConfirm => '삭제';

  @override
  String get proofDeleted => '인증샷을 지웠어요.';

  @override
  String get proofDeleteFailed => '사진을 지우지 못했어요. 다시 시도해 주세요.';

  @override
  String get proofReportSubject => '[둘운완] 인증샷 신고';

  @override
  String proofReportBody(String actionId) {
    return '어떤 점이 문제인지 알려 주세요.\n\n기록 ID: $actionId';
  }

  @override
  String proofReportMailFailed(String email) {
    return '메일 앱을 열지 못했어요. 이 주소로 보내 주세요: $email';
  }

  @override
  String get nowReactHint => '하나만 눌러도 인정이에요';

  @override
  String get nowReactAddNote => '한마디';

  @override
  String nowReactSemantics(String emoji) {
    return '$emoji 보내고 인정하기';
  }

  @override
  String nowReactedSnackbar(String emoji) {
    return '$emoji 인정했어요';
  }

  @override
  String get partnerFallbackLabel => '짝꿍';

  @override
  String get partnerFallbackLabelStart => '짝꿍';

  @override
  String get connectShareInvite => '카톡으로 초대 보내기';

  @override
  String get connectCopyCode => '코드 복사';

  @override
  String get connectHaveCodeTitle => '받은 코드가 있나요?';

  @override
  String get connectInviteSent => '초대를 보냈어요. 짝꿍이 들어오면 알려 줄게요.';

  @override
  String get connectShareFailed => '공유 창을 열지 못했어요. 코드를 복사해서 보내 주세요.';

  @override
  String get connectErrorCodeNotFound => '이 코드를 가진 사람을 찾지 못했어요. 다시 확인해 주세요.';

  @override
  String get connectErrorCodeFormat => '코드는 영문과 숫자 8자리예요.';

  @override
  String get connectErrorOwnerTaken => '이미 다른 짝꿍과 연결된 코드예요. 상대에게 새 코드를 받아 주세요.';

  @override
  String get connectErrorSelfTaken => '이미 연결된 짝꿍이 있어요. 기존 연결을 끊은 뒤 다시 시도해 주세요.';

  @override
  String get connectErrorCodeChanged => '코드가 바뀌었어요. 상대에게 새 코드를 받아 주세요.';

  @override
  String get connectErrorLinkUndone =>
      '연결이 유지되지 않았어요. 이미 다른 짝꿍과 연결된 코드일 수 있어요 — 상대에게 새 코드를 받아 주세요.';

  @override
  String inviteShareMessage(String code, String link) {
    return '나 운동 약속 걸었어 🤙 진짜 하는지 봐줘! 둘운완 깔고 코드 $code 넣으면 바로 연결돼 → $link';
  }

  @override
  String inviteShareMessageNoPromise(String code, String link) {
    return '나 운동 약속 걸 거야 🤙 진짜 하는지 봐줘! 둘운완 깔고 코드 $code 넣으면 바로 연결돼 → $link';
  }

  @override
  String get inviteShareSubject => '둘운완 초대';

  @override
  String get inviteHaveCodeLink => '초대 코드 받았어요';

  @override
  String connectConfirmTitle(String name) {
    return '$name의 운동 약속을 봐줄래요?';
  }

  @override
  String get connectConfirmBody => '연결하면 서로의 운동 약속과 인증샷을 볼 수 있어요.';

  @override
  String get connectConfirmAccept => '내가 봐줄게';

  @override
  String connectSuccessTitle(String name) {
    return '$name하고 연결됐어요 🎉';
  }

  @override
  String get connectSuccessBody => '이제 서로의 운동 약속을 봐줄 수 있어요.';

  @override
  String get connectSuccessAskTitle => '나도 걸래?';

  @override
  String get connectSuccessAskBody => '둘 다 하면 둘운완이에요.';

  @override
  String get connectSuccessMakePromise => '나도 걸기';

  @override
  String get connectSuccessLater => '나중에';

  @override
  String get connectSuccessDone => '좋아요';

  @override
  String get connectHowTitle => '이렇게 해요';

  @override
  String get connectHowProof => '운동하면 인증샷을 올려요';

  @override
  String get connectHowAck => '짝꿍 인증샷엔 탭 한 번으로 인정해 줘요';

  @override
  String get connectHowDuo => '둘 다 운동한 날이 둘운완이에요';

  @override
  String get nicknameSheetTitle => '짝꿍을 뭐라고 부를까요?';

  @override
  String nicknameSheetBody(String name) {
    return '앱 화면과 알림에서 $name 대신 이 애칭으로 보여요.';
  }

  @override
  String get nicknamePresetPartner => '짝꿍';

  @override
  String get nicknamePresetJagi => '자기';

  @override
  String get nicknamePresetOppa => '오빠';

  @override
  String get nicknamePresetYeobo => '여보';

  @override
  String get nicknamePresetAegi => '애기';

  @override
  String get nicknamePresetCustom => '직접 입력';

  @override
  String get nicknameCustomHint => '애칭 (10자까지)';

  @override
  String get nicknameSave => '저장하기';

  @override
  String get nicknameLater => '나중에 정할게요';

  @override
  String get nicknameRemove => '애칭 지우기';

  @override
  String get nicknameSaved => '애칭을 저장했어요.';

  @override
  String get nicknameRemoved => '애칭을 지웠어요.';

  @override
  String get nicknameSaveFailed => '애칭을 저장하지 못했어요. 다시 시도해 주세요.';

  @override
  String get usSetNickname => '애칭 정하기';

  @override
  String get usEditNickname => '애칭 바꾸기';

  @override
  String get onboardingInviteLater => '나중에 초대할게요';

  @override
  String get nowInviteCardTitle => '짝꿍이 보면 진짜 하게 돼요';

  @override
  String get nowInviteCardBody => '초대를 보내면 서로의 운동 약속을 봐줄 수 있어요.';

  @override
  String get nowInviteCardWaitingTitle => '짝꿍을 기다리는 중이에요';

  @override
  String get nowInviteCardWaitingBody => '아직 안 들어왔어요. 한 번 더 보내 볼까요?';

  @override
  String get nowInviteCardResend => '초대 다시 보내기';

  @override
  String get pivotNoticeTitle => '\'그래,해봐\'가 둘운완이 됐어요';

  @override
  String get pivotNoticeBody => '약속, 기록, 짝꿍 연결은 그대로예요.';

  @override
  String get pivotNoticeOk => '좋아요';

  @override
  String duoStreakDays(int count) {
    return '둘이 함께 $count일째';
  }

  @override
  String get duoStreakStart => '오늘 둘 다 하면 둘운완 1일째';

  @override
  String get duoTodayDone => '오늘 둘운완이에요 🎉';

  @override
  String get duoMeLabel => '나';

  @override
  String get duoStatusDone => '완료 ✓';

  @override
  String get duoStatusVerified => '인정 ❤️';

  @override
  String get duoStatusWaiting => '인정 대기';

  @override
  String get duoStatusPending => '아직';

  @override
  String get duoStatusRested => '휴식권';

  @override
  String get duoStatusOff => '쉬는 날';

  @override
  String get duoStatusMissed => '놓침';

  @override
  String get duoStatusUpcoming => '예정';

  @override
  String duoPersonStatus(String name, String status) {
    return '$name $status';
  }

  @override
  String duoWeekDuoDays(int count) {
    return '둘운완 $count일';
  }

  @override
  String duoDaySemantics(String day, String me, String partner) {
    return '$day 나 $me, 짝꿍 $partner';
  }

  @override
  String get duoShareButton => '공유 카드 만들기';

  @override
  String shareCardStreak(int count) {
    return '#둘운완 연속 $count일';
  }

  @override
  String get shareCardNoStreak => '#둘운완';

  @override
  String get shareCardStores => '스토어에서 \'둘운완\' 검색';

  @override
  String shareCardPersonDone(String name, String workout) {
    return '$name ✓ $workout';
  }

  @override
  String shareCardPersonOff(String name) {
    return '$name · 쉬는 날';
  }

  @override
  String shareCardPersonRested(String name) {
    return '$name · 휴식권';
  }

  @override
  String shareCardPersonPending(String name) {
    return '$name · 아직';
  }

  @override
  String get shareCardSheetTitleToday => '오늘 둘운완이에요 🎉 자랑해 볼까요?';

  @override
  String shareCardSheetTitleMilestone(int count) {
    return '둘이 함께 $count일째! 🎉 자랑해 볼까요?';
  }

  @override
  String get shareCardSheetTitleManual => '공유 카드';

  @override
  String get shareCardShare => '공유하기';

  @override
  String get shareCardLater => '다음에';

  @override
  String get shareCardFailed => '공유 카드를 만들지 못했어요.';

  @override
  String get shareCardOnlyMyPhoto => '카드에는 내 인증샷만 들어가요.';

  @override
  String get shareCardText => '#둘운완 #오운완 둘이 보면, 진짜 하게 돼요.';

  @override
  String get shareCardSemantics => '둘운완 공유 카드';

  @override
  String get nowPokeReplyComing => '지금 간다 🏃';

  @override
  String get nowPokeReplyPass => '오늘은 봐줘 🙏';

  @override
  String get nowPokeReplySent => '답장 보냈어요';

  @override
  String get nowPokeReplyFailed => '답장을 보내지 못했어요.';

  @override
  String get nowSendCheer => '응원 보내기';

  @override
  String get nowCheerDefaultMessage => '할 수 있어! 기다릴게 💪';

  @override
  String get nowCheerSent => '응원을 보냈어요';

  @override
  String get nowKnockSentToday => '오늘 똑똑 보냈어요';

  @override
  String get promisePenaltyChicken => '🍗 치킨 쏘기';

  @override
  String get promisePenaltyCoffee => '☕ 아아 쏘기';

  @override
  String get promisePenaltyDishes => '🍽️ 설거지 일주일';

  @override
  String get promisePenaltyMassage => '💆 마사지 10분';

  @override
  String get promisePenaltyMovie => '🎬 영화 고르기 양보';

  @override
  String get promisePenaltyPickup => '🚗 데리러 가기';

  @override
  String get promiseRewardOmakase => '🍣 같이 오마카세';

  @override
  String get promiseRewardDessert => '🍰 디저트 데이트';

  @override
  String get promiseRewardMassage => '💆 마사지 10분 받기';

  @override
  String get promiseRewardMovie => '🎬 영화 고르기 권한';

  @override
  String get promiseMoneyBlocked =>
      '돈 내기는 지원하지 않아요. 밥, 커피, 설거지처럼 둘이 할 수 있는 걸로 걸어 주세요.';

  @override
  String notifReminderBodyWithPartner(String name) {
    return '기록이 없으면 곧 $name한테 알려져요';
  }

  @override
  String get nowRecordQueued => '기록했어요. 연결되면 짝꿍한테 전해져요.';

  @override
  String get settingsAboutSection => '정보';

  @override
  String get settingsPrivacyPolicy => '개인정보처리방침';

  @override
  String get settingsTermsOfUse => '이용약관';

  @override
  String get settingsContactSupport => '고객지원';

  @override
  String get settingsContactSupportSubject => '[둘운완] 문의';

  @override
  String settingsLinkOpenFailed(String email) {
    return '열지 못했어요. 문의는 $email로 보내 주세요.';
  }

  @override
  String get usReportPartner => '짝꿍 신고하기';

  @override
  String get usReportPartnerSubject => '[둘운완] 짝꿍 신고';

  @override
  String usReportPartnerBody(String uid) {
    return '어떤 내용(사진, 한마디, 메시지 등)이 문제인지 알려 주세요. 확인 후 조치할게요.\n\n신고 대상 ID: $uid';
  }

  @override
  String get termsViewLink => '이용약관 보기';

  @override
  String get termsNoticeConnect =>
      '연결하면 이용약관에 동의하는 거예요. 부적절한 내용이나 괴롭힘은 허용하지 않고, 신고되면 내용과 계정을 정리해요.';

  @override
  String get termsNoticeInvite =>
      '초대를 보내면 이용약관에 동의하는 거예요. 부적절한 내용이나 괴롭힘은 허용하지 않아요.';

  @override
  String get termsNoticePhoto => '올리면 이용약관에 동의하는 거예요. 부적절한 사진이나 괴롭힘은 허용하지 않아요.';

  @override
  String get planSavedInviteTitle => '약속 걸었어요! 이제 봐 달라고 해 볼까요?';

  @override
  String get planSavedInviteBody => '짝꿍이 봐주면 진짜 하게 돼요. 카톡으로 코드와 링크를 보내요.';
}
