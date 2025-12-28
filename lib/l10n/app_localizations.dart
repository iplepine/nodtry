import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'OnMyBehalf'**
  String get appTitle;

  /// Tagline shown on splash screen
  ///
  /// In en, this message translates to:
  /// **'Plans we couldn\'t keep alone, together'**
  String get splashTagline;

  /// Google login button text
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginWithGoogle;

  /// Apple login button text
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get loginWithApple;

  /// Privacy message shown at bottom of login screen
  ///
  /// In en, this message translates to:
  /// **'We don\'t push.\nYour records are private between you two.'**
  String get privacyMessage;

  /// Headline on connect screen
  ///
  /// In en, this message translates to:
  /// **'Want to entrust this month to someone?'**
  String get connectHeadline;

  /// Subtitle on connect screen
  ///
  /// In en, this message translates to:
  /// **'You make the plan, and your partner manages it.'**
  String get connectSubtitle;

  /// Button to create invite code
  ///
  /// In en, this message translates to:
  /// **'Create Invite Code'**
  String get createInviteCode;

  /// Button to enter invite code
  ///
  /// In en, this message translates to:
  /// **'Enter Invite Code'**
  String get enterInviteCode;

  /// Button to start without connecting to a partner
  ///
  /// In en, this message translates to:
  /// **'Start Solo'**
  String get startSolo;

  /// Label for invite code
  ///
  /// In en, this message translates to:
  /// **'Invite Code'**
  String get inviteCode;

  /// Button to copy code
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyCode;

  /// Button to share code
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareCode;

  /// Message when code is copied
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get codeCopied;

  /// Message below invite code
  ///
  /// In en, this message translates to:
  /// **'Share this code with your partner'**
  String get codeShareMessage;

  /// Instruction to enter code
  ///
  /// In en, this message translates to:
  /// **'Enter the code below'**
  String get enterCodeBelow;

  /// Button to send connection request
  ///
  /// In en, this message translates to:
  /// **'Send Connection Request'**
  String get sendConnectionRequest;

  /// Message while waiting for connection
  ///
  /// In en, this message translates to:
  /// **'Your partner is reviewing the connection'**
  String get waitingForConnection;

  /// Message when there's a task to report
  ///
  /// In en, this message translates to:
  /// **'You can do it now'**
  String get homeNowTask;

  /// Button to report completion
  ///
  /// In en, this message translates to:
  /// **'Did it'**
  String get homeDidIt;

  /// Message when there's a verification needed
  ///
  /// In en, this message translates to:
  /// **'You have a message'**
  String get homeReceivedMessage;

  /// Button to check verification
  ///
  /// In en, this message translates to:
  /// **'Check it'**
  String get homeCheckIt;

  /// Message when report is sent and waiting
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get homeSentWaiting;

  /// Message while waiting for partner's check
  ///
  /// In en, this message translates to:
  /// **'Waiting for confirmation'**
  String get homeWaitingForCheck;

  /// Message when there's nothing to do
  ///
  /// In en, this message translates to:
  /// **'You can rest for a while now'**
  String get homeQuietDay;

  /// Message when report is checked
  ///
  /// In en, this message translates to:
  /// **'Checked'**
  String get homeChecked;

  /// Thank you message after check
  ///
  /// In en, this message translates to:
  /// **'Thank you'**
  String get homeThankYou;

  /// Week context information
  ///
  /// In en, this message translates to:
  /// **'{week} of {total} weeks'**
  String homeContextWeek(int week, int total);

  /// Context about who is managing
  ///
  /// In en, this message translates to:
  /// **'Entrusted to {name}'**
  String homeContextEntrusted(String name);

  /// Context about who is being managed
  ///
  /// In en, this message translates to:
  /// **'Managing {name}'**
  String homeContextManaging(String name);

  /// Now tab label
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get tabNow;

  /// History tab label
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// Us tab label
  ///
  /// In en, this message translates to:
  /// **'Us'**
  String get tabUs;

  /// Empty state message for history tab
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get historyEmpty;

  /// Section title for connected people
  ///
  /// In en, this message translates to:
  /// **'Connected People'**
  String get usConnectedPeople;

  /// Status label for managing someone
  ///
  /// In en, this message translates to:
  /// **'Managing'**
  String get usManaging;

  /// Status label for being managed
  ///
  /// In en, this message translates to:
  /// **'Entrusted'**
  String get usEntrusted;

  /// Button to invite new person
  ///
  /// In en, this message translates to:
  /// **'Invite New Person'**
  String get usInviteNew;

  /// Empty state message for us tab
  ///
  /// In en, this message translates to:
  /// **'No connections yet'**
  String get usNoConnections;

  /// Week progress in header
  ///
  /// In en, this message translates to:
  /// **'{week} of {total} weeks'**
  String headerWeekProgress(int week, int total);

  /// Message when there's no plan
  ///
  /// In en, this message translates to:
  /// **'No plan yet'**
  String get headerNoPlan;

  /// Message when plan period ended
  ///
  /// In en, this message translates to:
  /// **'Plan ended'**
  String get headerPlanEnded;

  /// Message when there's no active plan
  ///
  /// In en, this message translates to:
  /// **'No plan for this month yet'**
  String get nowNoPlan;

  /// Button to create a new plan
  ///
  /// In en, this message translates to:
  /// **'Create Plan'**
  String get nowCreatePlan;

  /// Message showing time until next action
  ///
  /// In en, this message translates to:
  /// **'Next action in {time}'**
  String nowNextActionIn(String time);

  /// Message showing days until next schedule
  ///
  /// In en, this message translates to:
  /// **'Next schedule in D-{days}'**
  String nowNextActionDays(int days);

  /// Quiet state message - rest
  ///
  /// In en, this message translates to:
  /// **'You can rest for a while now'**
  String get nowQuietRest;

  /// Quiet state message - no action needed
  ///
  /// In en, this message translates to:
  /// **'No need to worry for a while'**
  String get nowQuietNoAction;

  /// Record gaze - showing count in current week
  ///
  /// In en, this message translates to:
  /// **'{count}th promise this week'**
  String recordGazeWeekCount(int count);

  /// Record gaze - showing week progress
  ///
  /// In en, this message translates to:
  /// **'Week {week} of {total}'**
  String recordGazeWeekProgress(int week, int total);

  /// Record gaze - showing completion count
  ///
  /// In en, this message translates to:
  /// **'Already done {count} times'**
  String recordGazeDoneCount(int count);

  /// Manager suggestion title - soft approach
  ///
  /// In en, this message translates to:
  /// **'If you entrust this promise to someone'**
  String get managerSuggestionTitle;

  /// Manager suggestion subtitle
  ///
  /// In en, this message translates to:
  /// **'it might become a little easier'**
  String get managerSuggestionSubtitle;

  /// Alternative manager suggestion text
  ///
  /// In en, this message translates to:
  /// **'If keeping it alone is hard, you can try together'**
  String get managerSuggestionAlternative;

  /// Button to find manager - soft approach
  ///
  /// In en, this message translates to:
  /// **'Find someone to entrust'**
  String get managerSuggestionButton;

  /// Question to suggest manager - soft approach
  ///
  /// In en, this message translates to:
  /// **'Is there someone who can take care of this promise?'**
  String get managerSuggestionQuestion;

  /// Title for plan proposal screens - solo-first approach
  ///
  /// In en, this message translates to:
  /// **'My Promise'**
  String get planProposal;

  /// Progress hint for plan preparation
  ///
  /// In en, this message translates to:
  /// **'Preparing promise'**
  String get planPreparing;

  /// Title asking what to promise
  ///
  /// In en, this message translates to:
  /// **'What would you like to promise?'**
  String get planWhatToPromise;

  /// Hint about what kind of promise to make
  ///
  /// In en, this message translates to:
  /// **'Something you think you can keep'**
  String get planPromiseHint;

  /// Alternative title for solo plan
  ///
  /// In en, this message translates to:
  /// **'A promise I made to myself'**
  String get planMyPromise;

  /// Alternative title for solo plan
  ///
  /// In en, this message translates to:
  /// **'A promise I want to keep'**
  String get planKeepWatching;

  /// Hint text for action input field
  ///
  /// In en, this message translates to:
  /// **'e.g., Spending time with kids, Making time to read'**
  String get planActionHint;

  /// Message when input is empty
  ///
  /// In en, this message translates to:
  /// **'Just one line is enough'**
  String get planOneLineEnough;

  /// Next button text
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get planNext;

  /// Title for frequency selection screen
  ///
  /// In en, this message translates to:
  /// **'How about this much?'**
  String get planFrequencyTitle;

  /// Subtitle for frequency selection
  ///
  /// In en, this message translates to:
  /// **'It\'s okay if you don\'t keep it perfectly'**
  String get planFrequencySubtitle;

  /// Title for description screen
  ///
  /// In en, this message translates to:
  /// **'You can write it in detail if you want'**
  String get planDescriptionTitle;

  /// Subtitle for description screen
  ///
  /// In en, this message translates to:
  /// **'You can change it later'**
  String get planDescriptionSubtitle;

  /// Label for description input
  ///
  /// In en, this message translates to:
  /// **'What specifically would you like to do?'**
  String get planDescriptionLabel;

  /// Example text for description
  ///
  /// In en, this message translates to:
  /// **'e.g., Squats and stretching at home'**
  String get planDescriptionExample;

  /// Hint text for description input field
  ///
  /// In en, this message translates to:
  /// **'e.g., Squats and stretching at home, leg workout at gym...'**
  String get planDescriptionHint;

  /// Skip button for description screen
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get planDescriptionSkip;

  /// Message that description is optional
  ///
  /// In en, this message translates to:
  /// **'You can skip this step'**
  String get planDescriptionOptional;

  /// Title for day selection screen
  ///
  /// In en, this message translates to:
  /// **'You don\'t have to set days'**
  String get planDayTitle;

  /// Subtitle for day selection
  ///
  /// In en, this message translates to:
  /// **'I\'ll decide based on how I feel that day'**
  String get planDaySubtitle;

  /// Skip button text for day selection
  ///
  /// In en, this message translates to:
  /// **'I\'ll decide based on how I feel that day'**
  String get planDaySkip;

  /// Title for summary screen
  ///
  /// In en, this message translates to:
  /// **'This is what I\'ll propose'**
  String get planSummaryTitle;

  /// Label for frequency in summary
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get planSummaryFrequency;

  /// Label for days in summary
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get planSummaryDay;

  /// Label for description in summary
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get planSummaryDescription;

  /// Text when no days are selected
  ///
  /// In en, this message translates to:
  /// **'Decide based on condition'**
  String get planSummaryDayConditional;

  /// Info message about proposal
  ///
  /// In en, this message translates to:
  /// **'This is a proposal. Your partner will review and decide together.'**
  String get planSummaryInfo;

  /// Message about adjustability
  ///
  /// In en, this message translates to:
  /// **'You can adjust anytime if it\'s too much'**
  String get planSummaryAdjustable;

  /// Button to send proposal
  ///
  /// In en, this message translates to:
  /// **'I\'ll ask if this is okay'**
  String get planSummarySend;

  /// Message when proposal is sent
  ///
  /// In en, this message translates to:
  /// **'Plan proposal has been sent'**
  String get planSummarySent;

  /// Light frequency option label
  ///
  /// In en, this message translates to:
  /// **'Lightly'**
  String get planFrequencyLight;

  /// Moderate frequency option label
  ///
  /// In en, this message translates to:
  /// **'Moderately'**
  String get planFrequencyModerate;

  /// More frequency option label
  ///
  /// In en, this message translates to:
  /// **'A bit more'**
  String get planFrequencyMore;

  /// 2 times per week description
  ///
  /// In en, this message translates to:
  /// **'2 times/week'**
  String get planFrequencyWeekly2;

  /// 3 times per week description
  ///
  /// In en, this message translates to:
  /// **'3 times/week'**
  String get planFrequencyWeekly3;

  /// 4 times per week description
  ///
  /// In en, this message translates to:
  /// **'4 times/week'**
  String get planFrequencyWeekly4;

  /// Light frequency with count for summary
  ///
  /// In en, this message translates to:
  /// **'Lightly (2 times/week)'**
  String get planFrequencyLightWithCount;

  /// Moderate frequency with count for summary
  ///
  /// In en, this message translates to:
  /// **'Moderately (3 times/week)'**
  String get planFrequencyModerateWithCount;

  /// More frequency with count for summary
  ///
  /// In en, this message translates to:
  /// **'A bit more (4 times/week)'**
  String get planFrequencyMoreWithCount;

  /// Message when connection is successful
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connectConnected;

  /// Button to go to home screen
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get connectGoToHome;

  /// Plan section title in Us tab
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get usPlanSection;

  /// Message when there's no plan in Us tab
  ///
  /// In en, this message translates to:
  /// **'No current plan'**
  String get usNoPlanMessage;

  /// Subtitle when there's no plan
  ///
  /// In en, this message translates to:
  /// **'Would you like to start a new promise?'**
  String get usNoPlanSubtitle;

  /// Button to start a new plan
  ///
  /// In en, this message translates to:
  /// **'Start New Plan'**
  String get usStartNewPlan;

  /// Monday abbreviation
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayMonday;

  /// Tuesday abbreviation
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayTuesday;

  /// Wednesday abbreviation
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWednesday;

  /// Thursday abbreviation
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayThursday;

  /// Friday abbreviation
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFriday;

  /// Saturday abbreviation
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get daySaturday;

  /// Sunday abbreviation
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get daySunday;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Korean language option
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get settingsLanguageKorean;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// Theme setting label
  ///
  /// In en, this message translates to:
  /// **'Color Theme'**
  String get settingsTheme;

  /// Smoky Plum theme option
  ///
  /// In en, this message translates to:
  /// **'Smoky Plum × Warm Stone'**
  String get settingsThemeSmokyPlum;

  /// Deep Olive theme option
  ///
  /// In en, this message translates to:
  /// **'Deep Olive × Sand'**
  String get settingsThemeDeepOlive;

  /// Developer screen title
  ///
  /// In en, this message translates to:
  /// **'Developer Screen'**
  String get developerTitle;

  /// Developer screen navigation section title
  ///
  /// In en, this message translates to:
  /// **'Screen Navigation'**
  String get developerScreenNavigation;

  /// Developer screen navigation description
  ///
  /// In en, this message translates to:
  /// **'Navigate to any screen directly'**
  String get developerScreenNavigationDesc;

  /// Auth section title in developer screen
  ///
  /// In en, this message translates to:
  /// **'Authentication & Connection'**
  String get developerAuthSection;

  /// Main section title in developer screen
  ///
  /// In en, this message translates to:
  /// **'Main Screens'**
  String get developerMainSection;

  /// Plan section title in developer screen
  ///
  /// In en, this message translates to:
  /// **'Plan Creation'**
  String get developerPlanSection;

  /// Deep link section title
  ///
  /// In en, this message translates to:
  /// **'Deep Links'**
  String get developerDeepLink;

  /// Deep link format label
  ///
  /// In en, this message translates to:
  /// **'Deep Link URL Format:'**
  String get developerDeepLinkFormat;

  /// Splash screen name
  ///
  /// In en, this message translates to:
  /// **'Splash'**
  String get developerScreenSplash;

  /// Login screen name
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get developerScreenLogin;

  /// Connect screen name
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get developerScreenConnect;

  /// Home screen name
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get developerScreenHome;

  /// Developer screen name
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developerScreenDeveloper;

  /// Settings screen name
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get developerScreenSettings;

  /// Splash screen description
  ///
  /// In en, this message translates to:
  /// **'App launch screen'**
  String get developerScreenSplashDesc;

  /// Login screen description
  ///
  /// In en, this message translates to:
  /// **'Google/Apple login'**
  String get developerScreenLoginDesc;

  /// Connect screen description
  ///
  /// In en, this message translates to:
  /// **'Couple connection screen'**
  String get developerScreenConnectDesc;

  /// Home screen description
  ///
  /// In en, this message translates to:
  /// **'Now/History/Us tabs'**
  String get developerScreenHomeDesc;

  /// Settings screen description
  ///
  /// In en, this message translates to:
  /// **'Language and theme settings'**
  String get developerScreenSettingsDesc;

  /// Action selection screen name
  ///
  /// In en, this message translates to:
  /// **'Action Selection'**
  String get developerScreenActionSelection;

  /// Frequency screen name
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get developerScreenFrequency;

  /// Day selection screen name
  ///
  /// In en, this message translates to:
  /// **'Day Selection'**
  String get developerScreenDaySelection;

  /// Description screen name
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get developerScreenDescription;

  /// Summary screen name
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get developerScreenSummary;

  /// Action selection screen description
  ///
  /// In en, this message translates to:
  /// **'Screen 1: Action selection'**
  String get developerScreenActionSelectionDesc;

  /// Frequency screen description
  ///
  /// In en, this message translates to:
  /// **'Screen 2: Repeat frequency'**
  String get developerScreenFrequencyDesc;

  /// Day selection screen description
  ///
  /// In en, this message translates to:
  /// **'Screen 4: Day selection'**
  String get developerScreenDaySelectionDesc;

  /// Description screen description
  ///
  /// In en, this message translates to:
  /// **'Screen 3: Specific action description'**
  String get developerScreenDescriptionDesc;

  /// Summary screen description
  ///
  /// In en, this message translates to:
  /// **'Screen 5: Plan proposal summary'**
  String get developerScreenSummaryDesc;

  /// Section title for plan creation in settings
  ///
  /// In en, this message translates to:
  /// **'Plan Creation'**
  String get settingsPlanCreation;

  /// Title for plan creation option
  ///
  /// In en, this message translates to:
  /// **'Create New Promise'**
  String get settingsPlanCreationTitle;

  /// Description for unified plan creation screen
  ///
  /// In en, this message translates to:
  /// **'All steps in one screen'**
  String get settingsPlanCreationDesc;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
