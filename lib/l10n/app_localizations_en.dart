// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DuoDone';

  @override
  String get splashTagline => 'When your partner sees it, you actually do it.';

  @override
  String get loginWithGoogle => 'Continue with Google';

  @override
  String get loginWithApple => 'Continue with Apple';

  @override
  String get loginGuest => 'Start without login';

  @override
  String get privacyMessage =>
      'You both agree to connect.\nProof photos are seen only by your partner.';

  @override
  String get connectHeadline => 'Invite your partner';

  @override
  String get connectSubtitle =>
      'Send your code so you can back each other\'s workout promises.';

  @override
  String get enterInviteCode => 'Enter your partner\'s code';

  @override
  String get startSolo => 'I\'ll connect later';

  @override
  String get codeCopied => 'Code copied';

  @override
  String get enterCodeBelow => 'Enter the code below';

  @override
  String get sendConnectionRequest => 'Connect as partners';

  @override
  String get homeDidIt => 'Did it';

  @override
  String get homeReceivedMessage => 'News from your partner';

  @override
  String get homeChecked => 'Props';

  @override
  String get tabNow => 'Now';

  @override
  String get tabHistory => 'History';

  @override
  String get tabUs => 'Us';

  @override
  String get historyEmpty => 'No promises recorded yet';

  @override
  String get usMeTitle => 'Me';

  @override
  String get usDefaultNameMe => 'Me';

  @override
  String get usYouTitle => 'Partner';

  @override
  String get usHeroSubtitle => 'Backing each other\'s workouts';

  @override
  String get usCheerTooltip => 'Send cheer';

  @override
  String get usProfileEdit => 'Edit';

  @override
  String get usStatusMessagePlaceholder => 'Set status message';

  @override
  String get usMyInviteCode => 'My Invite Code';

  @override
  String get usGuestWarningMessage =>
      'If you change phone or delete app/data, you may lose records.';

  @override
  String get usGuestWarningAction => 'Link Account to Keep Records';

  @override
  String get usLoadError => 'Couldn\'t load your connection.';

  @override
  String get usNoInviteCode => 'No Code';

  @override
  String get usUnknownUser => 'Partner';

  @override
  String get usDisconnectDialogTitle => 'Disconnect';

  @override
  String usDisconnectDialogContent(String name) {
    return 'Disconnect from $name?';
  }

  @override
  String get usDisconnectConfirm => 'Disconnect';

  @override
  String get usDisconnectSuccess => 'You\'re no longer connected.';

  @override
  String get usDisconnectError => 'We couldn\'t disconnect. Please try again.';

  @override
  String get usDisconnectTooltip => 'Disconnect';

  @override
  String get usCropImageTitle => 'Crop Profile Image';

  @override
  String get cancel => 'Cancel';

  @override
  String get usProfileEditImageLabel => 'Change profile picture';

  @override
  String get usAddConnectionLabel => 'Connect your partner';

  @override
  String get usBadgeMutual => 'Together';

  @override
  String get usEmptyMatesTitle => 'No partner yet';

  @override
  String get usEmptyMatesSubtitle =>
      'Invite your partner and back each other\'s workout promises';

  @override
  String get nowNoPlan => 'No workout promise yet';

  @override
  String get nowCreatePlan => '+ Make a workout promise';

  @override
  String get nowQuietRest => 'Today\'s a rest day';

  @override
  String get nowNoPlanSubtitle => 'Pick one workout and make it a promise';

  @override
  String get nowTodayDone => 'All of today\'s promises kept 🙌';

  @override
  String nowTodayAllDone(int count) {
    return 'Kept all $count promises today 🙌';
  }

  @override
  String nowPartnerProposed(String name) {
    return '$name sent a new promise';
  }

  @override
  String get nowPartnerAdjusting => 'Your partner tweaked a promise';

  @override
  String get nowActionSkipToday => 'Skip today';

  @override
  String get nowDeferMenuTooltip => 'Set aside';

  @override
  String get nowDeferLaterTitle => 'I\'ll do it later';

  @override
  String get nowDeferLaterSubtitle =>
      'We\'ll show your next promise now and nudge you again later';

  @override
  String get nowSkipTodayTitle => 'Skip today';

  @override
  String get nowSkipTodaySubtitle => 'Counts as missed — your streak may reset';

  @override
  String get nowDeferRestSubtitle => 'Use a rest pass — your streak stays';

  @override
  String get nowSkipTodayDone => 'Skipped for today';

  @override
  String get nowDeferLaterDone => 'We\'ll nudge you again a bit later';

  @override
  String get nowDeferReminderTitle => 'Here\'s your nudge';

  @override
  String get nowDeferReminderBody => 'You set a promise aside for later';

  @override
  String get nowAddMorePlan => 'Add another workout promise?';

  @override
  String get planWhatToPromise => 'Which workout will you promise?';

  @override
  String get planPromiseHint => 'Something you think you can keep';

  @override
  String get planActionHint =>
      'e.g., 30 min at the gym, a 10k-step walk after dinner';

  @override
  String get planDescriptionHint =>
      'e.g., Squats and stretching at home, leg workout at gym...';

  @override
  String get dayMonday => 'Mon';

  @override
  String get dayTuesday => 'Tue';

  @override
  String get dayWednesday => 'Wed';

  @override
  String get dayThursday => 'Thu';

  @override
  String get dayFriday => 'Fri';

  @override
  String get daySaturday => 'Sat';

  @override
  String get daySunday => 'Sun';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageKorean => '한국어';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsTheme => 'Color Theme';

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
  String get developerTitle => 'Developer Screen';

  @override
  String get developerAuthSection => 'Authentication & Connection';

  @override
  String get developerMainSection => 'Main Screens';

  @override
  String get developerPlanSection => 'Plan Creation';

  @override
  String get developerDeepLink => 'Deep Links';

  @override
  String get developerDeepLinkFormat => 'Deep Link URL Format:';

  @override
  String get developerScreenSplash => 'Splash';

  @override
  String get developerScreenConnect => 'Connect';

  @override
  String get developerScreenHome => 'Home';

  @override
  String get developerScreenDeveloper => 'Developer';

  @override
  String get developerScreenSettings => 'Settings';

  @override
  String get developerScreenSplashDesc => 'App launch screen';

  @override
  String get developerScreenConnectDesc => 'Partner connection screen';

  @override
  String get developerScreenHomeDesc => 'Now/History/Us tabs';

  @override
  String get developerScreenSettingsDesc => 'Language and theme settings';

  @override
  String get developerScreenActionSelection => 'Action Selection';

  @override
  String get developerScreenActionSelectionDesc => 'Screen 1: Action selection';

  @override
  String get settingsDeveloper => 'Developer Menu';

  @override
  String get usLinkEmailAction => 'Link with Email';

  @override
  String get usLinkEmailTitle => 'Link Email Account';

  @override
  String get usLinkEmailContent =>
      'Enter an email and password to use for login.';

  @override
  String get usEmailLabel => 'Email';

  @override
  String get usPasswordLabel => 'Password';

  @override
  String get usLinkConfirm => 'Link';

  @override
  String headerWithPartner(String name) {
    return 'Together with $name';
  }

  @override
  String get usLinkEmailSuccess => 'Email account linked!';

  @override
  String get historyPartnerVerified => 'Your partner gave props';

  @override
  String get historyMeVerified => 'You gave props';

  @override
  String get frequencyEveryday => 'Every day';

  @override
  String get usMyPlanTitle => 'My promises';

  @override
  String usPartnerPlanTitle(String name) {
    return '$name\'s promises';
  }

  @override
  String get settingsDeveloperDesc => 'Debug menu';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsLogout => 'Log out';

  @override
  String get settingsLogoutDesc => 'Log out of your current account';

  @override
  String get settingsLogoutDialogTitle => 'Log out';

  @override
  String get settingsLogoutDialogContent => 'Log out now?';

  @override
  String get settingsLogoutConfirm => 'Log out';

  @override
  String get settingsDeleteAccount => 'Delete Account';

  @override
  String get settingsDeleteAccountDesc =>
      'Permanently delete your account and records';

  @override
  String get settingsDeleteAccountDialogTitle => 'Delete Account';

  @override
  String get settingsDeleteAccountDialogContent =>
      'Delete your account? Your account, records and proof photos will be erased, and this can\'t be undone. You may be asked to sign in once more to confirm.';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsDelete => 'Delete';

  @override
  String get loginWithEmail => 'Continue with Email';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get login => 'Login';

  @override
  String get signUp => 'Sign Up';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get invalidEmail => 'Invalid email format';

  @override
  String get weakPassword => 'Password must be at least 6 characters';

  @override
  String get userNotFound => 'No account found for that email.';

  @override
  String get settingsAccountDeletedSuccess => 'Account deleted';

  @override
  String get settingsDeleteAccountFailed =>
      'We couldn\'t delete your account. Please try again.';

  @override
  String get settingsDeleteAccountReauthCancelled =>
      'You need to sign in again to delete your account. Nothing was deleted.';

  @override
  String get settingsDeleteAccountWrongPassword =>
      'That password isn\'t right. Please try again.';

  @override
  String get settingsDeleteAccountPasswordTitle => 'Confirm your password';

  @override
  String get settingsDeleteAccountPasswordHint => 'Password';

  @override
  String get reconcileTookRest => 'Took a rest';

  @override
  String get timeChipPassed => 'Passed';

  @override
  String get nowStatusActuallyDone => 'Actually did it';

  @override
  String get timeChipNow => 'Now!';

  @override
  String get timeChipJustNow => 'Just now';

  @override
  String timeChipMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String timeChipHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String timeChipMinutesLeft(int minutes) {
    return '${minutes}m left';
  }

  @override
  String timeChipHoursLeft(int hours) {
    return '${hours}h left';
  }

  @override
  String get timeChipYesterday => 'Yesterday';

  @override
  String timeChipDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get timeChipTomorrow => 'Tomorrow';

  @override
  String get timeChipDayAfterTomorrow => 'Day after tomorrow';

  @override
  String timeChipDaysLeft(int days) {
    return '${days}d left';
  }

  @override
  String timeChipNextWeek(String weekday) {
    return 'Next $weekday';
  }

  @override
  String timeChipDate(int month, int day) {
    return '$month/$day';
  }

  @override
  String get vagueTimeMorning => 'In the morning';

  @override
  String get vagueTimeLunch => 'Around lunch';

  @override
  String get vagueTimeAfternoon => 'In the afternoon';

  @override
  String get vagueTimeEvening => 'In the evening';

  @override
  String get vagueTimeNight => 'At night';

  @override
  String get vagueTimeLateNight => 'Late night';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get comfortingFuture => 'Great job today';

  @override
  String get comfortingLate => 'Late is okay';

  @override
  String get nowDoEarly => 'Do it now';

  @override
  String get nowDoAnytime => 'Do it today';

  @override
  String get timeChipAnytime => 'Anytime today';

  @override
  String get nowNextActionLater =>
      'Not time yet — you can do this later today.';

  @override
  String get nowNextActionAnytime => 'Do this anytime today.';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get notificationSettingsTitle => 'Notification Manager';

  @override
  String get noActiveAlarms => 'No active alarms';

  @override
  String get historyTapToChange => 'Tap to change status';

  @override
  String get settingsBuyDeveloperCoffee => 'Buy the developer a coffee';

  @override
  String get settingsCoffeeSubtitle => 'A warm cup of coffee goes a long way!';

  @override
  String get settingsCoffeePurchasing => 'Processing payment...';

  @override
  String get settingsStoreUnavailable =>
      'Can\'t connect to the store. Please check your settings.';

  @override
  String get planMine => 'Your promise in one line';

  @override
  String get planClearAction => 'Clear';

  @override
  String get planPartnerPreviewWithout =>
      'You can start solo. Connect your partner to give each other props and knocks.';

  @override
  String get planConnectPartner => 'Connect your partner';

  @override
  String get planDayEveryDay => 'Every day';

  @override
  String get planDayWeekdays => 'Weekdays';

  @override
  String planDayCountFormat(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days/week',
      one: '1 day/week',
    );
    return '$_temp0';
  }

  @override
  String planPreviewMeta(String days, String time) {
    return '$days · $time · 28 days';
  }

  @override
  String get planTimeAM => 'AM';

  @override
  String get planTimePM => 'PM';

  @override
  String planTimeFormatNoMinute(String period, int hour) {
    return '$hour $period';
  }

  @override
  String planTimeFormatWithMinute(String period, int hour, String minute) {
    return '$hour:$minute $period';
  }

  @override
  String get planDayPresetThreeDaysLabel => '3 days/wk';

  @override
  String get planDayPresetWeekdaysLabel => 'Weekdays';

  @override
  String get planDayPresetEveryDayLabel => 'Every day';

  @override
  String get planDayPresetWeekendLabel => 'Weekend';

  @override
  String get planTellUsActionFirst => 'Tell us which workout you\'ll do!';

  @override
  String get planSaveError =>
      'We couldn\'t save your promise. Please try again.';

  @override
  String get planCreateTitle => 'New workout promise';

  @override
  String get planEditTitle => 'Edit promise';

  @override
  String planCreateHeaderWithPartner(String name) {
    return 'Which workout will you promise $name?';
  }

  @override
  String get planCreateDaysTitle => 'Which days?';

  @override
  String get planCreateDaysRequired => 'Pick at least one day';

  @override
  String planCreateDaysFromPartner(String name) {
    return 'Matched to $name\'s workout days';
  }

  @override
  String get planCreateDeadlineTitle => 'Done by when?';

  @override
  String get planCreateDeadlineHint => 'We\'ll remind you at this time';

  @override
  String get planCreateDeadlineRequired => 'Pick a deadline';

  @override
  String get planDeadlineMorning => '7 AM';

  @override
  String get planDeadlineNoon => 'Noon';

  @override
  String get planDeadlineEvening => '7 PM';

  @override
  String get planDeadlineNight => '9 PM';

  @override
  String get planDeadlineLateNight => '10 PM';

  @override
  String get planDeadlineCustom => 'Custom';

  @override
  String get planCreateMemoToggle => 'Add a note (optional)';

  @override
  String planCreatePartnerNotice(String name) {
    return 'Miss it and $name will know';
  }

  @override
  String planCreateCtaWithPartner(String name, String nameWithParticle) {
    return '🤙 Pinky promise with $name';
  }

  @override
  String get planCreateCtaSolo => 'Start my promise';

  @override
  String get planEditCta => 'Save changes';

  @override
  String planSavedWithPartner(String name) {
    return 'Workout promise made with $name 🤙';
  }

  @override
  String get planSavedSolo => 'Your workout promise has started 💪';

  @override
  String get planEditSaved => 'Promise updated';

  @override
  String get planDayPresetTwoDaysLabel => '2 days/wk';

  @override
  String get workoutTypeGymLabel => 'Gym';

  @override
  String get workoutTypeGymAction => 'Hit the gym';

  @override
  String get workoutTypeRunningLabel => 'Running';

  @override
  String get workoutTypeRunningAction => 'Run for 30 minutes';

  @override
  String get workoutTypeHomeTrainingLabel => 'Home workout';

  @override
  String get workoutTypeHomeTrainingAction => '20-minute home workout';

  @override
  String get workoutTypeWalkingLabel => 'Walking';

  @override
  String get workoutTypeWalkingAction => 'Walk for 30 minutes';

  @override
  String get workoutTypePilatesLabel => 'Pilates';

  @override
  String get workoutTypePilatesAction => 'Go to Pilates class';

  @override
  String get workoutTypeYogaLabel => 'Yoga';

  @override
  String get workoutTypeYogaAction => '30 minutes of yoga';

  @override
  String get workoutTypeStretchingLabel => 'Stretching';

  @override
  String get workoutTypeStretchingAction => 'Stretch for 10 minutes before bed';

  @override
  String get workoutTypeSwimmingLabel => 'Swimming';

  @override
  String get workoutTypeSwimmingAction => 'Go for a swim';

  @override
  String get workoutTypeClimbingLabel => 'Climbing';

  @override
  String get workoutTypeClimbingAction => 'Go climbing';

  @override
  String get workoutTypeCyclingLabel => 'Cycling';

  @override
  String get workoutTypeCyclingAction => 'Ride a bike for 40 minutes';

  @override
  String get workoutTypeHikingLabel => 'Hiking';

  @override
  String get workoutTypeHikingAction => 'Go hiking';

  @override
  String get workoutTypeStrengthLabel => 'Strength';

  @override
  String get workoutTypeStrengthAction => '30 minutes of strength training';

  @override
  String get workoutTypeDietLabel => 'Diet · no late snacks';

  @override
  String get workoutTypeDietAction => 'No late-night snacks';

  @override
  String get workoutTypeDietName => 'Diet';

  @override
  String get workoutTypeOtherLabel => 'Custom';

  @override
  String get workoutTypeOtherName => 'Workout';

  @override
  String get workoutTypeCyclingName => 'Cycling';

  @override
  String get workoutTypeStrengthName => 'Strength training';

  @override
  String get focusTimerPickerTitle => 'How long do you want to focus?';

  @override
  String get focusTimerPickerSubtitle =>
      'When the timer ends, the \"Done\" note opens automatically.';

  @override
  String focusTimerPresetMin(int minutes) {
    return '$minutes min';
  }

  @override
  String focusTimerCustomHint(int min, int max) {
    return 'Custom ($min–$max min)';
  }

  @override
  String get focusTimerMinuteUnit => 'min';

  @override
  String get focusTimerPickFirst => 'Pick a duration';

  @override
  String focusTimerStart(int minutes) {
    return 'Start $minutes min';
  }

  @override
  String get focusTimerGiveUpTitle => 'Give up the timer?';

  @override
  String get focusTimerGiveUpBody =>
      'Progress isn\'t saved. The promise stays as not done.';

  @override
  String get focusTimerKeepGoing => 'Keep going';

  @override
  String get focusTimerGiveUp => 'Give up';

  @override
  String get focusTimerGiveUpShort => 'Stop';

  @override
  String focusTimerHeader(int minutes) {
    return 'Focus $minutes min';
  }

  @override
  String focusTimerHeaderWithPlan(String title, int minutes) {
    return '$title · $minutes min';
  }

  @override
  String get focusTimerPaused => 'Paused';

  @override
  String get focusTimerDoneNow => 'Done now';

  @override
  String get focusTimerResume => 'Resume';

  @override
  String get focusTimerPause => 'Pause';

  @override
  String get actionNoteHintDefault => 'How did it go? (optional)';

  @override
  String get planTimeUnset => 'Time not set';

  @override
  String get planDaysEveryday => 'Every day';

  @override
  String get planDaysWeekdays => 'Weekdays';

  @override
  String get planDaysWeekend => 'Weekend';

  @override
  String get planStateActive => 'Active';

  @override
  String get planStateDraft => 'Draft';

  @override
  String get planStatePending => 'Awaiting approval';

  @override
  String get planStateRejected => 'Declined';

  @override
  String get planStateCompleted => 'Ended';

  @override
  String get planStateStopped => 'Stopped';

  @override
  String get planCardMenuTooltip => 'Promise options';

  @override
  String get planCardEdit => 'Edit';

  @override
  String get planCardDelete => 'Delete';

  @override
  String get notifyEditorTitle => 'Notifications';

  @override
  String get notifyEditorSubtitleOn =>
      'We\'ll remind you at your promise time.';

  @override
  String get notifyEditorSubtitleOff => 'Track without notifications.';

  @override
  String get notifyEditorPromiseTime => 'Promise time your partner sees';

  @override
  String get notifyEditorDefaultTimeHint =>
      '9 PM is a good default — there\'s still time to give each other props before the day ends.';

  @override
  String get notifyEditorOffWarningTitle => 'Turn off the reminder?';

  @override
  String notifyEditorOffWarningBody(String name) {
    return 'Without a reminder there\'s no deadline, so $name won\'t hear about a missed day.';
  }

  @override
  String get notifyEditorOffWarningConfirm => 'Turn off';

  @override
  String get notifyEditorPrealert => 'Pre-alert';

  @override
  String get notifyEditorOnTime => 'On time';

  @override
  String get notifyEditor5MinBefore => '5 min before';

  @override
  String get notifyEditor10MinBefore => '10 min before';

  @override
  String get notifyEditor30MinBefore => '30 min before';

  @override
  String get notifyEditor1HourBefore => '1 hr before';

  @override
  String get notifyEditorRepeatModeLabel => 'Repeat';

  @override
  String get notifyEditorRepeatDaily => 'Once a day';

  @override
  String get notifyEditorRepeatHourly => 'Every few hours';

  @override
  String get notifyEditorIntervalLabel => 'Interval';

  @override
  String notifyEditorIntervalHours(int count) {
    return 'Every ${count}h';
  }

  @override
  String get notifyEditorWindowStart => 'Start';

  @override
  String get notifyEditorWindowEnd => 'End';

  @override
  String notifyEditorHourlyHint(int interval, int start, int end) {
    return 'We\'ll remind you every ${interval}h from $start:00 to $end:00.';
  }

  @override
  String planTimeHourlyRange(int start, int end, int interval) {
    return '$start:00–$end:00 · every ${interval}h';
  }

  @override
  String promiseChipPenaltyTriggered(String description) {
    return 'Missed it — $description';
  }

  @override
  String promiseChipPenaltyImminentOne(String description) {
    return 'One more miss and it\'s $description';
  }

  @override
  String promiseChipRewardAchieved(String description) {
    return 'Kept it! — $description';
  }

  @override
  String promiseChipRewardImminent(int days, String description) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days more days',
      one: '1 more day',
    );
    return '$_temp0 to win — $description';
  }

  @override
  String promiseChipSafeBoth(int rewardDays, int penaltyBuffer) {
    String _temp0 = intl.Intl.pluralLogic(
      rewardDays,
      locale: localeName,
      other: '$rewardDays days',
      one: '1 day',
    );
    return '$_temp0 to win · $penaltyBuffer more misses and the bet\'s on';
  }

  @override
  String promiseChipSafeRewardOnly(int days, String description) {
    return '$days days to win — $description';
  }

  @override
  String promiseChipSafePenaltyOnly(int buffer, String description) {
    String _temp0 = intl.Intl.pluralLogic(
      buffer,
      locale: localeName,
      other: '$buffer more misses',
      one: 'One more miss',
    );
    return '$_temp0 and it\'s $description';
  }

  @override
  String get promiseSheetTitle => 'The bet';

  @override
  String promiseSheetSubtitle(int success, int failed, int remaining) {
    return 'Settled when the promise ends. So far $success kept · $failed missed · $remaining to go.';
  }

  @override
  String get promiseSheetRewardLabel => 'If kept';

  @override
  String get promiseSheetPenaltyLabel => 'If missed';

  @override
  String promiseSheetRewardTarget(int target, int success) {
    return 'Keep $target days to win — $success so far';
  }

  @override
  String promiseSheetPenaltyImpossible(int target) {
    String _temp0 = intl.Intl.pluralLogic(
      target,
      locale: localeName,
      other: '$target days',
      one: '1 day',
    );
    return '$_temp0 missed — the bet\'s on';
  }

  @override
  String promiseSheetPenaltyJustOne(int target) {
    return 'On at $target missed days — one more miss and it\'s on';
  }

  @override
  String promiseSheetPenaltyBuffer(int target, int buffer) {
    return 'On at $target missed days — $buffer more misses and it\'s on';
  }

  @override
  String get promiseSheetClose => 'Close';

  @override
  String get splashLoggingIn => 'Signing in…';

  @override
  String get emailLoginToggleSignUp => 'No account? Sign up';

  @override
  String get emailLoginToggleLogin => 'Already have an account? Log in';

  @override
  String get settingsSupport => 'Support';

  @override
  String get notificationSettingsNoAlarm => 'No alarm';

  @override
  String notificationSettingsAlarmOff(String timeString) {
    return 'Alarm off ($timeString)';
  }

  @override
  String get notificationSettingsSaveFailed =>
      'Couldn\'t save notification setting. Reverted to the previous one.';

  @override
  String get historyCardFeedbackHint => 'Add a word (optional)';

  @override
  String get historyCardFeedbackButton => 'Props!';

  @override
  String get historyCardAcknowledgePractice => 'Partner props';

  @override
  String get planSummaryMyDone => 'Days I did it';

  @override
  String get planSummaryPartnerVerified => 'Partner props';

  @override
  String planSummaryCount(int count) {
    return '$count';
  }

  @override
  String get connectInviteCodeDetectedTitle =>
      'We found an invite code you copied';

  @override
  String get connectCancel => 'Cancel';

  @override
  String get connectNotice => 'Heads up';

  @override
  String get connectAlreadyConnectedBody =>
      'You\'re already connected with a partner.\nDuoDone connects you with one person at a time.';

  @override
  String get connectOk => 'OK';

  @override
  String get allPlansTitleMine => 'My promises';

  @override
  String get allPlansTitlePartner => 'Your partner\'s promises';

  @override
  String get allPlansEmpty => 'No promises yet';

  @override
  String get allPlansDeleteTitle => 'Delete this promise?';

  @override
  String get allPlansDeleteBody => 'This can\'t be undone.';

  @override
  String get allPlansDeleted => 'Promise deleted.';

  @override
  String get allPlansDeleteFailed =>
      'We couldn\'t delete that. Please try again.';

  @override
  String get allPlansDelete => 'Delete';

  @override
  String get allPlansCancel => 'Cancel';

  @override
  String get historyErrorUnknown => 'Something unexpected went wrong.';

  @override
  String get historyErrorIndexMissing =>
      'A database index is missing for this query.\nPlease screenshot this and send it to the developer.';

  @override
  String get historyErrorAlreadyDeleted =>
      'This record or promise was already deleted,\nso a reaction can\'t be left.';

  @override
  String get historyErrorTitle => 'Something went wrong';

  @override
  String get historyErrorCreationLink => 'Creation link:';

  @override
  String get historyOk => 'OK';

  @override
  String get historySectionActive => 'In progress';

  @override
  String get historySectionFinished => 'Finished';

  @override
  String get historyToday => 'Today';

  @override
  String get historyYesterday => 'Yesterday';

  @override
  String get historyDatePattern => 'MMM d (EEE)';

  @override
  String get historyCardDatePattern => 'M/d (EEE)';

  @override
  String get historyWeeklyPulseTitle => 'This week';

  @override
  String get historyWeeklyMeLabel => 'Me';

  @override
  String get historyWeeklyPartnerLabel => 'Partner';

  @override
  String get historyReconcileTitle => 'Fix a past record';

  @override
  String get historyReconcileSubtitle => 'What actually happened on this day?';

  @override
  String get historyReconcileHold => 'Leave it';

  @override
  String get usNoticeTitle => 'Notice';

  @override
  String get usOk => 'OK';

  @override
  String get usProfileSaveFailed =>
      'We couldn\'t save your profile. Please try again.';

  @override
  String get usEditProfile => 'Edit profile';

  @override
  String get usNameLabel => 'Name';

  @override
  String get usStatusLabel => 'Status message';

  @override
  String get usCancel => 'Cancel';

  @override
  String get usSave => 'Save';

  @override
  String get usSeeAll => 'See all >';

  @override
  String get usEmptyMine => 'No promises yet';

  @override
  String get usEmptyPartner => 'Your partner has no active promises';

  @override
  String get usCreatePlanShort => '+ Workout promise';

  @override
  String get usCreatePlan => 'Make a workout promise';

  @override
  String get usDeletePlanTitle => 'Delete this promise?';

  @override
  String get usDeletePlanBody => 'This can\'t be undone.';

  @override
  String get usPlanDeleted => 'Promise deleted.';

  @override
  String get usDeleteFailed => 'We couldn\'t delete that. Please try again.';

  @override
  String get usDelete => 'Delete';

  @override
  String get planDetailPracticeHistory => 'Log';

  @override
  String get planDetailLoadFailed =>
      'Couldn\'t load records. Please try again.';

  @override
  String get planDetailNoRecords => 'No records yet.';

  @override
  String get planDetailNotSavedPlan => 'This promise isn\'t saved yet.';

  @override
  String get planDetailRecordDone => 'Done';

  @override
  String get planDetailRecordSkipped => 'Skipped';

  @override
  String get planDetailRecordRested => 'Rest pass';

  @override
  String get planDetailRecordRescued => 'Partner props';

  @override
  String get planDetailPokeSent => 'Knock sent to your partner.';

  @override
  String get planDetailPokeFailed =>
      'We couldn\'t send that. Please try again.';

  @override
  String get planDetailPokeDoneToday => 'Knocked today';

  @override
  String get planDetailPokeSending => 'Sending…';

  @override
  String get planDetailPokeAsk => 'Send a knock';

  @override
  String get planDetailPokeAlreadyDone => 'Already done today';

  @override
  String get planDetailDayMon => 'Mon';

  @override
  String get planDetailDayTue => 'Tue';

  @override
  String get planDetailDayWed => 'Wed';

  @override
  String get planDetailDayThu => 'Thu';

  @override
  String get planDetailDayFri => 'Fri';

  @override
  String get planDetailDaySat => 'Sat';

  @override
  String get planDetailDaySun => 'Sun';

  @override
  String get planDetailEveryDay => 'Every day';

  @override
  String get planDetailTimeUnset => 'Time not set';

  @override
  String get planDetailNotificationSaved => 'Notification settings saved.';

  @override
  String get planDetailNotificationSaveFailed =>
      'Couldn\'t save notification setting. Reverted to the previous one.';

  @override
  String get planDetailSave => 'Save';

  @override
  String get planDetailStopTitle => 'Stop this promise?';

  @override
  String get planDetailStopBody =>
      'Even if you stop, your record so far is kept.';

  @override
  String get planDetailCancel => 'Cancel';

  @override
  String get planDetailStopped => 'Promise stopped.';

  @override
  String get planDetailActionFailed =>
      'Something went wrong. Please try again.';

  @override
  String get planDetailStop => 'Stop';

  @override
  String get planDetailRestartTitle => 'Restart with the same promise?';

  @override
  String get planDetailRestartBody =>
      'We\'ll copy the previous promise as-is.\nYou can edit it before starting.';

  @override
  String get planDetailRestart => 'Restart';

  @override
  String get planDetailReplaceBody =>
      'Your current promise will be stopped and you\'ll move to create a new one.\nExisting records are kept safe.';

  @override
  String get planDetailRestartWithScheduleTitle =>
      'Restart with a new schedule?';

  @override
  String get nowFocusNoteDoneJustNow => 'Focused and completed!';

  @override
  String nowFocusNoteDoneFor(String duration) {
    return 'Focused for $duration and completed!';
  }

  @override
  String nowFocusDurationMinSec(int minutes, int seconds) {
    return '$minutes min $seconds sec';
  }

  @override
  String nowFocusDurationMin(int minutes) {
    return '$minutes min';
  }

  @override
  String nowFocusDurationSec(int seconds) {
    return '$seconds sec';
  }

  @override
  String get nowTodayPromiseFallback => 'Today\'s promise';

  @override
  String get nowSkipDialogTitle => 'Skip today?';

  @override
  String nowSkipDialogBody(String title) {
    return '\'$title\' will count as missed today, and your partner will be told. Your streak together may reset.';
  }

  @override
  String get nowCancel => 'Cancel';

  @override
  String get nowSkipToday => 'Skip today';

  @override
  String get nowSkippedSnackbar => 'Skipped today\'s promise.';

  @override
  String get nowApproveCheering => 'Great — it\'s on!';

  @override
  String get nowApproveFailed => 'Couldn\'t accept.';

  @override
  String get nowRejectDialogTitle => 'Want to tweak it a bit?';

  @override
  String get nowRejectLessFrequent => 'Lower the frequency';

  @override
  String get nowRejectDifferentTime => 'Try a different time slot';

  @override
  String get nowRejectCustom => 'I\'ll write my own';

  @override
  String get nowRejectRequested => 'Sent your suggestion';

  @override
  String get nowRejectCustomDialogTitle => 'What would you change?';

  @override
  String get nowRejectCustomHint =>
      'e.g. How about starting with 3 times a week?';

  @override
  String get nowSend => 'Send';

  @override
  String get nowCheerFailed => 'Couldn\'t send cheer.';

  @override
  String get nowPokeNoActivityMessage =>
      'Knock knock! Make a workout promise — I\'ve got your back 🙂';

  @override
  String get nowPokeSent => 'Knock sent.';

  @override
  String get nowPokeFailed => 'Couldn\'t send the knock.';

  @override
  String get nowPokeAgainMessage =>
      'Knock knock! Waiting on today\'s promise 🙂';

  @override
  String get nowPokeAgainSent => 'Knock sent to your partner.';

  @override
  String get nowSettlementSaved => 'Saved your 4-week wrap-up.';

  @override
  String get nowExitDialogTitle => 'Wrap up this 4-week round here?';

  @override
  String get nowExitReasonWeakPoke => 'Knocks didn\'t really help';

  @override
  String get nowExitReasonTooBig => 'The goal was too big';

  @override
  String get nowExitReasonPartnerBurden => 'Backing each other felt like a lot';

  @override
  String get nowExitReasonCustomLabel => 'Other';

  @override
  String get nowExitReasonCustomHint =>
      'Optionally, a brief note on wrapping up';

  @override
  String get nowExitReasonNoCustom => 'No custom reason';

  @override
  String get nowExitSubmit => 'Submit';

  @override
  String get nowRestPassTitle => 'Use rest pass';

  @override
  String get nowRestPassBody =>
      'Use this week\'s rest pass.\nYour streak stays intact.';

  @override
  String get nowRestPassConfirm => 'Use it';

  @override
  String get nowRestPassUsed => 'Rest well today. Your streak is safe!';

  @override
  String get nowRestPassAlreadyUsed =>
      'You already used this week\'s rest pass.';

  @override
  String get nowRestPassError => 'Something went wrong.';

  @override
  String get nowRescuedSnackbar => 'Props given! Their streak lives on.';

  @override
  String get nowRescueFailed => 'Couldn\'t give props.';

  @override
  String get nowPromiseAccepted => 'Bet\'s on! 🤝';

  @override
  String get nowPromiseDeclined => 'Passed on this bet.';

  @override
  String get nowPromiseResponseFailed => 'Couldn\'t answer the bet.';

  @override
  String get nowPromiseProposed => 'Bet proposed!';

  @override
  String get nowPromiseProposeFailed => 'Couldn\'t propose the bet.';

  @override
  String nowTimeMinBeforeAlert(int minutes) {
    return '${minutes}m before alert';
  }

  @override
  String nowTimeHourBeforeAlert(int hours) {
    return '${hours}h before alert';
  }

  @override
  String nowTimeMinAfterAlert(int minutes) {
    return '${minutes}m after alert';
  }

  @override
  String nowTimeHourAfterAlert(int hours) {
    return '${hours}h after alert';
  }

  @override
  String get nowErrorTitle => 'Something went wrong';

  @override
  String get nowErrorCreationLink => 'Creation link:';

  @override
  String get nowOk => 'OK';

  @override
  String get nowRetryLater => 'Please try again later';

  @override
  String get nowPartnerActionFallback => 'Your partner\'s promise';

  @override
  String get nowActionNoteHint => 'Add a word (optional)';

  @override
  String get nowVerifyAndSend => 'Give props & send';

  @override
  String nowStreakCount(int count) {
    return '$count in a row!';
  }

  @override
  String get nowHeaderAdjustNeeded => 'Adjustment needed';

  @override
  String get nowHeaderPromiseProposed => 'A bet proposal arrived';

  @override
  String get nowHeaderPromiseSettled => 'The bet result is in';

  @override
  String get nowPromiseAckButton => 'See the result';

  @override
  String get nowPromiseAckDialogTitle => 'Bet result';

  @override
  String get nowPromiseAckDialogHint => 'A word for your partner (optional)';

  @override
  String get nowPromiseAckDialogConfirm => 'Got it';

  @override
  String get nowPromiseAckSnackbar => 'Result checked';

  @override
  String get nowPromiseAckFailed => 'Couldn\'t confirm the result';

  @override
  String get planDetailViewList => 'List';

  @override
  String get planDetailViewCalendar => 'Calendar';

  @override
  String get planDetailViewGraph => 'Graph';

  @override
  String get planDetailLegendDone => 'Done';

  @override
  String get planDetailLegendRested => 'Rest pass';

  @override
  String get planDetailLegendRescued => 'Props';

  @override
  String get planDetailLegendSkipped => 'Skipped';

  @override
  String get planDetailLegendMissed => 'Missed';

  @override
  String get planDetailLegendScheduled => 'Scheduled';

  @override
  String planDetailWeekLabel(int week) {
    return 'Week $week';
  }

  @override
  String get planDetailGraphCompletionRate => 'Weekly completion';

  @override
  String get planDetailGraphEmpty => 'Nothing to plot yet.';

  @override
  String get planDetailProgressTitle => 'Progress';

  @override
  String get planDetailProgressSuccessRate => 'Success rate';

  @override
  String planDetailProgressFractionDays(int done, int total) {
    return '$done/$total days';
  }

  @override
  String get planDetailProgressStreakLabel => 'Streak';

  @override
  String get planDetailProgressDoneLabel => 'Done';

  @override
  String get planDetailProgressRemainingLabel => 'Left';

  @override
  String get planDetailProgressMissedLabel => 'Missed';

  @override
  String planDetailProgressDayUnit(int n) {
    return '${n}d';
  }

  @override
  String planDetailProgressCountUnit(int n) {
    return '${n}x';
  }

  @override
  String get planDetailProgressNoVerdictYet => 'No verdicts in yet';

  @override
  String get planDetailPromiseProgressTitle => 'Bet progress';

  @override
  String get planDetailPromiseRewardLabel => '🏆 If kept';

  @override
  String get planDetailPromisePenaltyLabel => '⚡ If missed';

  @override
  String planDetailPromiseRewardNeed(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days more days',
      one: '1 more day',
    );
    return '$_temp0 to win';
  }

  @override
  String get planDetailPromiseRewardAchieved => '🎉 Kept it!';

  @override
  String planDetailPromisePenaltyBuffer(int buffer) {
    return '$buffer more misses and the bet\'s on';
  }

  @override
  String get planDetailPromisePenaltyImminent =>
      'One more miss and the bet\'s on';

  @override
  String get planDetailPromisePenaltyTriggered => '⚡ Missed · the bet\'s on';

  @override
  String get planDetailMoreMenu => 'More';

  @override
  String get planDetailMenuRestartCompleted => 'New promise from this one';

  @override
  String get planDetailMenuRestartActive => 'Restart with new schedule';

  @override
  String get planDetailMenuStop => 'Stop promise';

  @override
  String planDetailPromiseSuccessFailBreakdown(int success, int fail) {
    return '$success kept · $fail missed';
  }

  @override
  String get nowHeaderSettlementNeeded => 'Your 4 weeks are up';

  @override
  String get nowHeaderSettlementSub =>
      'Look back on these 4 weeks and decide on the next round.';

  @override
  String get nowMetricCompleted => 'Completed';

  @override
  String get nowMetricPartnerReact => 'Partner props';

  @override
  String get nowMetricMissed => 'Missed days';

  @override
  String nowMetricDaysSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String nowMetricCountSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '1 time',
    );
    return '$_temp0';
  }

  @override
  String get nowSettlementWinMessage =>
      'You hit the goal you set. Nicely done! Decide whether to keep going for another 4 weeks.';

  @override
  String get nowSettlementLoseMessage =>
      'You didn\'t quite reach the goal this time, but the 4 weeks you shared still count. Decide what to adjust for the next round.';

  @override
  String get nowSettlementNeutralMessage =>
      'You made it through the whole 4 weeks together. Decide whether to go another round.';

  @override
  String nowRewardCondition(int days, String description) {
    return 'Keep $days days: $description';
  }

  @override
  String nowPenaltyCondition(int days, String description) {
    return 'Miss $days days: $description';
  }

  @override
  String nowPromiseResult(int success, int fail) {
    return '$success kept / $fail missed';
  }

  @override
  String get nowAchieved => 'Achieved!';

  @override
  String get nowTriggered => 'It\'s on!';

  @override
  String get nowNotMet => 'Not met';

  @override
  String get nowDecline => 'Pass';

  @override
  String get nowAccept => 'I\'m in!';

  @override
  String get nowContinueNext4Weeks => 'Start the next 4 weeks';

  @override
  String get nowStopHere => 'Wrap up this 4-week round here';

  @override
  String get nowModify => 'Modify';

  @override
  String get nowStartFocusTimer => 'Start now! (Focus timer)';

  @override
  String get nowRestToday => 'Rest today (rest pass)';

  @override
  String get nowHeaderTodayAllDone => 'All done for today 🎉';

  @override
  String nowHeaderConfirmAndPull(String name) {
    return '$name did it! Give them props?';
  }

  @override
  String nowHeaderWaiting(String name) {
    return 'Waiting for $name\'s promise';
  }

  @override
  String get nowHeaderWaitingAccept => 'Waiting for them to accept the bet';

  @override
  String get nowHeaderPromiseResult => 'The bet result is in';

  @override
  String get nowAdjust => 'Let\'s tweak it';

  @override
  String get nowApprove => 'Sounds good!';

  @override
  String get nowPartnerNoNewPlanGuide =>
      'Your partner hasn\'t made a workout promise yet. Send a knock to start together?';

  @override
  String get nowKnockMakePlan => 'Knock! Let\'s do this together';

  @override
  String nowPartnerMissedPokeBody(String name) {
    return '$name hasn\'t done today\'s promise yet. Send a cheer?';
  }

  @override
  String nowPartnerQuietPokeBody(String name) {
    return '$name\'s promise is still quiet. Send a knock to say you\'re waiting?';
  }

  @override
  String get nowKnockPull => 'Send a knock';

  @override
  String get nowRescueYesterday => 'Give props for yesterday';

  @override
  String get nowVerifyAndCheer => 'Give props';

  @override
  String get nowMakePromise => 'Make a bet';

  @override
  String get nowPartnerFallback2 => 'Your partner';

  @override
  String nowPartnerAllDone(String name) {
    return '$name kept every promise today 🎉';
  }

  @override
  String get nowQuickCheckHelp => 'Giving props keeps them going tomorrow.';

  @override
  String nowLastAction(String title) {
    return 'Last check-in: $title';
  }

  @override
  String nowRewardLine(int days, String description) {
    return '🏆 Keep $days days: $description';
  }

  @override
  String nowPenaltyLine(int days, String description) {
    return '⚡ Miss $days days: $description';
  }

  @override
  String nowResultLine(int success, int fail) {
    return 'Result: $success kept / $fail missed';
  }

  @override
  String get nowWaitingApproval => 'Waiting for approval…';

  @override
  String get nowRewardAchievedTitle => '🎉 Kept it!';

  @override
  String get nowPenaltyTriggeredTitle => '⚡ The bet\'s on!';

  @override
  String get nowBothTitle => '🎉 Kept it! + ⚡ The bet\'s on!';

  @override
  String get nowConditionNotMet => 'Conditions not met';

  @override
  String nowTotalDaysOnly(int days) {
    return 'A $days-day promise';
  }

  @override
  String nowTotalDaysScheduled(int days, int scheduled) {
    return 'A $days-day promise · $scheduled days scheduled';
  }

  @override
  String get nowMakePromiseTitle => 'Make a bet';

  @override
  String get nowMakePromiseSubtitle =>
      'The bet starts once your partner accepts. Bet treats and chores, not money.';

  @override
  String nowProgressLine(int success, int failed, int remaining) {
    return 'So far $success kept · $failed missed · $remaining to go';
  }

  @override
  String nowMaxLimitsLine(int reward, int penalty) {
    return 'Set up to $reward days to keep and up to $penalty misses.';
  }

  @override
  String get nowRewardTitle => '🏆 If kept';

  @override
  String get nowRewardHint => 'e.g. 🍣 sushi date, you pick the movie';

  @override
  String get nowRewardTargetLabel => 'Days to keep';

  @override
  String get nowPenaltyTitle => '⚡ If missed';

  @override
  String get nowPenaltyHint => 'e.g. 🍗 buy the chicken, dishes for a week';

  @override
  String get nowPenaltyTargetLabel => 'Miss limit';

  @override
  String get nowProposePromise => 'Propose the bet';

  @override
  String nowDaysSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String nowMaxDaysLabel(int days) {
    return 'Max $days days';
  }

  @override
  String get nowPokeReceived => 'Your partner sent a knock';

  @override
  String nowPokeReceivedFromName(String name) {
    return '$name sent a knock';
  }

  @override
  String get nowNoteDateToday => 'Today';

  @override
  String get connectErrorSelfCode => 'You can\'t use your own invite code.';

  @override
  String get connectErrorFailed =>
      'That code is invalid, or the connection failed.';

  @override
  String get connectErrorDisconnectFailed =>
      'Couldn\'t disconnect. Please try again.';

  @override
  String get accountLinkErrorAlreadyInUse =>
      'This account is already linked to another user.';

  @override
  String get accountLinkErrorInvalidCredential =>
      'The credentials are invalid.';

  @override
  String get accountLinkErrorNotAllowed => 'This operation isn\'t allowed.';

  @override
  String get accountLinkErrorGeneric =>
      'Something went wrong while linking your account.';

  @override
  String get planCreateErrorNoUser =>
      'We couldn\'t find your account. Please sign in again.';

  @override
  String get notifyBannerTitle => 'Notifications are off';

  @override
  String get notifyBannerBody =>
      'Turn them on so you don\'t miss your partner\'s props and knocks.';

  @override
  String get notifyBannerAction => 'Turn on';

  @override
  String get nowActionFailed => 'Something went wrong. Please try again.';

  @override
  String get usNameRequired => 'Please enter a name.';

  @override
  String get usImagePickFailed =>
      'We couldn\'t use that image. Please try another one.';

  @override
  String get settingsLogoutFailed =>
      'We couldn\'t sign you out. Please try again.';

  @override
  String get settingsDeletingAccount => 'Deleting your account…';

  @override
  String get authErrorInvalidCredential =>
      'That email or password isn\'t right.';

  @override
  String get authErrorUserNotFound => 'We couldn\'t find that account.';

  @override
  String get authErrorEmailInUse => 'That email is already signed up.';

  @override
  String get authErrorInvalidEmail => 'That email address isn\'t valid.';

  @override
  String get authErrorWeakPassword =>
      'Please use a password of at least 6 characters.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Please try again in a moment.';

  @override
  String get authErrorNetwork => 'Check your connection and try again.';

  @override
  String get authErrorGeneric => 'Sign-in failed. Please try again.';

  @override
  String get tutorialSkip => 'Skip';

  @override
  String get tutorialClose => 'Close';

  @override
  String get tutorialNext => 'Next';

  @override
  String get tutorialStart => 'Get started';

  @override
  String get tutorialFooter => 'One workout promise is all it takes to start.';

  @override
  String get tutorialPage1Title => 'Make a workout promise';

  @override
  String get tutorialPage1Body =>
      'Gym, running, home workouts — pick what and when, then promise it to your partner. It\'s much harder to skip than a promise to yourself.';

  @override
  String get tutorialPage2Title => 'Your partner sees it, and gives props';

  @override
  String get tutorialPage2Body =>
      'Snap a proof photo after your workout and your partner sees it right away. One tap from them is props — and they\'ll knock on the days you forget.';

  @override
  String get tutorialPage3Title => 'Both done? That\'s DuoDone';

  @override
  String get tutorialPage3Body =>
      'When you both work out, that\'s a DuoDone day. Watch the days you\'ve stacked up together.';

  @override
  String get appUpdateRequiredTitle => 'Update required';

  @override
  String get appUpdateRequiredBody =>
      'This version is no longer supported. Update to the latest version to keep going.';

  @override
  String get appUpdateButton => 'Update';

  @override
  String get appUpdateSoftTitle => 'A new version is here';

  @override
  String get appUpdateSoftBody =>
      'Update to get the latest features and fixes.';

  @override
  String get appUpdateLater => 'Later';

  @override
  String get appUpdateStoreOpenFailed =>
      'Couldn\'t open the store. Please update from the store app.';

  @override
  String get nowHeaderPartnerAskedAdjust => 'Your partner suggested a tweak';

  @override
  String get nowHeaderPokeWaiting => 'Knock knock! Your partner is waiting';

  @override
  String nowHeaderMissedNotice(String name) {
    return 'No check-in yet today, so $name got a heads-up';
  }

  @override
  String nowHeaderPartnerMissed(String name) {
    return '$name\'s promise is still open today';
  }

  @override
  String get nowHeaderPokeTurn => 'Your turn to send a knock';

  @override
  String get promiseUntitledFallback => 'Promise';

  @override
  String planSummaryWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String get settingsTutorialTitle => 'How it works';

  @override
  String get settingsTutorialDesc =>
      'See again how workout promises and props work';

  @override
  String get notifActionDidIt => 'Did it';

  @override
  String get notifActionSkipToday => 'Skip today';

  @override
  String get notifActionSnooze => 'Remind me in 10 min';

  @override
  String get notifActionProps => '❤️ Give props';

  @override
  String get notifActionCheer => '💪 Send a cheer';

  @override
  String get notifReminderBody => 'One check-in and today is logged 📸';

  @override
  String get notifFallbackTitle => 'DuoDone';

  @override
  String get notifChannelRemindersName => 'Promise reminders';

  @override
  String get notifChannelRemindersDesc =>
      'Reminders at the times you set for your promises';

  @override
  String get notifChannelGeneralName => 'Partner updates';

  @override
  String get notifChannelGeneralDesc =>
      'Props, knocks, and cheers from your partner';

  @override
  String get notifChannelScheduledName => 'Scheduled reminders';

  @override
  String get notifChannelScheduledDesc => 'Notifications at a time you picked';

  @override
  String get notifChannelDebugName => 'Test notifications';

  @override
  String get notifChannelDebugDesc => 'For testing notifications';

  @override
  String nowHeroQuestion(String emoji, String workout) {
    return '$emoji $workout done today?';
  }

  @override
  String nowHeroQuestionDiet(String emoji, String workout) {
    return '$emoji $workout on track today?';
  }

  @override
  String nowHeroQuestionLegacy(String title) {
    return 'Did you do \'$title\' today?';
  }

  @override
  String get nowProofTakePhoto => '📸 Take a proof photo';

  @override
  String get nowHeroVerifyLegacy => 'Check in';

  @override
  String get nowDidItNoPhoto => 'Did it, no photo';

  @override
  String get proofSourceSheetTitle => 'Add a proof photo';

  @override
  String get proofSourceCamera => '📸 Take with camera';

  @override
  String get proofSourceCameraHint => 'Shows as just taken';

  @override
  String get proofSourceGallery => '🖼️ Choose from album';

  @override
  String get proofSourceGalleryHint => 'Shows as an album photo with its date';

  @override
  String get proofConsentTitle => 'Before your first proof photo';

  @override
  String get proofConsentOnlyPartner => 'Only your partner can see it.';

  @override
  String get proofConsentLocationRemoved =>
      'Location and other photo info are removed before upload.';

  @override
  String get proofConsentAfterDisconnect =>
      'If you disconnect, it can no longer be seen in the app.';

  @override
  String get proofConsentNoInappropriate =>
      'Please don\'t upload inappropriate photos.';

  @override
  String get proofConsentAgree => 'Got it';

  @override
  String get proofPreviewTitle => 'Send this proof?';

  @override
  String get proofPreviewSubmit => 'Send proof';

  @override
  String get proofUploadDone => 'Proof photo sent 📸';

  @override
  String get proofUploadFailed =>
      'Couldn\'t upload the photo, but today\'s record is saved.';

  @override
  String get proofPhotoPrepareFailed =>
      'Couldn\'t use that photo. Please try another one.';

  @override
  String get proofPickFailed => 'Couldn\'t open the camera or album.';

  @override
  String proofBadgeCamera(String time) {
    return '📸 Just taken · $time';
  }

  @override
  String get proofBadgeCameraJustNow => '📸 Just taken';

  @override
  String proofBadgeCameraOn(String when) {
    return '📸 Camera · $when';
  }

  @override
  String proofBadgeGalleryTaken(String date) {
    return '🖼️ Album · taken $date';
  }

  @override
  String get proofBadgeGallery => '🖼️ Album';

  @override
  String get proofPhotoLoadFailed => 'Couldn\'t load the photo';

  @override
  String get proofPhotoRetry => 'Try again';

  @override
  String get proofPhotoSemantics => 'Proof photo';

  @override
  String get proofViewerMenu => 'More';

  @override
  String get proofViewerReport => 'Report';

  @override
  String get proofViewerDelete => 'Delete photo';

  @override
  String get proofDeleteConfirmTitle => 'Delete this proof photo?';

  @override
  String get proofDeleteConfirmBody =>
      'Your partner won\'t see it anymore. The record itself stays.';

  @override
  String get proofDeleteConfirm => 'Delete';

  @override
  String get proofDeleted => 'Proof photo deleted.';

  @override
  String get proofDeleteFailed =>
      'Couldn\'t delete the photo. Please try again.';

  @override
  String get proofReportSubject => '[DuoDone] Report a proof photo';

  @override
  String proofReportBody(String actionId) {
    return 'Please tell us what\'s wrong with this photo.\n\nRecord ID: $actionId';
  }

  @override
  String proofReportMailFailed(String email) {
    return 'Couldn\'t open your mail app. Please email us at $email.';
  }

  @override
  String get nowReactHint => 'One tap gives props';

  @override
  String get nowReactAddNote => 'Add a note';

  @override
  String nowReactSemantics(String emoji) {
    return 'Give props with $emoji';
  }

  @override
  String nowReactedSnackbar(String emoji) {
    return 'Props sent $emoji';
  }

  @override
  String get partnerFallbackLabel => 'your partner';

  @override
  String get partnerFallbackLabelStart => 'Your partner';

  @override
  String get connectShareInvite => 'Send an invite';

  @override
  String get connectCopyCode => 'Copy code';

  @override
  String get connectHaveCodeTitle => 'Got a code from your partner?';

  @override
  String get connectInviteSent =>
      'Invite sent. We\'ll let you know when your partner joins.';

  @override
  String get connectShareFailed =>
      'Couldn\'t open the share sheet. Copy the code and send it instead.';

  @override
  String get connectErrorCodeNotFound =>
      'We couldn\'t find anyone with that code. Please check it and try again.';

  @override
  String get connectErrorCodeFormat => 'Codes are 8 letters and numbers.';

  @override
  String get connectErrorOwnerTaken =>
      'That code\'s owner is already connected to someone. Ask them for a new code.';

  @override
  String get connectErrorSelfTaken =>
      'You\'re already connected to a partner. Disconnect first, then try again.';

  @override
  String get connectErrorCodeChanged =>
      'That code has changed. Ask your partner for the new one.';

  @override
  String get connectErrorLinkUndone =>
      'The connection didn\'t hold. The code may belong to someone who\'s already connected — ask for a new code.';

  @override
  String inviteShareMessage(String code, String link) {
    return 'I made a workout promise 🤙 Back me up! Get DuoDone and enter code $code to connect → $link';
  }

  @override
  String inviteShareMessageNoPromise(String code, String link) {
    return 'I\'m making a workout promise 🤙 Back me up! Get DuoDone and enter code $code to connect → $link';
  }

  @override
  String get inviteShareSubject => 'DuoDone invite';

  @override
  String get inviteHaveCodeLink => 'I got an invite code';

  @override
  String connectConfirmTitle(String name) {
    return 'Back $name\'s workout promises?';
  }

  @override
  String get connectConfirmBody =>
      'Once connected, you\'ll see each other\'s workout promises and proof photos.';

  @override
  String get connectConfirmAccept => 'I\'ve got you';

  @override
  String connectSuccessTitle(String name) {
    return 'You\'re connected with $name 🎉';
  }

  @override
  String get connectSuccessBody =>
      'Now you can back each other\'s workout promises.';

  @override
  String get connectSuccessAskTitle => 'Make one too?';

  @override
  String get connectSuccessAskBody => 'When you both do it, that\'s DuoDone.';

  @override
  String get connectSuccessMakePromise => 'Make mine';

  @override
  String get connectSuccessLater => 'Later';

  @override
  String get connectSuccessDone => 'Great';

  @override
  String get connectHowTitle => 'How it works';

  @override
  String get connectHowProof => 'Work out, then post a proof photo';

  @override
  String get connectHowAck =>
      'One tap on your partner\'s photo gives them props';

  @override
  String get connectHowDuo => 'A day you both work out is a DuoDone day';

  @override
  String get nicknameSheetTitle => 'What do you call your partner?';

  @override
  String nicknameSheetBody(String name) {
    return 'We\'ll show this instead of $name in the app and notifications.';
  }

  @override
  String get nicknamePresetPartner => 'Partner';

  @override
  String get nicknamePresetJagi => 'Babe';

  @override
  String get nicknamePresetOppa => 'Honey';

  @override
  String get nicknamePresetYeobo => 'Love';

  @override
  String get nicknamePresetAegi => 'Baby';

  @override
  String get nicknamePresetCustom => 'Type my own';

  @override
  String get nicknameCustomHint => 'Nickname (up to 10 characters)';

  @override
  String get nicknameSave => 'Save';

  @override
  String get nicknameLater => 'I\'ll decide later';

  @override
  String get nicknameRemove => 'Remove nickname';

  @override
  String get nicknameSaved => 'Nickname saved.';

  @override
  String get nicknameRemoved => 'Nickname removed.';

  @override
  String get nicknameSaveFailed =>
      'Couldn\'t save the nickname. Please try again.';

  @override
  String get usSetNickname => 'Set a nickname';

  @override
  String get usEditNickname => 'Change nickname';

  @override
  String get onboardingInviteLater => 'I\'ll invite later';

  @override
  String get nowInviteCardTitle =>
      'You actually do it when your partner sees it';

  @override
  String get nowInviteCardBody =>
      'Send an invite so you can back each other\'s workout promises.';

  @override
  String get nowInviteCardWaitingTitle => 'Waiting for your partner';

  @override
  String get nowInviteCardWaitingBody =>
      'They haven\'t joined yet. Send it again?';

  @override
  String get nowInviteCardResend => 'Send it again';

  @override
  String get pivotNoticeTitle => 'Nod&Try is now DuoDone';

  @override
  String get pivotNoticeBody =>
      'Your promises, history and partner connection are all still here.';

  @override
  String get pivotNoticeOk => 'Got it';

  @override
  String duoStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Together for $count days',
      one: 'Together for 1 day',
    );
    return '$_temp0';
  }

  @override
  String get duoStreakStart => 'Both check in today for day 1';

  @override
  String get duoTodayDone => 'You both did it today 🎉';

  @override
  String get duoMeLabel => 'Me';

  @override
  String get duoStatusDone => 'done ✓';

  @override
  String get duoStatusVerified => 'props ❤️';

  @override
  String get duoStatusWaiting => 'awaiting props';

  @override
  String get duoStatusPending => 'not yet';

  @override
  String get duoStatusRested => 'rest pass';

  @override
  String get duoStatusOff => 'day off';

  @override
  String get duoStatusMissed => 'missed';

  @override
  String get duoStatusUpcoming => 'coming up';

  @override
  String duoPersonStatus(String name, String status) {
    return '$name · $status';
  }

  @override
  String duoWeekDuoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count duo days',
      one: '1 duo day',
      zero: 'No duo days yet',
    );
    return '$_temp0';
  }

  @override
  String duoDaySemantics(String day, String me, String partner) {
    return '$day: me $me, partner $partner';
  }

  @override
  String get duoShareButton => 'Make a share card';

  @override
  String shareCardStreak(int count) {
    return '#DuoDone $count-day streak';
  }

  @override
  String get shareCardNoStreak => '#DuoDone';

  @override
  String get shareCardStores => 'Search \'DuoDone\' in your app store';

  @override
  String shareCardPersonDone(String name, String workout) {
    return '$name ✓ $workout';
  }

  @override
  String shareCardPersonOff(String name) {
    return '$name · day off';
  }

  @override
  String shareCardPersonRested(String name) {
    return '$name · rest pass';
  }

  @override
  String shareCardPersonPending(String name) {
    return '$name · not yet';
  }

  @override
  String get shareCardSheetTitleToday =>
      'You both did it today 🎉 Show it off?';

  @override
  String shareCardSheetTitleMilestone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days together 🎉 Show it off?',
    );
    return '$_temp0';
  }

  @override
  String get shareCardSheetTitleManual => 'Share card';

  @override
  String get shareCardShare => 'Share';

  @override
  String get shareCardLater => 'Later';

  @override
  String get shareCardFailed => 'Couldn\'t make the share card.';

  @override
  String get shareCardOnlyMyPhoto => 'Only your own photo goes on the card.';

  @override
  String get shareCardText =>
      '#DuoDone When your partner sees it, you actually do it.';

  @override
  String get shareCardSemantics => 'DuoDone share card';

  @override
  String get nowPokeReplyComing => 'On my way 🏃';

  @override
  String get nowPokeReplyPass => 'Go easy on me 🙏';

  @override
  String get nowPokeReplySent => 'Reply sent';

  @override
  String get nowPokeReplyFailed => 'Couldn\'t send the reply.';

  @override
  String get nowSendCheer => 'Send a cheer';

  @override
  String get nowCheerDefaultMessage => 'You\'ve got this! I\'m waiting 💪';

  @override
  String get nowCheerSent => 'Cheer sent';

  @override
  String get nowKnockSentToday => 'Knocked today';

  @override
  String get promisePenaltyChicken => '🍗 Buy the chicken';

  @override
  String get promisePenaltyCoffee => '☕ Buy the iced coffee';

  @override
  String get promisePenaltyDishes => '🍽️ Dishes for a week';

  @override
  String get promisePenaltyMassage => '💆 10-minute massage';

  @override
  String get promisePenaltyMovie => '🎬 They pick the movie';

  @override
  String get promisePenaltyPickup => '🚗 Pick-up duty';

  @override
  String get promiseRewardOmakase => '🍣 Omakase together';

  @override
  String get promiseRewardDessert => '🍰 Dessert date';

  @override
  String get promiseRewardMassage => '💆 A 10-minute massage';

  @override
  String get promiseRewardMovie => '🎬 You pick the movie';

  @override
  String get promiseMoneyBlocked =>
      'Money bets aren\'t supported. Bet something you can do together, like a meal, coffee or the dishes.';

  @override
  String notifReminderBodyWithPartner(String name) {
    return 'No check-in yet? We\'ll let $name know soon.';
  }

  @override
  String get nowRecordQueued =>
      'Saved. It\'ll reach your partner once you\'re back online.';

  @override
  String get settingsAboutSection => 'About';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsTermsOfUse => 'Terms of use';

  @override
  String get settingsContactSupport => 'Contact support';

  @override
  String get settingsContactSupportSubject => '[DuoDone] Support';

  @override
  String settingsLinkOpenFailed(String email) {
    return 'Couldn\'t open it. You can reach us at $email.';
  }

  @override
  String get usReportPartner => 'Report partner';

  @override
  String get usReportPartnerSubject => '[DuoDone] Report a partner';

  @override
  String usReportPartnerBody(String uid) {
    return 'Tell us what\'s wrong (a photo, note or message). We\'ll review it and act.\n\nReported account ID: $uid';
  }

  @override
  String get termsViewLink => 'View terms of use';

  @override
  String get termsNoticeConnect =>
      'By connecting you agree to the Terms of Use. Objectionable content and abusive behavior aren\'t tolerated — reported content and accounts are removed.';

  @override
  String get termsNoticeInvite =>
      'Sending an invite means you agree to the Terms of Use. Objectionable content and abuse aren\'t tolerated.';

  @override
  String get termsNoticePhoto =>
      'By posting you agree to the Terms of Use. Objectionable photos and abuse aren\'t tolerated.';

  @override
  String get planSavedInviteTitle =>
      'Promise made! Ask your partner to back you up?';

  @override
  String get planSavedInviteBody =>
      'With your partner watching, you\'ll actually do it. Send them your code and link.';
}
