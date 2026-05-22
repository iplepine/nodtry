// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Nod&Try';

  @override
  String get splashTagline => 'Plans we couldn\'t keep alone, together';

  @override
  String get loginWithGoogle => 'Continue with Google';

  @override
  String get loginWithApple => 'Continue with Apple';

  @override
  String get loginGuest => 'Start without login';

  @override
  String get privacyMessage =>
      'We don\'t push.\nYour records are private between you two.';

  @override
  String get connectHeadline => 'Want to entrust this month to someone?';

  @override
  String get connectSubtitle =>
      'You make the plan, and your partner manages it.';

  @override
  String get createInviteCode => 'Create Invite Code';

  @override
  String get enterInviteCode => 'Enter Invite Code';

  @override
  String get startSolo => 'Start Solo';

  @override
  String get inviteCode => 'Invite Code';

  @override
  String get copyCode => 'Copy';

  @override
  String get shareCode => 'Share';

  @override
  String get codeCopied => 'Code copied';

  @override
  String get codeShareMessage => 'Share this code with your partner';

  @override
  String get enterCodeBelow => 'Enter the code below';

  @override
  String get sendConnectionRequest => 'Send Connection Request';

  @override
  String get waitingForConnection => 'Your partner is reviewing the connection';

  @override
  String get homeNowTask => 'You can do it now';

  @override
  String get homeDidIt => 'Did it';

  @override
  String get homeReceivedMessage => 'I\'ll do this';

  @override
  String get homeCheckIt => 'Nod&Try';

  @override
  String get homeSentWaiting => 'I sent my work';

  @override
  String get homeWaitingForCheck => 'Waiting for confirmation';

  @override
  String get homeQuietDay => 'You can rest for a while now';

  @override
  String get homeChecked => 'Okay';

  @override
  String get homeThankYou => 'Thank you';

  @override
  String get timePassedActorMessage => 'No record delivered yet';

  @override
  String get timePassedManagerMessage => 'No words delivered yet';

  @override
  String get timePassedActorSubMessage => 'It\'s okay to start now';

  @override
  String get timePassedManagerSubMessage => 'The day is passing quietly';

  @override
  String get pastUncompletedMessage => 'Scheduled a little while ago';

  @override
  String get pastUncompletedSubMessage => 'There was a previous promise';

  @override
  String get pastUncompletedTimeChip => 'Just before';

  @override
  String homeContextWeek(int week, int total) {
    return '$week of $total weeks';
  }

  @override
  String homeContextEntrusted(String name) {
    return 'Entrusted to $name';
  }

  @override
  String homeContextManaging(String name) {
    return 'Managing $name';
  }

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
  String get usYouTitle => 'You';

  @override
  String get usProfileEdit => 'Edit';

  @override
  String get usStatusMessagePlaceholder => 'Set status message';

  @override
  String get usMyIntroduction => 'My Introduction';

  @override
  String get usMyInviteCode => 'My Invite Code';

  @override
  String get usBadgeSupported => 'Supported';

  @override
  String get usBadgeCheering => 'Cheering';

  @override
  String get usGuestWarningMessage =>
      'If you change phone or delete app/data, you may lose records.';

  @override
  String get usGuestWarningAction => 'Link Account to Keep Records';

  @override
  String get usLinkSuccess => 'Google account linked successfully!';

  @override
  String usLinkError(String error) {
    return 'Account linking failed: $error';
  }

  @override
  String get usLoadError => 'Error loading connections';

  @override
  String get usNoInviteCode => 'No Code';

  @override
  String get usNoName => 'No Name';

  @override
  String get usUnknownUser => 'Unknown User';

  @override
  String get usDisconnectDialogTitle => 'Disconnect';

  @override
  String usDisconnectDialogContent(String name) {
    return 'Disconnect from $name?';
  }

  @override
  String get usDisconnectConfirm => 'Disconnect';

  @override
  String get usDisconnectSuccess => 'Disconnected successfully.';

  @override
  String usDisconnectError(String error) {
    return 'Disconnection failed: $error';
  }

  @override
  String get usDisconnectTooltip => 'Disconnect';

  @override
  String get usCropImageTitle => 'Crop Profile Image';

  @override
  String get cancel => 'Cancel';

  @override
  String get usProfileEditImageLabel => 'Change profile picture';

  @override
  String get usAddConnectionLabel => 'Add new connection';

  @override
  String get usBadgeMutual => 'Together';

  @override
  String get usEmptyMatesTitle => 'No mates connected yet';

  @override
  String get usEmptyMatesSubtitle =>
      'Send your invite code to become each other\'s safe base';

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
    return '$week of $total weeks';
  }

  @override
  String get headerNoPlan => 'No plan yet';

  @override
  String get headerPlanEnded => 'Plan ended';

  @override
  String get nowNoPlan => 'What promises shall we make this month?';

  @override
  String get nowCreatePlan => 'Create Plan';

  @override
  String nowNextActionIn(String time) {
    return 'Next action in $time';
  }

  @override
  String nowNextActionDays(int days) {
    return 'Next schedule in D-$days';
  }

  @override
  String get nowQuietRest => 'You can rest for a while now';

  @override
  String get nowQuietNoAction => 'No need to worry for a while';

  @override
  String get nowNoPlanSubtitle => 'Shall we make just one promise?';

  @override
  String get nowTodayDone => 'Took care of everything today 🙌';

  @override
  String nowTodayAllDone(int count) {
    return 'Took care of all $count today 🙌';
  }

  @override
  String get nowPartnerProposed => 'Proposed this promise';

  @override
  String get nowPartnerAdjusting => 'Adjusting the promise a bit';

  @override
  String get nowPartnerDidIt => 'I did it!';

  @override
  String get nowActionPass => 'Just skip';

  @override
  String get nowActionSkipToday => 'Let\'s skip today';

  @override
  String get nowAddMorePlan => 'Shall we make another promise?';

  @override
  String recordGazeWeekCount(int count) {
    return '${count}th promise this week';
  }

  @override
  String recordGazeWeekProgress(int week, int total) {
    return 'Week $week of $total';
  }

  @override
  String recordGazeDoneCount(int count) {
    return 'Already done $count times';
  }

  @override
  String get managerSuggestionTitle => 'If you entrust this promise to someone';

  @override
  String get managerSuggestionSubtitle => 'it might become a little easier';

  @override
  String get managerSuggestionAlternative =>
      'If keeping it alone is hard, you can try together';

  @override
  String get managerSuggestionButton => 'Find someone to entrust';

  @override
  String get managerSuggestionQuestion =>
      'Is there someone who can take care of this promise?';

  @override
  String get planProposal => 'My Promise';

  @override
  String get planPreparing => 'Preparing promise';

  @override
  String get planWhatToPromise => 'What would you like to promise?';

  @override
  String get planPromiseHint => 'Something you think you can keep';

  @override
  String get planMyPromise => 'A promise I made to myself';

  @override
  String get planKeepWatching => 'A promise I want to keep';

  @override
  String get planActionHint =>
      'e.g., Spending time with kids, Making time to read';

  @override
  String get planOneLineEnough => 'Just one line is enough';

  @override
  String get planNext => 'Next';

  @override
  String get planFrequencyTitle => 'How about this much?';

  @override
  String get planFrequencySubtitle =>
      'It\'s okay if you don\'t keep it perfectly';

  @override
  String get planDescriptionTitle => 'You can write it in detail if you want';

  @override
  String get planDescriptionSubtitle => 'You can change it later';

  @override
  String get planDescriptionLabel => 'What specifically would you like to do?';

  @override
  String get planDescriptionExample => 'e.g., Squats and stretching at home';

  @override
  String get planDescriptionHint =>
      'e.g., Squats and stretching at home, leg workout at gym...';

  @override
  String get planDescriptionSkip => 'Skip';

  @override
  String get planDescriptionOptional => 'You can skip this step';

  @override
  String get planDayTitle => 'You don\'t have to set days';

  @override
  String get planDaySubtitle =>
      'But choosing them can make it easier to remember.';

  @override
  String get planDaySkip => 'I\'ll decide based on how I feel that day';

  @override
  String get planSummaryTitle => 'This is what I\'ll propose';

  @override
  String get planSummaryFrequency => 'Frequency';

  @override
  String get planSummaryDay => 'Days';

  @override
  String get planSummaryDescription => 'Description';

  @override
  String get planSummaryDayConditional => 'Decide based on condition';

  @override
  String get planSummaryInfo =>
      'This is a proposal. Your partner will review and decide together.';

  @override
  String get planSummaryAdjustable =>
      'You can adjust anytime if it\'s too much';

  @override
  String get planSummarySend => 'I\'ll do this';

  @override
  String get planSummarySent => 'Plan proposal has been sent';

  @override
  String get planFrequencyLight => 'Lightly';

  @override
  String get planFrequencyModerate => 'Moderately';

  @override
  String get planFrequencyMore => 'A bit more';

  @override
  String get planFrequencyWeekly2 => '2 times/week';

  @override
  String get planFrequencyWeekly3 => '3 times/week';

  @override
  String get planFrequencyWeekly4 => '4 times/week';

  @override
  String get planFrequencyLightWithCount => 'Lightly (2 times/week)';

  @override
  String get planFrequencyModerateWithCount => 'Moderately (3 times/week)';

  @override
  String get planFrequencyMoreWithCount => 'A bit more (4 times/week)';

  @override
  String get connectConnected => 'Connected';

  @override
  String get connectGoToHome => 'Go to Home';

  @override
  String get usPlanSection => 'Plan';

  @override
  String get usNoPlanMessage => 'No current plan';

  @override
  String get usNoPlanSubtitle => 'Would you like to start a new promise?';

  @override
  String get usStartNewPlan => 'Start New Plan';

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
  String get developerScreenLogin => 'Login';

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
  String get developerScreenLoginDesc => 'Google/Apple login';

  @override
  String get developerScreenConnectDesc => 'Couple connection screen';

  @override
  String get developerScreenHomeDesc => 'Now/History/Us tabs';

  @override
  String get developerScreenSettingsDesc => 'Language and theme settings';

  @override
  String get developerScreenActionSelection => 'Action Selection';

  @override
  String get developerScreenFrequency => 'Frequency';

  @override
  String get developerScreenDaySelection => 'Day Selection';

  @override
  String get developerScreenDescription => 'Description';

  @override
  String get developerScreenSummary => 'Summary';

  @override
  String get developerScreenActionSelectionDesc => 'Screen 1: Action selection';

  @override
  String get developerScreenFrequencyDesc => 'Screen 2: Repeat frequency';

  @override
  String get developerScreenDaySelectionDesc => 'Screen 4: Day selection';

  @override
  String get developerScreenDescriptionDesc =>
      'Screen 3: Specific action description';

  @override
  String get developerScreenSummaryDesc => 'Screen 5: Plan proposal summary';

  @override
  String get settingsPlanCreation => 'Plan Creation';

  @override
  String get settingsPlanCreationTitle => 'Create New Promise';

  @override
  String get settingsPlanCreationDesc => 'All steps in one screen';

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
    return 'With $name';
  }

  @override
  String get usLinkEmailSuccess => 'Email account linked successfully!';

  @override
  String get historyPartnerVerified => 'Partner verified';

  @override
  String get historyMeVerified => 'I verified';

  @override
  String get frequencyEveryday => 'Everyday';

  @override
  String get planNotificationTimeOptional => 'Notification time (Optional)';

  @override
  String get usMyPlanTitle => 'My Promise';

  @override
  String usPartnerPlanTitle(String name) {
    return '$name\'s Promise';
  }

  @override
  String get vagueTimeDinner => 'Dinner';

  @override
  String get vagueTimeBedtime => 'Bedtime';

  @override
  String get cheerSimple => 'Okay';

  @override
  String get cheerMore => 'More';

  @override
  String get cheerSheetTitle => 'How to Cheer?';

  @override
  String get cheerMessageHint => 'Leave a cheer message';

  @override
  String get cheerSend => 'Send';

  @override
  String get doneSheetTitle => 'Share your thoughts';

  @override
  String get doneMessageHint => 'Leave a short note';

  @override
  String get doneButton => 'Complete';

  @override
  String get settingsDeveloperDesc => 'Debug menu';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsLogout => 'Log out';

  @override
  String get settingsLogoutDesc => 'Log out from your current account';

  @override
  String get settingsLogoutDialogTitle => 'Log out';

  @override
  String get settingsLogoutDialogContent => 'Are you sure you want to log out?';

  @override
  String get settingsLogoutConfirm => 'Log out';

  @override
  String get settingsDeleteAccount => 'Delete Account';

  @override
  String get settingsDeleteAccountDesc =>
      'Permanently delete your account and data';

  @override
  String get settingsDeleteAccountDialogTitle => 'Delete Account';

  @override
  String get settingsDeleteAccountDialogContent =>
      'Are you sure you want to delete your account? This action cannot be undone.';

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
  String get emailStartMessage => 'Start with Email';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get invalidEmail => 'Invalid email format';

  @override
  String get weakPassword => 'Password must be at least 6 characters';

  @override
  String get accountExistsWithDifferentCredential =>
      'Account already exists with a different credential';

  @override
  String get userNotFound => 'No user found for that email.';

  @override
  String get wrongPassword => 'Wrong password provided for that user.';

  @override
  String get settingsAccountDeletedSuccess => 'Account deleted successfully';

  @override
  String get settingsAuthServiceNotFound => 'Auth Service not found';

  @override
  String settingsDeleteAccountFailed(Object error) {
    return 'Failed to delete account: $error';
  }

  @override
  String get reconcileTitle => 'Reconcile';

  @override
  String get reconcileActuallyDone => 'Actually did it';

  @override
  String get reconcileTookRest => 'Took a break today';

  @override
  String get reconcileSkip => 'Skip';

  @override
  String get reconcileDoneMessage => 'Record has been reconciled.';

  @override
  String get historyFilterAll => 'All';

  @override
  String get historyFilterMe => 'My Action';

  @override
  String get historyFilterPartner => 'Partner\'s Action';

  @override
  String get historyMyActionVerified => 'Partner saw it';

  @override
  String get historyPartnerActionVerified => 'Saw it';

  @override
  String get historyPartnerActionWaiting => 'Not seen yet';

  @override
  String get historyActionSawIt => 'Saw it 👍';

  @override
  String get historyActionCheer => 'Cheering you 💜';

  @override
  String get timeChipStillActionable => 'Still actionable';

  @override
  String get timeChipPassed => 'Passed';

  @override
  String get nowStatusActuallyDone => 'Actually did it';

  @override
  String get nowLateCompletion => 'Completed even if late!';

  @override
  String get nowLateJustInTime => 'Did it a bit late';

  @override
  String get nowWithinToday => 'Done within today';

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
  String get planTimeQuestion => 'When should I notify you?';

  @override
  String get comfortingFuture => 'Great job today';

  @override
  String get comfortingLate => 'Late is okay';

  @override
  String get comfortingJustDoIt => 'Just do it today';

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
  String get planMostlyProcrastinated => 'What you usually put off';

  @override
  String get planRecommendedPromises => 'Suggested promises';

  @override
  String get planMine => 'My promise';

  @override
  String get planClearAction => 'Clear';

  @override
  String get planRecommendedFrequency => 'Suggested frequency';

  @override
  String get planNoDayMeansDaily =>
      'Without picking days, this becomes a daily promise.';

  @override
  String get planPartnerFallback => 'your partner';

  @override
  String get planActionFallback => 'my promise';

  @override
  String get planPartnerPreviewLabel => 'Here\'s how your partner sees it';

  @override
  String planPartnerPreviewWith(String name, String promise) {
    return '$name will be asked to nudge you on \"$promise\" without missing a beat for 28 days.';
  }

  @override
  String get planPartnerPreviewWithout =>
      'Without a partner there\'s no one to receive the poke. Connect one before saving for stronger pressure.';

  @override
  String get planConnectPartner => 'Connect a partner';

  @override
  String get planDayEveryDay => 'Every day';

  @override
  String get planDayWeekdays => 'Weekdays';

  @override
  String planDayCountFormat(int count) {
    return '$count days/week';
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
    return '$period $hour';
  }

  @override
  String planTimeFormatWithMinute(String period, int hour, String minute) {
    return '$period $hour:$minute';
  }

  @override
  String planTemplatePerWeek(String label, int count) {
    return '$label · $count/wk';
  }

  @override
  String get planCategoryStudyLabel => 'Study';

  @override
  String get planCategoryStudyDescription =>
      'Self-study you keep putting off — English, certifications, coding';

  @override
  String get planCategoryExerciseLabel => 'Exercise';

  @override
  String get planCategoryExerciseDescription =>
      'Movement that\'s hard to start — walking, gym, stretching';

  @override
  String get planCategoryCustomLabel => 'Custom';

  @override
  String get planCategoryCustomDescription =>
      'Write your own promise without picking a template';

  @override
  String get planTemplateEnglishLabel => 'English';

  @override
  String get planTemplateEnglishAction => 'Read 10 English sentences aloud';

  @override
  String get planTemplateEnglishDescription =>
      'Aim for low-pressure daily exposure to English.';

  @override
  String get planTemplateCertificateLabel => 'Certification';

  @override
  String get planTemplateCertificateAction => 'Solve 10 past exam questions';

  @override
  String get planTemplateCertificateDescription =>
      'Repeat a fixed count without breaking the streak instead of cramming.';

  @override
  String get planTemplateCodingLabel => 'Coding';

  @override
  String get planTemplateCodingAction => '30 min of coding or one problem';

  @override
  String get planTemplateCodingDescription =>
      'Secure the days you actually touch code before chasing big goals.';

  @override
  String get planTemplateReadingLabel => 'Reading';

  @override
  String get planTemplateReadingAction => 'Read 10 pages and log one line';

  @override
  String get planTemplateReadingDescription =>
      'Leave a one-line trace so your partner can check in easily.';

  @override
  String get planTemplateWritingLabel => 'Writing';

  @override
  String get planTemplateWritingAction => 'Write for 15 min or 300 characters';

  @override
  String get planTemplateWritingDescription =>
      'Focus on starting days, not finished pieces.';

  @override
  String get planTemplateWalkingLabel => 'Walking';

  @override
  String get planTemplateWalkingAction => 'Walk 30 minutes';

  @override
  String get planTemplateWalkingDescription =>
      'Commit to stepping outside before worrying about gear.';

  @override
  String get planTemplateGymLabel => 'Gym';

  @override
  String get planTemplateGymAction => 'Go to the gym and work out for 30 min';

  @override
  String get planTemplateGymDescription =>
      'Increase days you arrive at the gym rather than perfect workouts.';

  @override
  String get planTemplateStretchingLabel => 'Stretching';

  @override
  String get planTemplateStretchingAction => 'Stretch for 10 minutes';

  @override
  String get planTemplateStretchingDescription =>
      'Show your partner even a short loosen-up.';

  @override
  String get planDayPresetThreeDaysLabel => '3 days/wk';

  @override
  String get planDayPresetWeekdaysLabel => 'Weekdays';

  @override
  String get planDayPresetEveryDayLabel => 'Every day';

  @override
  String get planDayPresetWeekendLabel => 'Weekend';

  @override
  String get planDayPresetStudyThreeDaysDesc =>
      'Build three wins in the first week';

  @override
  String get planDayPresetStudyWeekdaysDesc =>
      'Anchor your study to the weekdays';

  @override
  String get planDayPresetStudyEveryDayDesc =>
      'Show your partner something each day, even briefly';

  @override
  String get planDayPresetExerciseThreeDaysDesc =>
      'Start with a Mon/Wed/Fri rhythm';

  @override
  String get planDayPresetExerciseWeekendDesc =>
      'Leave a movement trace on weekends';

  @override
  String get planDayPresetExerciseEveryDayDesc =>
      'Get daily check-ins like a short stretch';

  @override
  String get planDayPresetCustomThreeDaysDesc => 'A low-pressure default';

  @override
  String get planDayPresetCustomWeekdaysDesc =>
      'Lock it in as a weekday routine';

  @override
  String get planDayPresetCustomEveryDayDesc =>
      'Leave a small action every day';

  @override
  String planStepHeader(int current, int total) {
    return 'Preparing promise · $current/$total';
  }

  @override
  String get planTellUsActionFirst => 'Tell us what you want to promise!';

  @override
  String get planProposalSaved =>
      'Proposal saved.\nGo chat about it with your partner!';

  @override
  String planSaveError(String error) {
    return 'An error occurred while saving: $error';
  }

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
  String get actionNoteHintDefault => 'Share your thoughts (optional)';

  @override
  String get planTimeUnset => 'Time not set';

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
  String get planDescriptionTip => 'Tip: try \"If X, then Y\"';

  @override
  String get planDescriptionExamples =>
      'e.g. \"When I get home from work, I change into workout clothes\"\ne.g. \"When the kids fall asleep, I read for 30 minutes\"';

  @override
  String get planDescriptionTipFooter =>
      'A specific situation makes you 2–3× more likely to follow through!';

  @override
  String get notifyEditorTitle => 'Notifications';

  @override
  String get notifyEditorSubtitleOn => 'Pick when we should poke you.';

  @override
  String get notifyEditorSubtitleOff => 'Track without notifications.';

  @override
  String get notifyEditorPromiseTime => 'Promise time visible to your partner';

  @override
  String get notifyEditorDefaultTimeHint =>
      '9 PM by default is a good time for your partner to check before the day slips by.';

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
  String promiseChipPenaltyTriggered(String description) {
    return '⚡ Penalty locked in — $description';
  }

  @override
  String promiseChipPenaltyImminentOne(String description) {
    return '⚡ Just one more miss triggers the penalty — $description';
  }

  @override
  String promiseChipPenaltyImminent(int count, String description) {
    return '⚡ $count more misses triggers the penalty — $description';
  }

  @override
  String promiseChipRewardAchieved(String description) {
    return '🏆 Reward earned! — $description';
  }

  @override
  String promiseChipRewardImminent(int days, String description) {
    return '🏆 $days more day(s) to the reward — $description';
  }

  @override
  String promiseChipSafeBoth(int rewardDays, int penaltyBuffer) {
    return '🏆 $rewardDays days to reward · ⚡ $penaltyBuffer misses safe';
  }

  @override
  String promiseChipSafeRewardOnly(int days, String description) {
    return '🏆 $days days to reward — $description';
  }

  @override
  String promiseChipSafePenaltyOnly(int buffer, String description) {
    return '⚡ $buffer misses safe — $description';
  }

  @override
  String get promiseSheetTitle => 'Promise terms';

  @override
  String promiseSheetSubtitle(int success, int failed, int remaining) {
    return 'Settled when the plan ends. Currently $success done · $failed missed · $remaining days left.';
  }

  @override
  String get promiseSheetRewardLabel => 'Reward';

  @override
  String get promiseSheetPenaltyLabel => 'Penalty';

  @override
  String promiseSheetRewardTarget(int target, int success) {
    return '$target successful days to earn it — currently $success';
  }

  @override
  String promiseSheetPenaltyImpossible(int target) {
    return 'Needed $target successful days but you can no longer reach it — penalty locked in';
  }

  @override
  String promiseSheetPenaltyJustOne(int target) {
    return 'Triggers below $target successful days — you can\'t miss even once more';
  }

  @override
  String promiseSheetPenaltyBuffer(int target, int buffer) {
    return 'Triggers below $target successful days — $buffer more misses are safe';
  }

  @override
  String get promiseSheetClose => 'Close';

  @override
  String splashLoginFailed(String error) {
    return 'Login failed: $error';
  }

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
  String get historyCardFeedbackHint => 'Leave a warm note (optional)';

  @override
  String get historyCardFeedbackButton => 'OK';

  @override
  String get historyCardAcknowledgePractice => 'Acknowledge practice';

  @override
  String get planSummaryMyDone => 'My completions';

  @override
  String get planSummaryPartnerVerified => 'Partner verified';

  @override
  String planSummaryCount(int count) {
    return '$count';
  }

  @override
  String get connectInviteCodeDetectedTitle => 'Invite code detected';

  @override
  String connectInviteCodeDetectedBody(String code) {
    return 'We found an invite code ($code) in your clipboard.\nPaste it?';
  }

  @override
  String get connectCancel => 'Cancel';

  @override
  String get connectPaste => 'Paste';

  @override
  String get connectNotice => 'Notice';

  @override
  String get connectAlreadyConnectedBody =>
      'You already have a connected partner.\nMultiple partners will be supported later.';

  @override
  String get connectOk => 'OK';

  @override
  String get connectSuccess => 'Connected!';

  @override
  String get allPlansTitleMine => 'My promises';

  @override
  String get allPlansTitlePartner => 'Partner\'s promises';

  @override
  String get allPlansEmpty => 'No promises yet';

  @override
  String get allPlansDeleteTitle => 'Delete this promise?';

  @override
  String get allPlansDeleteBody => 'This can\'t be undone.';

  @override
  String get allPlansDeleted => 'Promise deleted.';

  @override
  String allPlansDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get allPlansDelete => 'Delete';

  @override
  String get allPlansCancel => 'Cancel';

  @override
  String get historyErrorUnknown => 'An unknown error occurred.';

  @override
  String get historyErrorIndexMissing =>
      'Database index missing for this query.\nPlease screenshot this and send it to the developer.';

  @override
  String get historyErrorAlreadyDeleted =>
      'This record or promise was already deleted,\nso a reaction can\'t be left.';

  @override
  String get historyErrorTitle => 'Error';

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
  String get historyDatePattern => 'EEEE, MMM d, yyyy';

  @override
  String get historyReconcileTitle => 'Reconcile past record';

  @override
  String get historyReconcileSubtitle => 'What actually happened on this day?';

  @override
  String get historyReconcileHold => 'Leave it';

  @override
  String get usNoticeTitle => 'Notice';

  @override
  String get usOk => 'OK';

  @override
  String usProfileSaveFailed(String error) {
    return 'Profile save failed: $error';
  }

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
  String get usEmptyPartner => 'Partner has no active promises';

  @override
  String get usCreatePlanShort => '+ New promise';

  @override
  String get usCreatePlan => 'New promise';

  @override
  String get usDeletePlanTitle => 'Delete this promise?';

  @override
  String get usDeletePlanBody => 'This can\'t be undone.';

  @override
  String get usPlanDeleted => 'Promise deleted.';

  @override
  String usDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get usDelete => 'Delete';

  @override
  String get planDetailPracticeHistory => 'Practice log';

  @override
  String planDetailLoadFailed(String error) {
    return 'Couldn\'t load records.\n$error';
  }

  @override
  String get planDetailNoRecords => 'No records yet.';

  @override
  String get planDetailNotSavedPlan => 'Plan not saved.';

  @override
  String get planDetailRecordDone => 'Done';

  @override
  String get planDetailRecordSkipped => 'Skipped';

  @override
  String get planDetailRecordRested => 'Rested';

  @override
  String get planDetailRecordRescued => 'Acknowledged';

  @override
  String get planDetailPokeSent => 'Knock knock — door tapped!';

  @override
  String planDetailPokeFailed(String error) {
    return 'Send failed: $error';
  }

  @override
  String get planDetailPokeDoneToday => 'Knock sent for today';

  @override
  String get planDetailPokeSending => 'Sending…';

  @override
  String get planDetailPokeAsk => 'Knock knock… are you forgetting?';

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
  String planDetailActionFailed(String error) {
    return 'Action failed: $error';
  }

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
  String get planDetailReport => 'Practice report';

  @override
  String get planDetailReportPeriod => 'Total period';

  @override
  String planDetailReportDays(int count) {
    return '$count days';
  }

  @override
  String get planDetailReportCompleted => 'Completions';

  @override
  String planDetailReportCount(int count) {
    return '$count times';
  }

  @override
  String get planDetailReportRate => 'Achievement rate';

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
    return 'We\'ll mark $title as skipped for today.';
  }

  @override
  String get nowCancel => 'Cancel';

  @override
  String get nowSkipToday => 'Skip today';

  @override
  String get nowSkippedSnackbar => 'Skipped today\'s promise.';

  @override
  String get nowApproveCheering => 'Cheering you on!';

  @override
  String get nowApproveFailed => 'Approval failed.';

  @override
  String get nowVerifyDone => 'Practice verified!';

  @override
  String get nowVerifyFailed => 'Verification failed.';

  @override
  String get nowRejectDialogTitle => 'Want to adjust a bit more?';

  @override
  String get nowRejectLessFrequent => 'Lower the frequency';

  @override
  String get nowRejectDifferentTime => 'Try a different time slot';

  @override
  String get nowRejectCustom => 'Custom message';

  @override
  String get nowRejectRequested => 'Adjustment requested';

  @override
  String get nowRejectCustomDialogTitle => 'What would you like to adjust?';

  @override
  String get nowRejectCustomHint =>
      'e.g. How about starting with 3 times a week?';

  @override
  String get nowSend => 'Send';

  @override
  String get nowCheerExcited => 'Sent excited support! 🔥';

  @override
  String get nowCheerLove => 'Sent your love! ❤️';

  @override
  String get nowCheerProud => 'Said you\'re awesome! 👍';

  @override
  String get nowCheerStrength => 'Said hang in there! 💪';

  @override
  String get nowCheerFailed => 'Couldn\'t send cheer.';

  @override
  String get nowPokeNoActivityMessage =>
      'Knock knock! Someone\'s waiting for a promise. Want to make today\'s?';

  @override
  String get nowPokeSent => 'Sent a knock signal.';

  @override
  String get nowPokeFailed => 'Couldn\'t send the knock.';

  @override
  String get nowPokeAgainMessage =>
      'Knock knock! Your partner is waiting. Want to firm up today\'s promise?';

  @override
  String get nowPokeAgainSent => 'Knock knock — pulled the promise again.';

  @override
  String get nowSettlementSaved => '4-week settlement saved.';

  @override
  String get nowExitDialogTitle => 'Stop here for this 4-week round?';

  @override
  String get nowExitReasonWeakPoke => 'The knock pressure was weak';

  @override
  String get nowExitReasonTooBig => 'The goal was too big';

  @override
  String get nowExitReasonPartnerBurden => 'Partner verification felt heavy';

  @override
  String get nowExitReasonCustomLabel => 'Other';

  @override
  String get nowExitReasonCustomHint => 'Briefly say why you\'re stopping';

  @override
  String get nowExitReasonNoCustom => 'No custom reason';

  @override
  String get nowExitSubmit => 'Submit';

  @override
  String get nowRestPassTitle => 'Use rest pass';

  @override
  String get nowRestPassBody =>
      'Use one rest pass this week.\nYour streak stays intact.';

  @override
  String get nowRestPassConfirm => 'Use it';

  @override
  String get nowRestPassUsed => 'Rest well today. Your streak is safe!';

  @override
  String get nowRestPassAlreadyUsed =>
      'You already used this week\'s rest pass.';

  @override
  String get nowRestPassError => 'An error occurred.';

  @override
  String get nowRescuedSnackbar =>
      'Acknowledged the practice! Streak preserved.';

  @override
  String get nowRescueFailed => 'Couldn\'t acknowledge practice.';

  @override
  String get nowPromiseAccepted => 'Accepted the promise!';

  @override
  String get nowPromiseDeclined => 'Declined the promise.';

  @override
  String get nowPromiseResponseFailed => 'Couldn\'t send promise response.';

  @override
  String get nowPromiseProposed => 'Proposed the promise!';

  @override
  String get nowPromiseProposeFailed => 'Couldn\'t propose the promise.';

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
  String get nowKeepFlowing => 'Great! Keep this flow going';

  @override
  String get nowGuideWhen =>
      'Setting \"when to do it\" raises your follow-through';

  @override
  String get nowGuideSmallStart => 'Starting small is fine. Consistency wins';

  @override
  String get nowGuideBetterToday => 'Better than yesterday is enough';

  @override
  String get nowErrorTitle => 'Error';

  @override
  String get nowErrorCreationLink => 'Creation link:';

  @override
  String get nowOk => 'OK';

  @override
  String get nowRetryLater => 'Please try again later';

  @override
  String get nowPartnerActionFallback => 'Partner\'s practice';

  @override
  String get nowActionNoteHint => 'Leave a warm note (optional)';

  @override
  String get nowVerifyAndSend => 'Verify and send';

  @override
  String nowStreakCount(int count) {
    return '$count days in a row!';
  }

  @override
  String get nowHeaderAdjustNeeded => 'Adjustment needed';

  @override
  String get nowHeaderPromiseProposed => 'Promise proposal arrived';

  @override
  String get nowHeaderPromiseSettled => 'Promise result is out';

  @override
  String get nowHeaderSettlementNeeded => '4-week settlement needed';

  @override
  String get nowHeaderSettlementSub =>
      'Confirm whether the knock really pulled the promise and pick the next 4 weeks.';

  @override
  String get nowMetricCompleted => 'Completed';

  @override
  String get nowMetricPartnerReact => 'Partner reactions';

  @override
  String get nowMetricMissed => 'Missed days';

  @override
  String nowMetricDaysSuffix(int count) {
    return '$count days';
  }

  @override
  String nowMetricCountSuffix(int count) {
    return '$count times';
  }

  @override
  String get nowSettlementWinMessage =>
      'You passed the meaningful 12-day mark. Time to decide on the next 4 weeks.';

  @override
  String get nowSettlementLoseMessage =>
      'More important than finishing is noting where you stopped. Leave a reason to make the next attempt easier.';

  @override
  String nowRewardCondition(int days, String description) {
    return '$days successful days: $description';
  }

  @override
  String nowPenaltyCondition(int days, String description) {
    return '$days failed days: $description';
  }

  @override
  String nowPromiseResult(int success, int fail) {
    return 'Successes $success / Failures $fail';
  }

  @override
  String get nowAchieved => 'Achieved!';

  @override
  String get nowTriggered => 'Triggered!';

  @override
  String get nowNotMet => 'Not met';

  @override
  String get nowDecline => 'Decline';

  @override
  String get nowAccept => 'Accept';

  @override
  String get nowContinueNext4Weeks => 'Start the next 4 weeks';

  @override
  String get nowStopHere => 'Stop this 4-week round here';

  @override
  String get nowModify => 'Modify';

  @override
  String get nowStartFocusTimer => 'Start now! (Focus timer)';

  @override
  String get nowRestToday => 'Rest today (rest pass)';

  @override
  String get nowMissedPlanFallback => 'Past promise';

  @override
  String get nowVerifyingDeadline => 'Waiting for verification · cheer needed';

  @override
  String get nowHeaderTodayAllDone => 'All today\'s promises kept';

  @override
  String get nowHeaderConfirmAndPull => 'Time to verify and pull';

  @override
  String get nowHeaderWaiting => 'Waiting';

  @override
  String get nowHeaderWaitingAccept => 'Waiting for promise approval';

  @override
  String get nowHeaderPromiseResult => 'Promise result is out';

  @override
  String get nowAdjust => 'Adjust';

  @override
  String get nowApprove => 'Approve';

  @override
  String get nowPartnerNoNewPlanGuide =>
      'The other person hasn\'t made a new promise. Want to knock before it gets buried?';

  @override
  String get nowKnockMakePlan => 'Knock! Ask to make a promise';

  @override
  String nowPartnerMissedPokeBody(String name) {
    return '$name\'s promise is now a missed promise. Knock to pull it again.';
  }

  @override
  String nowPartnerQuietPokeBody(String name) {
    return '$name\'s promise is still quiet. Knock before it gets buried.';
  }

  @override
  String get nowKnockPull => 'Knock! Pull';

  @override
  String get nowRescueYesterday => 'Acknowledge yesterday';

  @override
  String get nowVerifyAndCheer => 'Verify and cheer';

  @override
  String get nowMakePromise => 'Make a promise';

  @override
  String get nowPartnerFallback2 => 'partner';

  @override
  String nowPartnerAllDone(String name) {
    return '$name kept all today\'s promises.';
  }

  @override
  String get nowQuickCheckHelp =>
      'A quick verification makes tomorrow easier too.';

  @override
  String nowLastAction(String title) {
    return 'Last action: $title';
  }

  @override
  String nowRewardLine(int days, String description) {
    return '🏆 $days successful days: $description';
  }

  @override
  String nowPenaltyLine(int days, String description) {
    return '⚡ $days failed days: $description';
  }

  @override
  String nowResultLine(int success, int fail) {
    return 'Result: Successes $success / Failures $fail';
  }

  @override
  String get nowWaitingApproval => 'Waiting for approval…';

  @override
  String get nowRewardAchievedTitle => '🎉 Reward earned!';

  @override
  String get nowPenaltyTriggeredTitle => '⚡ Penalty triggered!';

  @override
  String get nowBothTitle => '🎉 Reward earned! + ⚡ Penalty triggered!';

  @override
  String get nowConditionNotMet => 'Conditions not met';

  @override
  String nowTotalDaysOnly(int days) {
    return 'A $days-day promise';
  }

  @override
  String nowTotalDaysScheduled(int days, int scheduled) {
    return 'A $days-day promise · $scheduled practice days planned';
  }

  @override
  String get nowMakePromiseTitle => 'Make a promise';

  @override
  String get nowMakePromiseSubtitle => 'It starts once your partner accepts';

  @override
  String nowProgressLine(int success, int failed, int remaining) {
    return 'Currently $success successes · $failed failures · $remaining days remaining';
  }

  @override
  String nowMaxLimitsLine(int reward, int penalty) {
    return 'Reward up to $reward days, penalty up to $penalty days.';
  }

  @override
  String get nowRewardTitle => '🏆 Reward (carrot)';

  @override
  String get nowRewardHint => 'e.g. treat to chicken, fancy dinner';

  @override
  String get nowRewardTargetLabel => 'Success target';

  @override
  String get nowPenaltyTitle => '⚡ Penalty (stick)';

  @override
  String get nowPenaltyHint => 'e.g. dishes for a week, buy coffee';

  @override
  String get nowPenaltyTargetLabel => 'Failure limit';

  @override
  String get nowProposePromise => 'Propose promise';

  @override
  String nowDaysSuffix(int count) {
    return '$count days';
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
  String get nowYesterday => 'Yesterday';
}
