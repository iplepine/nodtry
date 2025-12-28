// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'OnMyBehalf';

  @override
  String get splashTagline => 'Plans we couldn\'t keep alone, together';

  @override
  String get loginWithGoogle => 'Continue with Google';

  @override
  String get loginWithApple => 'Continue with Apple';

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
  String get homeReceivedMessage => 'You have a message';

  @override
  String get homeCheckIt => 'Check it';

  @override
  String get homeSentWaiting => 'Sent';

  @override
  String get homeWaitingForCheck => 'Waiting for confirmation';

  @override
  String get homeQuietDay => 'You can rest for a while now';

  @override
  String get homeChecked => 'Checked';

  @override
  String get homeThankYou => 'Thank you';

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
  String get nowNoPlan => 'No plan for this month yet';

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
  String get planDaySubtitle => 'I\'ll decide based on how I feel that day';

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
  String get planSummarySend => 'I\'ll ask if this is okay';

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
}
