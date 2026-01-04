// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Nod & Try';

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
  String get homeCheckIt => 'Nod & Try';

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
  String get historyEmpty => 'No history yet';

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
  String get settingsThemeSmokyPlum => 'Smoky Plum × Warm Stone';

  @override
  String get settingsThemeDeepOlive => 'Deep Olive × Sand';

  @override
  String get developerTitle => 'Developer Screen';

  @override
  String get developerScreenNavigation => 'Screen Navigation';

  @override
  String get developerScreenNavigationDesc => 'Navigate to any screen directly';

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
  String get settingsDeveloperDesc => 'Debug menu';

  @override
  String get settingsAccount => 'Account';

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
}
