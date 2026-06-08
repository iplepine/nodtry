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
  /// **'Nod&Try'**
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

  /// Button to start the app without logging in (Guest Mode)
  ///
  /// In en, this message translates to:
  /// **'Start without login'**
  String get loginGuest;

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
  /// **'I\'ll do this'**
  String get homeReceivedMessage;

  /// Button to check verification
  ///
  /// In en, this message translates to:
  /// **'Nod&Try'**
  String get homeCheckIt;

  /// Message when report is sent and waiting
  ///
  /// In en, this message translates to:
  /// **'I sent my work'**
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
  /// **'Okay'**
  String get homeChecked;

  /// Thank you message after check
  ///
  /// In en, this message translates to:
  /// **'Thank you'**
  String get homeThankYou;

  /// Message for actor when time has passed but within grace period
  ///
  /// In en, this message translates to:
  /// **'No record delivered yet'**
  String get timePassedActorMessage;

  /// Message for manager when actor hasn't reported yet
  ///
  /// In en, this message translates to:
  /// **'No words delivered yet'**
  String get timePassedManagerMessage;

  /// Sub-message for actor when time has passed
  ///
  /// In en, this message translates to:
  /// **'It\'s okay to start now'**
  String get timePassedActorSubMessage;

  /// Sub-message for manager when actor hasn't reported yet
  ///
  /// In en, this message translates to:
  /// **'The day is passing quietly'**
  String get timePassedManagerSubMessage;

  /// Message for past uncompleted task in Secondary card
  ///
  /// In en, this message translates to:
  /// **'Scheduled a little while ago'**
  String get pastUncompletedMessage;

  /// Sub-message for past uncompleted task
  ///
  /// In en, this message translates to:
  /// **'There was a previous promise'**
  String get pastUncompletedSubMessage;

  /// Time chip text for past uncompleted tasks
  ///
  /// In en, this message translates to:
  /// **'Just before'**
  String get pastUncompletedTimeChip;

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
  /// **'No promises recorded yet'**
  String get historyEmpty;

  /// Us tab - Me section title
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get usMeTitle;

  /// Us tab - Default user name
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get usDefaultNameMe;

  /// Us tab - You section title
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get usYouTitle;

  /// No description provided for @usHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Promises you\'re building together'**
  String get usHeroSubtitle;

  /// No description provided for @usCheerSent.
  ///
  /// In en, this message translates to:
  /// **'Cheer sent ⚡'**
  String get usCheerSent;

  /// No description provided for @usCheerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send cheer'**
  String get usCheerTooltip;

  /// Us tab - Profile edit button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get usProfileEdit;

  /// Us tab - Status message placeholder
  ///
  /// In en, this message translates to:
  /// **'Set status message'**
  String get usStatusMessagePlaceholder;

  /// Us tab - My introduction button
  ///
  /// In en, this message translates to:
  /// **'My Introduction'**
  String get usMyIntroduction;

  /// Us tab - My invite code button
  ///
  /// In en, this message translates to:
  /// **'My Invite Code'**
  String get usMyInviteCode;

  /// Us tab - Badge: They support Me
  ///
  /// In en, this message translates to:
  /// **'Supported'**
  String get usBadgeSupported;

  /// Us tab - Badge: I cheer Them
  ///
  /// In en, this message translates to:
  /// **'Cheering'**
  String get usBadgeCheering;

  /// No description provided for @usGuestWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'If you change phone or delete app/data, you may lose records.'**
  String get usGuestWarningMessage;

  /// No description provided for @usGuestWarningAction.
  ///
  /// In en, this message translates to:
  /// **'Link Account to Keep Records'**
  String get usGuestWarningAction;

  /// No description provided for @usLinkSuccess.
  ///
  /// In en, this message translates to:
  /// **'Google account linked successfully!'**
  String get usLinkSuccess;

  /// No description provided for @usLinkError.
  ///
  /// In en, this message translates to:
  /// **'Account linking failed: {error}'**
  String usLinkError(String error);

  /// No description provided for @usLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading connections'**
  String get usLoadError;

  /// No description provided for @usNoInviteCode.
  ///
  /// In en, this message translates to:
  /// **'No Code'**
  String get usNoInviteCode;

  /// No description provided for @usNoName.
  ///
  /// In en, this message translates to:
  /// **'No Name'**
  String get usNoName;

  /// No description provided for @usUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get usUnknownUser;

  /// No description provided for @usDisconnectDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get usDisconnectDialogTitle;

  /// No description provided for @usDisconnectDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Disconnect from {name}?'**
  String usDisconnectDialogContent(String name);

  /// No description provided for @usDisconnectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get usDisconnectConfirm;

  /// No description provided for @usDisconnectSuccess.
  ///
  /// In en, this message translates to:
  /// **'Disconnected successfully.'**
  String get usDisconnectSuccess;

  /// No description provided for @usDisconnectError.
  ///
  /// In en, this message translates to:
  /// **'Disconnection failed: {error}'**
  String usDisconnectError(String error);

  /// No description provided for @usDisconnectTooltip.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get usDisconnectTooltip;

  /// No description provided for @usCropImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop Profile Image'**
  String get usCropImageTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Us tab - Profile edit image label
  ///
  /// In en, this message translates to:
  /// **'Change profile picture'**
  String get usProfileEditImageLabel;

  /// Us tab - Add new connection button label
  ///
  /// In en, this message translates to:
  /// **'Add new connection'**
  String get usAddConnectionLabel;

  /// Us tab - Badge: Mutual support
  ///
  /// In en, this message translates to:
  /// **'Together'**
  String get usBadgeMutual;

  /// Us tab - Empty state title
  ///
  /// In en, this message translates to:
  /// **'No mates connected yet'**
  String get usEmptyMatesTitle;

  /// Us tab - Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Send your invite code to become each other\'s safe base'**
  String get usEmptyMatesSubtitle;

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
  /// **'What promises shall we make this month?'**
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

  /// Subtitle when there's no plan
  ///
  /// In en, this message translates to:
  /// **'Shall we make just one promise?'**
  String get nowNoPlanSubtitle;

  /// Message when all tasks are done
  ///
  /// In en, this message translates to:
  /// **'Took care of everything today 🙌'**
  String get nowTodayDone;

  /// Headline when multiple plans were completed today
  ///
  /// In en, this message translates to:
  /// **'Took care of all {count} today 🙌'**
  String nowTodayAllDone(int count);

  /// Partner plan share - proposed
  ///
  /// In en, this message translates to:
  /// **'Proposed this promise'**
  String get nowPartnerProposed;

  /// Partner plan share - adjusting
  ///
  /// In en, this message translates to:
  /// **'Adjusting the promise a bit'**
  String get nowPartnerAdjusting;

  /// Partner action share - confirmed
  ///
  /// In en, this message translates to:
  /// **'I did it!'**
  String get nowPartnerDidIt;

  /// Action to skip partner feedback
  ///
  /// In en, this message translates to:
  /// **'Just skip'**
  String get nowActionPass;

  /// Action to skip today's task
  ///
  /// In en, this message translates to:
  /// **'Let\'s skip today'**
  String get nowActionSkipToday;

  /// Button to add more plans in TodayComplete/TodayEmpty state
  ///
  /// In en, this message translates to:
  /// **'Shall we make another promise?'**
  String get nowAddMorePlan;

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
  /// **'But choosing them can make it easier to remember.'**
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
  /// **'I\'ll do this'**
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

  /// Mint and Orange theme option
  ///
  /// In en, this message translates to:
  /// **'Mint × Orange'**
  String get settingsThemeSmokyPlum;

  /// Deep Olive theme option
  ///
  /// In en, this message translates to:
  /// **'Deep Olive × Sand'**
  String get settingsThemeDeepOlive;

  /// Pacific (Ocean Blue × Coral) theme option
  ///
  /// In en, this message translates to:
  /// **'Pacific'**
  String get settingsThemePacific;

  /// Rose Mocha (Dusty Rose × Cream) theme option
  ///
  /// In en, this message translates to:
  /// **'Rose Mocha'**
  String get settingsThemeRoseMocha;

  /// Lavender Dusk (Plum × Mustard Gold) theme option
  ///
  /// In en, this message translates to:
  /// **'Lavender Dusk'**
  String get settingsThemeLavenderDusk;

  /// Developer screen title
  ///
  /// In en, this message translates to:
  /// **'Developer Screen'**
  String get developerTitle;

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

  /// No description provided for @settingsPlanCreationDesc.
  ///
  /// In en, this message translates to:
  /// **'All steps in one screen'**
  String get settingsPlanCreationDesc;

  /// Developer menu label
  ///
  /// In en, this message translates to:
  /// **'Developer Menu'**
  String get settingsDeveloper;

  /// No description provided for @usLinkEmailAction.
  ///
  /// In en, this message translates to:
  /// **'Link with Email'**
  String get usLinkEmailAction;

  /// No description provided for @usLinkEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Link Email Account'**
  String get usLinkEmailTitle;

  /// No description provided for @usLinkEmailContent.
  ///
  /// In en, this message translates to:
  /// **'Enter an email and password to use for login.'**
  String get usLinkEmailContent;

  /// No description provided for @usEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get usEmailLabel;

  /// No description provided for @usPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get usPasswordLabel;

  /// No description provided for @usLinkConfirm.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get usLinkConfirm;

  /// Header text showing partner name
  ///
  /// In en, this message translates to:
  /// **'With {name}'**
  String headerWithPartner(String name);

  /// No description provided for @usLinkEmailSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email account linked successfully!'**
  String get usLinkEmailSuccess;

  /// History card label when partner verified
  ///
  /// In en, this message translates to:
  /// **'Partner verified'**
  String get historyPartnerVerified;

  /// History card label when I verified
  ///
  /// In en, this message translates to:
  /// **'I verified'**
  String get historyMeVerified;

  /// Frequency label for everyday
  ///
  /// In en, this message translates to:
  /// **'Everyday'**
  String get frequencyEveryday;

  /// Label for optional notification time
  ///
  /// In en, this message translates to:
  /// **'Notification time (Optional)'**
  String get planNotificationTimeOptional;

  /// Title for my plan section
  ///
  /// In en, this message translates to:
  /// **'My Promise'**
  String get usMyPlanTitle;

  /// Title for partner plan section
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Promise'**
  String usPartnerPlanTitle(String name);

  /// Vague time label for dinner
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get vagueTimeDinner;

  /// Vague time label for bedtime
  ///
  /// In en, this message translates to:
  /// **'Bedtime'**
  String get vagueTimeBedtime;

  /// Simple cheer option
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get cheerSimple;

  /// Option to see more cheer options
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get cheerMore;

  /// Title for the cheer selection sheet
  ///
  /// In en, this message translates to:
  /// **'How to Cheer?'**
  String get cheerSheetTitle;

  /// Hint text for cheer message input
  ///
  /// In en, this message translates to:
  /// **'Leave a cheer message'**
  String get cheerMessageHint;

  /// Send button for cheer message
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get cheerSend;

  /// No description provided for @doneSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts'**
  String get doneSheetTitle;

  /// No description provided for @doneMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Leave a short note'**
  String get doneMessageHint;

  /// No description provided for @doneButton.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get doneButton;

  /// Description for developer menu
  ///
  /// In en, this message translates to:
  /// **'Debug menu'**
  String get settingsDeveloperDesc;

  /// Account section title in settings
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// Logout button title
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogout;

  /// Description for logout option
  ///
  /// In en, this message translates to:
  /// **'Log out from your current account'**
  String get settingsLogoutDesc;

  /// Title for logout confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogoutDialogTitle;

  /// Content for logout confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get settingsLogoutDialogContent;

  /// Logout confirmation button label
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogoutConfirm;

  /// Delete account button title
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get settingsDeleteAccount;

  /// Description for delete account option
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and data'**
  String get settingsDeleteAccountDesc;

  /// Title for delete account confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get settingsDeleteAccountDialogTitle;

  /// Content for delete account confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone.'**
  String get settingsDeleteAccountDialogContent;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsCancel;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get settingsDelete;

  /// Email login button text
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get loginWithEmail;

  /// Email label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Sign up button text
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Headline for email login screen
  ///
  /// In en, this message translates to:
  /// **'Start with Email'**
  String get emailStartMessage;

  /// Hint text for password input
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// Hint text for email input
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// Error message for invalid email
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get invalidEmail;

  /// Error message for weak password
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get weakPassword;

  /// Error message for existing account
  ///
  /// In en, this message translates to:
  /// **'Account already exists with a different credential'**
  String get accountExistsWithDifferentCredential;

  /// Error message for user not found
  ///
  /// In en, this message translates to:
  /// **'No user found for that email.'**
  String get userNotFound;

  /// Error message for wrong password
  ///
  /// In en, this message translates to:
  /// **'Wrong password provided for that user.'**
  String get wrongPassword;

  /// Success message after account deletion
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get settingsAccountDeletedSuccess;

  /// Error message when auth service is missing
  ///
  /// In en, this message translates to:
  /// **'Auth Service not found'**
  String get settingsAuthServiceNotFound;

  /// No description provided for @settingsDeleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account: {error}'**
  String settingsDeleteAccountFailed(Object error);

  /// No description provided for @reconcileTitle.
  ///
  /// In en, this message translates to:
  /// **'Reconcile'**
  String get reconcileTitle;

  /// No description provided for @reconcileActuallyDone.
  ///
  /// In en, this message translates to:
  /// **'Actually did it'**
  String get reconcileActuallyDone;

  /// No description provided for @reconcileTookRest.
  ///
  /// In en, this message translates to:
  /// **'Took a break today'**
  String get reconcileTookRest;

  /// No description provided for @reconcileSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get reconcileSkip;

  /// No description provided for @reconcileDoneMessage.
  ///
  /// In en, this message translates to:
  /// **'Record has been reconciled.'**
  String get reconcileDoneMessage;

  /// No description provided for @historyFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get historyFilterAll;

  /// No description provided for @historyFilterMe.
  ///
  /// In en, this message translates to:
  /// **'My Action'**
  String get historyFilterMe;

  /// No description provided for @historyFilterPartner.
  ///
  /// In en, this message translates to:
  /// **'Partner\'s Action'**
  String get historyFilterPartner;

  /// No description provided for @historyMyActionVerified.
  ///
  /// In en, this message translates to:
  /// **'Partner saw it'**
  String get historyMyActionVerified;

  /// No description provided for @historyPartnerActionVerified.
  ///
  /// In en, this message translates to:
  /// **'Saw it'**
  String get historyPartnerActionVerified;

  /// No description provided for @historyPartnerActionWaiting.
  ///
  /// In en, this message translates to:
  /// **'Not seen yet'**
  String get historyPartnerActionWaiting;

  /// No description provided for @historyActionSawIt.
  ///
  /// In en, this message translates to:
  /// **'Saw it 👍'**
  String get historyActionSawIt;

  /// No description provided for @historyActionCheer.
  ///
  /// In en, this message translates to:
  /// **'Cheering you 💜'**
  String get historyActionCheer;

  /// No description provided for @timeChipStillActionable.
  ///
  /// In en, this message translates to:
  /// **'Still actionable'**
  String get timeChipStillActionable;

  /// No description provided for @timeChipPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get timeChipPassed;

  /// No description provided for @nowStatusActuallyDone.
  ///
  /// In en, this message translates to:
  /// **'Actually did it'**
  String get nowStatusActuallyDone;

  /// No description provided for @nowLateCompletion.
  ///
  /// In en, this message translates to:
  /// **'Completed even if late!'**
  String get nowLateCompletion;

  /// No description provided for @nowLateJustInTime.
  ///
  /// In en, this message translates to:
  /// **'Did it a bit late'**
  String get nowLateJustInTime;

  /// No description provided for @nowWithinToday.
  ///
  /// In en, this message translates to:
  /// **'Done within today'**
  String get nowWithinToday;

  /// No description provided for @timeChipNow.
  ///
  /// In en, this message translates to:
  /// **'Now!'**
  String get timeChipNow;

  /// No description provided for @timeChipJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeChipJustNow;

  /// No description provided for @timeChipMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String timeChipMinutesAgo(int minutes);

  /// No description provided for @timeChipHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String timeChipHoursAgo(int hours);

  /// No description provided for @timeChipMinutesLeft.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m left'**
  String timeChipMinutesLeft(int minutes);

  /// No description provided for @timeChipHoursLeft.
  ///
  /// In en, this message translates to:
  /// **'{hours}h left'**
  String timeChipHoursLeft(int hours);

  /// No description provided for @timeChipYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get timeChipYesterday;

  /// No description provided for @timeChipDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String timeChipDaysAgo(int days);

  /// No description provided for @timeChipTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get timeChipTomorrow;

  /// No description provided for @timeChipDayAfterTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Day after tomorrow'**
  String get timeChipDayAfterTomorrow;

  /// No description provided for @timeChipDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days}d left'**
  String timeChipDaysLeft(int days);

  /// No description provided for @timeChipNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next {weekday}'**
  String timeChipNextWeek(String weekday);

  /// No description provided for @timeChipDate.
  ///
  /// In en, this message translates to:
  /// **'{month}/{day}'**
  String timeChipDate(int month, int day);

  /// No description provided for @vagueTimeMorning.
  ///
  /// In en, this message translates to:
  /// **'In the morning'**
  String get vagueTimeMorning;

  /// No description provided for @vagueTimeLunch.
  ///
  /// In en, this message translates to:
  /// **'Around lunch'**
  String get vagueTimeLunch;

  /// No description provided for @vagueTimeAfternoon.
  ///
  /// In en, this message translates to:
  /// **'In the afternoon'**
  String get vagueTimeAfternoon;

  /// No description provided for @vagueTimeEvening.
  ///
  /// In en, this message translates to:
  /// **'In the evening'**
  String get vagueTimeEvening;

  /// No description provided for @vagueTimeNight.
  ///
  /// In en, this message translates to:
  /// **'At night'**
  String get vagueTimeNight;

  /// No description provided for @vagueTimeLateNight.
  ///
  /// In en, this message translates to:
  /// **'Late night'**
  String get vagueTimeLateNight;

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySun;

  /// No description provided for @planTimeQuestion.
  ///
  /// In en, this message translates to:
  /// **'When should I notify you?'**
  String get planTimeQuestion;

  /// No description provided for @comfortingFuture.
  ///
  /// In en, this message translates to:
  /// **'Great job today'**
  String get comfortingFuture;

  /// No description provided for @comfortingLate.
  ///
  /// In en, this message translates to:
  /// **'Late is okay'**
  String get comfortingLate;

  /// No description provided for @comfortingJustDoIt.
  ///
  /// In en, this message translates to:
  /// **'Just do it today'**
  String get comfortingJustDoIt;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @notificationSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Manager'**
  String get notificationSettingsTitle;

  /// No description provided for @noActiveAlarms.
  ///
  /// In en, this message translates to:
  /// **'No active alarms'**
  String get noActiveAlarms;

  /// No description provided for @historyTapToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap to change status'**
  String get historyTapToChange;

  /// Title for the in-app tip / coffee support entry
  ///
  /// In en, this message translates to:
  /// **'Buy the developer a coffee'**
  String get settingsBuyDeveloperCoffee;

  /// Subtitle encouraging the user to tip the developer
  ///
  /// In en, this message translates to:
  /// **'A warm cup of coffee goes a long way!'**
  String get settingsCoffeeSubtitle;

  /// Subtitle shown while the coffee tip purchase is in progress
  ///
  /// In en, this message translates to:
  /// **'Processing payment...'**
  String get settingsCoffeePurchasing;

  /// Snackbar shown when the IAP store is unavailable
  ///
  /// In en, this message translates to:
  /// **'Can\'t connect to the store. Please check your settings.'**
  String get settingsStoreUnavailable;

  /// No description provided for @planMostlyProcrastinated.
  ///
  /// In en, this message translates to:
  /// **'What you usually put off'**
  String get planMostlyProcrastinated;

  /// No description provided for @planRecommendedPromises.
  ///
  /// In en, this message translates to:
  /// **'Suggested promises'**
  String get planRecommendedPromises;

  /// No description provided for @planMine.
  ///
  /// In en, this message translates to:
  /// **'My promise'**
  String get planMine;

  /// No description provided for @planClearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get planClearAction;

  /// No description provided for @planRecommendedFrequency.
  ///
  /// In en, this message translates to:
  /// **'Suggested frequency'**
  String get planRecommendedFrequency;

  /// No description provided for @planNoDayMeansDaily.
  ///
  /// In en, this message translates to:
  /// **'Without picking days, this becomes a daily promise.'**
  String get planNoDayMeansDaily;

  /// No description provided for @planPartnerFallback.
  ///
  /// In en, this message translates to:
  /// **'your partner'**
  String get planPartnerFallback;

  /// No description provided for @planActionFallback.
  ///
  /// In en, this message translates to:
  /// **'my promise'**
  String get planActionFallback;

  /// No description provided for @planPartnerPreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Here\'s how your partner sees it'**
  String get planPartnerPreviewLabel;

  /// No description provided for @planPartnerPreviewWith.
  ///
  /// In en, this message translates to:
  /// **'{name} will be asked to nudge you on \"{promise}\" without missing a beat for 28 days.'**
  String planPartnerPreviewWith(String name, String promise);

  /// No description provided for @planPartnerPreviewWithout.
  ///
  /// In en, this message translates to:
  /// **'Without a partner there\'s no one to receive the poke. Connect one before saving for stronger pressure.'**
  String get planPartnerPreviewWithout;

  /// No description provided for @planConnectPartner.
  ///
  /// In en, this message translates to:
  /// **'Connect a partner'**
  String get planConnectPartner;

  /// No description provided for @planDayEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get planDayEveryDay;

  /// No description provided for @planDayWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get planDayWeekdays;

  /// No description provided for @planDayCountFormat.
  ///
  /// In en, this message translates to:
  /// **'{count} days/week'**
  String planDayCountFormat(int count);

  /// No description provided for @planPreviewMeta.
  ///
  /// In en, this message translates to:
  /// **'{days} · {time} · 28 days'**
  String planPreviewMeta(String days, String time);

  /// No description provided for @planTimeAM.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get planTimeAM;

  /// No description provided for @planTimePM.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get planTimePM;

  /// No description provided for @planTimeFormatNoMinute.
  ///
  /// In en, this message translates to:
  /// **'{period} {hour}'**
  String planTimeFormatNoMinute(String period, int hour);

  /// No description provided for @planTimeFormatWithMinute.
  ///
  /// In en, this message translates to:
  /// **'{period} {hour}:{minute}'**
  String planTimeFormatWithMinute(String period, int hour, String minute);

  /// No description provided for @planTemplatePerWeek.
  ///
  /// In en, this message translates to:
  /// **'{label} · {count}/wk'**
  String planTemplatePerWeek(String label, int count);

  /// No description provided for @planCategoryStudyLabel.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get planCategoryStudyLabel;

  /// No description provided for @planCategoryStudyDescription.
  ///
  /// In en, this message translates to:
  /// **'Self-study you keep putting off — English, certifications, coding'**
  String get planCategoryStudyDescription;

  /// No description provided for @planCategoryExerciseLabel.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get planCategoryExerciseLabel;

  /// No description provided for @planCategoryExerciseDescription.
  ///
  /// In en, this message translates to:
  /// **'Movement that\'s hard to start — walking, gym, stretching'**
  String get planCategoryExerciseDescription;

  /// No description provided for @planCategoryVerifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Verified routines'**
  String get planCategoryVerifiedLabel;

  /// No description provided for @planCategoryVerifiedDescription.
  ///
  /// In en, this message translates to:
  /// **'Daily habits grounded in neuroscience and sleep research'**
  String get planCategoryVerifiedDescription;

  /// No description provided for @planCategoryCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get planCategoryCustomLabel;

  /// No description provided for @planCategoryCustomDescription.
  ///
  /// In en, this message translates to:
  /// **'Write your own promise without picking a template'**
  String get planCategoryCustomDescription;

  /// No description provided for @planTemplateEnglishLabel.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get planTemplateEnglishLabel;

  /// No description provided for @planTemplateEnglishAction.
  ///
  /// In en, this message translates to:
  /// **'Read 10 English sentences aloud'**
  String get planTemplateEnglishAction;

  /// No description provided for @planTemplateEnglishDescription.
  ///
  /// In en, this message translates to:
  /// **'Aim for low-pressure daily exposure to English.'**
  String get planTemplateEnglishDescription;

  /// No description provided for @planTemplateCertificateLabel.
  ///
  /// In en, this message translates to:
  /// **'Certification'**
  String get planTemplateCertificateLabel;

  /// No description provided for @planTemplateCertificateAction.
  ///
  /// In en, this message translates to:
  /// **'Solve 10 past exam questions'**
  String get planTemplateCertificateAction;

  /// No description provided for @planTemplateCertificateDescription.
  ///
  /// In en, this message translates to:
  /// **'Repeat a fixed count without breaking the streak instead of cramming.'**
  String get planTemplateCertificateDescription;

  /// No description provided for @planTemplateCodingLabel.
  ///
  /// In en, this message translates to:
  /// **'Coding'**
  String get planTemplateCodingLabel;

  /// No description provided for @planTemplateCodingAction.
  ///
  /// In en, this message translates to:
  /// **'30 min of coding or one problem'**
  String get planTemplateCodingAction;

  /// No description provided for @planTemplateCodingDescription.
  ///
  /// In en, this message translates to:
  /// **'Secure the days you actually touch code before chasing big goals.'**
  String get planTemplateCodingDescription;

  /// No description provided for @planTemplateReadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get planTemplateReadingLabel;

  /// No description provided for @planTemplateReadingAction.
  ///
  /// In en, this message translates to:
  /// **'Read 10 pages and log one line'**
  String get planTemplateReadingAction;

  /// No description provided for @planTemplateReadingDescription.
  ///
  /// In en, this message translates to:
  /// **'Leave a one-line trace so your partner can check in easily.'**
  String get planTemplateReadingDescription;

  /// No description provided for @planTemplateWritingLabel.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get planTemplateWritingLabel;

  /// No description provided for @planTemplateWritingAction.
  ///
  /// In en, this message translates to:
  /// **'Write for 15 min or 300 characters'**
  String get planTemplateWritingAction;

  /// No description provided for @planTemplateWritingDescription.
  ///
  /// In en, this message translates to:
  /// **'Focus on starting days, not finished pieces.'**
  String get planTemplateWritingDescription;

  /// No description provided for @planTemplateWalkingLabel.
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get planTemplateWalkingLabel;

  /// No description provided for @planTemplateWalkingAction.
  ///
  /// In en, this message translates to:
  /// **'Walk 30 minutes'**
  String get planTemplateWalkingAction;

  /// No description provided for @planTemplateWalkingDescription.
  ///
  /// In en, this message translates to:
  /// **'Commit to stepping outside before worrying about gear.'**
  String get planTemplateWalkingDescription;

  /// No description provided for @planTemplateGymLabel.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get planTemplateGymLabel;

  /// No description provided for @planTemplateGymAction.
  ///
  /// In en, this message translates to:
  /// **'Go to the gym and work out for 30 min'**
  String get planTemplateGymAction;

  /// No description provided for @planTemplateGymDescription.
  ///
  /// In en, this message translates to:
  /// **'Increase days you arrive at the gym rather than perfect workouts.'**
  String get planTemplateGymDescription;

  /// No description provided for @planTemplateStretchingLabel.
  ///
  /// In en, this message translates to:
  /// **'Stretching'**
  String get planTemplateStretchingLabel;

  /// No description provided for @planTemplateStretchingAction.
  ///
  /// In en, this message translates to:
  /// **'Stretch for 10 minutes'**
  String get planTemplateStretchingAction;

  /// No description provided for @planTemplateStretchingDescription.
  ///
  /// In en, this message translates to:
  /// **'Show your partner even a short loosen-up.'**
  String get planTemplateStretchingDescription;

  /// No description provided for @planTemplateMorningLightLabel.
  ///
  /// In en, this message translates to:
  /// **'Morning light'**
  String get planTemplateMorningLightLabel;

  /// No description provided for @planTemplateMorningLightAction.
  ///
  /// In en, this message translates to:
  /// **'Get 5–10 minutes of morning sunlight'**
  String get planTemplateMorningLightAction;

  /// No description provided for @planTemplateMorningLightDescription.
  ///
  /// In en, this message translates to:
  /// **'Morning sunlight hitting your eyes tells the brain the day has started, locking in tonight\'s melatonin release so you fall asleep faster and deeper. 5–10 minutes outdoors is enough on clear days; stretch to 10–20 on cloudy ones, 20–30 in rain. Windows block the key wavelengths and sunglasses dampen the light-sensing cells (never stare directly at the sun)'**
  String get planTemplateMorningLightDescription;

  /// No description provided for @planTemplateCaffeineDelayLabel.
  ///
  /// In en, this message translates to:
  /// **'Delay caffeine'**
  String get planTemplateCaffeineDelayLabel;

  /// No description provided for @planTemplateCaffeineDelayAction.
  ///
  /// In en, this message translates to:
  /// **'First caffeine 90 minutes after waking'**
  String get planTemplateCaffeineDelayAction;

  /// No description provided for @planTemplateCaffeineDelayDescription.
  ///
  /// In en, this message translates to:
  /// **'Caffeine right after waking only blocks sleep-signal molecules (adenosine) for a while — they pile up and hit at once later, causing an afternoon slump. Wait 90 minutes for cleaner, longer-lasting energy'**
  String get planTemplateCaffeineDelayDescription;

  /// No description provided for @planTemplatePhysioSighLabel.
  ///
  /// In en, this message translates to:
  /// **'Physiological sigh'**
  String get planTemplatePhysioSighLabel;

  /// No description provided for @planTemplatePhysioSighAction.
  ///
  /// In en, this message translates to:
  /// **'5 minutes of physiological sighs'**
  String get planTemplatePhysioSighAction;

  /// No description provided for @planTemplatePhysioSighDescription.
  ///
  /// In en, this message translates to:
  /// **'Take a short inhale through the nose, then a second one to fully inflate the lungs, and exhale slowly through the mouth. This dumps trapped CO₂ in one shot and drops heart rate immediately. An RCT (n=111) showed it beat meditation for stress and mood. Even one or two reps help in the moment; 5 minutes daily is the preventive dose'**
  String get planTemplatePhysioSighDescription;

  /// No description provided for @planTemplateFocus90Label.
  ///
  /// In en, this message translates to:
  /// **'90-min focus'**
  String get planTemplateFocus90Label;

  /// No description provided for @planTemplateFocus90Action.
  ///
  /// In en, this message translates to:
  /// **'One 90-minute focus session'**
  String get planTemplateFocus90Action;

  /// No description provided for @planTemplateFocus90Description.
  ///
  /// In en, this message translates to:
  /// **'The brain runs on ~90-minute focus cycles (ultradian rhythm). Mornings are richest in dopamine and norepinephrine, so deep work lands best then, and attention naturally drops after 90 min — give yourself 10–30 minutes off before the next cycle. Kill notifications and stay on one task throughout'**
  String get planTemplateFocus90Description;

  /// No description provided for @planTemplateSleepEnvLabel.
  ///
  /// In en, this message translates to:
  /// **'Sleep environment'**
  String get planTemplateSleepEnvLabel;

  /// No description provided for @planTemplateSleepEnvAction.
  ///
  /// In en, this message translates to:
  /// **'Dim and cool the bedroom an hour before bed'**
  String get planTemplateSleepEnvAction;

  /// No description provided for @planTemplateSleepEnvDescription.
  ///
  /// In en, this message translates to:
  /// **'An hour before bed, switch off overhead lights and use indirect lamps — that\'s when melatonin starts to rise, speeding sleep onset. Keep the bedroom at 18–20°C; your body needs a slight temperature drop for deep sleep and REM. A hot shower right before bed actually delays sleep, so finish 1–2 hours earlier'**
  String get planTemplateSleepEnvDescription;

  /// No description provided for @planDayPresetThreeDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'3 days/wk'**
  String get planDayPresetThreeDaysLabel;

  /// No description provided for @planDayPresetWeekdaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get planDayPresetWeekdaysLabel;

  /// No description provided for @planDayPresetEveryDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get planDayPresetEveryDayLabel;

  /// No description provided for @planDayPresetWeekendLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekend'**
  String get planDayPresetWeekendLabel;

  /// No description provided for @planDayPresetStudyThreeDaysDesc.
  ///
  /// In en, this message translates to:
  /// **'Build three wins in the first week'**
  String get planDayPresetStudyThreeDaysDesc;

  /// No description provided for @planDayPresetStudyWeekdaysDesc.
  ///
  /// In en, this message translates to:
  /// **'Anchor your study to the weekdays'**
  String get planDayPresetStudyWeekdaysDesc;

  /// No description provided for @planDayPresetStudyEveryDayDesc.
  ///
  /// In en, this message translates to:
  /// **'Show your partner something each day, even briefly'**
  String get planDayPresetStudyEveryDayDesc;

  /// No description provided for @planDayPresetExerciseThreeDaysDesc.
  ///
  /// In en, this message translates to:
  /// **'Start with a Mon/Wed/Fri rhythm'**
  String get planDayPresetExerciseThreeDaysDesc;

  /// No description provided for @planDayPresetExerciseWeekendDesc.
  ///
  /// In en, this message translates to:
  /// **'Leave a movement trace on weekends'**
  String get planDayPresetExerciseWeekendDesc;

  /// No description provided for @planDayPresetExerciseEveryDayDesc.
  ///
  /// In en, this message translates to:
  /// **'Get daily check-ins like a short stretch'**
  String get planDayPresetExerciseEveryDayDesc;

  /// No description provided for @planDayPresetCustomThreeDaysDesc.
  ///
  /// In en, this message translates to:
  /// **'A low-pressure default'**
  String get planDayPresetCustomThreeDaysDesc;

  /// No description provided for @planDayPresetCustomWeekdaysDesc.
  ///
  /// In en, this message translates to:
  /// **'Lock it in as a weekday routine'**
  String get planDayPresetCustomWeekdaysDesc;

  /// No description provided for @planDayPresetCustomEveryDayDesc.
  ///
  /// In en, this message translates to:
  /// **'Leave a small action every day'**
  String get planDayPresetCustomEveryDayDesc;

  /// No description provided for @planStepHeader.
  ///
  /// In en, this message translates to:
  /// **'Preparing promise · {current}/{total}'**
  String planStepHeader(int current, int total);

  /// No description provided for @planTellUsActionFirst.
  ///
  /// In en, this message translates to:
  /// **'Tell us what you want to promise!'**
  String get planTellUsActionFirst;

  /// No description provided for @planProposalSaved.
  ///
  /// In en, this message translates to:
  /// **'Proposal saved.\nGo chat about it with your partner!'**
  String get planProposalSaved;

  /// No description provided for @planSaveError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while saving: {error}'**
  String planSaveError(String error);

  /// No description provided for @focusTimerPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'How long do you want to focus?'**
  String get focusTimerPickerTitle;

  /// No description provided for @focusTimerPickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When the timer ends, the \"Done\" note opens automatically.'**
  String get focusTimerPickerSubtitle;

  /// No description provided for @focusTimerPresetMin.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String focusTimerPresetMin(int minutes);

  /// No description provided for @focusTimerCustomHint.
  ///
  /// In en, this message translates to:
  /// **'Custom ({min}–{max} min)'**
  String focusTimerCustomHint(int min, int max);

  /// No description provided for @focusTimerMinuteUnit.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get focusTimerMinuteUnit;

  /// No description provided for @focusTimerPickFirst.
  ///
  /// In en, this message translates to:
  /// **'Pick a duration'**
  String get focusTimerPickFirst;

  /// No description provided for @focusTimerStart.
  ///
  /// In en, this message translates to:
  /// **'Start {minutes} min'**
  String focusTimerStart(int minutes);

  /// No description provided for @focusTimerGiveUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Give up the timer?'**
  String get focusTimerGiveUpTitle;

  /// No description provided for @focusTimerGiveUpBody.
  ///
  /// In en, this message translates to:
  /// **'Progress isn\'t saved. The promise stays as not done.'**
  String get focusTimerGiveUpBody;

  /// No description provided for @focusTimerKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get focusTimerKeepGoing;

  /// No description provided for @focusTimerGiveUp.
  ///
  /// In en, this message translates to:
  /// **'Give up'**
  String get focusTimerGiveUp;

  /// No description provided for @focusTimerGiveUpShort.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get focusTimerGiveUpShort;

  /// No description provided for @focusTimerHeader.
  ///
  /// In en, this message translates to:
  /// **'Focus {minutes} min'**
  String focusTimerHeader(int minutes);

  /// No description provided for @focusTimerHeaderWithPlan.
  ///
  /// In en, this message translates to:
  /// **'{title} · {minutes} min'**
  String focusTimerHeaderWithPlan(String title, int minutes);

  /// No description provided for @focusTimerPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get focusTimerPaused;

  /// No description provided for @focusTimerDoneNow.
  ///
  /// In en, this message translates to:
  /// **'Done now'**
  String get focusTimerDoneNow;

  /// No description provided for @focusTimerResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get focusTimerResume;

  /// No description provided for @focusTimerPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get focusTimerPause;

  /// No description provided for @actionNoteHintDefault.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts (optional)'**
  String get actionNoteHintDefault;

  /// No description provided for @planTimeUnset.
  ///
  /// In en, this message translates to:
  /// **'Time not set'**
  String get planTimeUnset;

  /// No description provided for @planDaysEveryday.
  ///
  /// In en, this message translates to:
  /// **'Everyday'**
  String get planDaysEveryday;

  /// No description provided for @planDaysWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get planDaysWeekdays;

  /// No description provided for @planDaysWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend'**
  String get planDaysWeekend;

  /// No description provided for @planStateActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get planStateActive;

  /// No description provided for @planStateDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get planStateDraft;

  /// No description provided for @planStatePending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting approval'**
  String get planStatePending;

  /// No description provided for @planStateRejected.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get planStateRejected;

  /// No description provided for @planStateCompleted.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get planStateCompleted;

  /// No description provided for @planStateStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get planStateStopped;

  /// No description provided for @planDescriptionTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: try \"If X, then Y\"'**
  String get planDescriptionTip;

  /// No description provided for @planDescriptionExamples.
  ///
  /// In en, this message translates to:
  /// **'e.g. \"When I get home from work, I change into workout clothes\"\ne.g. \"When the kids fall asleep, I read for 30 minutes\"'**
  String get planDescriptionExamples;

  /// No description provided for @planDescriptionTipFooter.
  ///
  /// In en, this message translates to:
  /// **'A specific situation makes you 2–3× more likely to follow through!'**
  String get planDescriptionTipFooter;

  /// No description provided for @notifyEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifyEditorTitle;

  /// No description provided for @notifyEditorSubtitleOn.
  ///
  /// In en, this message translates to:
  /// **'Pick when we should poke you.'**
  String get notifyEditorSubtitleOn;

  /// No description provided for @notifyEditorSubtitleOff.
  ///
  /// In en, this message translates to:
  /// **'Track without notifications.'**
  String get notifyEditorSubtitleOff;

  /// No description provided for @notifyEditorPromiseTime.
  ///
  /// In en, this message translates to:
  /// **'Promise time visible to your partner'**
  String get notifyEditorPromiseTime;

  /// No description provided for @notifyEditorDefaultTimeHint.
  ///
  /// In en, this message translates to:
  /// **'9 PM by default is a good time for your partner to check before the day slips by.'**
  String get notifyEditorDefaultTimeHint;

  /// No description provided for @notifyEditorPrealert.
  ///
  /// In en, this message translates to:
  /// **'Pre-alert'**
  String get notifyEditorPrealert;

  /// No description provided for @notifyEditorOnTime.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get notifyEditorOnTime;

  /// No description provided for @notifyEditor5MinBefore.
  ///
  /// In en, this message translates to:
  /// **'5 min before'**
  String get notifyEditor5MinBefore;

  /// No description provided for @notifyEditor10MinBefore.
  ///
  /// In en, this message translates to:
  /// **'10 min before'**
  String get notifyEditor10MinBefore;

  /// No description provided for @notifyEditor30MinBefore.
  ///
  /// In en, this message translates to:
  /// **'30 min before'**
  String get notifyEditor30MinBefore;

  /// No description provided for @notifyEditor1HourBefore.
  ///
  /// In en, this message translates to:
  /// **'1 hr before'**
  String get notifyEditor1HourBefore;

  /// No description provided for @promiseChipPenaltyTriggered.
  ///
  /// In en, this message translates to:
  /// **'Penalty locked in — {description}'**
  String promiseChipPenaltyTriggered(String description);

  /// No description provided for @promiseChipPenaltyImminentOne.
  ///
  /// In en, this message translates to:
  /// **'Just one more miss triggers the penalty — {description}'**
  String promiseChipPenaltyImminentOne(String description);

  /// No description provided for @promiseChipPenaltyImminent.
  ///
  /// In en, this message translates to:
  /// **'{count} more misses triggers the penalty — {description}'**
  String promiseChipPenaltyImminent(int count, String description);

  /// No description provided for @promiseChipRewardAchieved.
  ///
  /// In en, this message translates to:
  /// **'Reward earned! — {description}'**
  String promiseChipRewardAchieved(String description);

  /// No description provided for @promiseChipRewardImminent.
  ///
  /// In en, this message translates to:
  /// **'{days} more day(s) to the reward — {description}'**
  String promiseChipRewardImminent(int days, String description);

  /// No description provided for @promiseChipSafeBoth.
  ///
  /// In en, this message translates to:
  /// **'{rewardDays} days to reward · {penaltyBuffer} misses safe'**
  String promiseChipSafeBoth(int rewardDays, int penaltyBuffer);

  /// No description provided for @promiseChipSafeRewardOnly.
  ///
  /// In en, this message translates to:
  /// **'{days} days to reward — {description}'**
  String promiseChipSafeRewardOnly(int days, String description);

  /// No description provided for @promiseChipSafePenaltyOnly.
  ///
  /// In en, this message translates to:
  /// **'{buffer} misses safe — {description}'**
  String promiseChipSafePenaltyOnly(int buffer, String description);

  /// No description provided for @promiseSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Promise terms'**
  String get promiseSheetTitle;

  /// No description provided for @promiseSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Settled when the plan ends. Currently {success} done · {failed} missed · {remaining} days left.'**
  String promiseSheetSubtitle(int success, int failed, int remaining);

  /// No description provided for @promiseSheetRewardLabel.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get promiseSheetRewardLabel;

  /// No description provided for @promiseSheetPenaltyLabel.
  ///
  /// In en, this message translates to:
  /// **'Penalty'**
  String get promiseSheetPenaltyLabel;

  /// No description provided for @promiseSheetRewardTarget.
  ///
  /// In en, this message translates to:
  /// **'{target} successful days to earn it — currently {success}'**
  String promiseSheetRewardTarget(int target, int success);

  /// No description provided for @promiseSheetPenaltyImpossible.
  ///
  /// In en, this message translates to:
  /// **'Needed {target} successful days but you can no longer reach it — penalty locked in'**
  String promiseSheetPenaltyImpossible(int target);

  /// No description provided for @promiseSheetPenaltyJustOne.
  ///
  /// In en, this message translates to:
  /// **'Triggers below {target} successful days — you can\'t miss even once more'**
  String promiseSheetPenaltyJustOne(int target);

  /// No description provided for @promiseSheetPenaltyBuffer.
  ///
  /// In en, this message translates to:
  /// **'Triggers below {target} successful days — {buffer} more misses are safe'**
  String promiseSheetPenaltyBuffer(int target, int buffer);

  /// No description provided for @promiseSheetClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get promiseSheetClose;

  /// No description provided for @splashLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String splashLoginFailed(String error);

  /// No description provided for @splashLoggingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get splashLoggingIn;

  /// No description provided for @emailLoginToggleSignUp.
  ///
  /// In en, this message translates to:
  /// **'No account? Sign up'**
  String get emailLoginToggleSignUp;

  /// No description provided for @emailLoginToggleLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get emailLoginToggleLogin;

  /// No description provided for @settingsSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSupport;

  /// No description provided for @notificationSettingsNoAlarm.
  ///
  /// In en, this message translates to:
  /// **'No alarm'**
  String get notificationSettingsNoAlarm;

  /// No description provided for @notificationSettingsAlarmOff.
  ///
  /// In en, this message translates to:
  /// **'Alarm off ({timeString})'**
  String notificationSettingsAlarmOff(String timeString);

  /// No description provided for @notificationSettingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save notification setting. Reverted to the previous one.'**
  String get notificationSettingsSaveFailed;

  /// No description provided for @historyCardFeedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Leave a warm note (optional)'**
  String get historyCardFeedbackHint;

  /// No description provided for @historyCardFeedbackButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get historyCardFeedbackButton;

  /// No description provided for @historyCardAcknowledgePractice.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge practice'**
  String get historyCardAcknowledgePractice;

  /// No description provided for @planSummaryMyDone.
  ///
  /// In en, this message translates to:
  /// **'My completions'**
  String get planSummaryMyDone;

  /// No description provided for @planSummaryPartnerVerified.
  ///
  /// In en, this message translates to:
  /// **'Partner verified'**
  String get planSummaryPartnerVerified;

  /// No description provided for @planSummaryCount.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String planSummaryCount(int count);

  /// No description provided for @connectInviteCodeDetectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite code detected'**
  String get connectInviteCodeDetectedTitle;

  /// No description provided for @connectInviteCodeDetectedBody.
  ///
  /// In en, this message translates to:
  /// **'We found an invite code ({code}) in your clipboard.\nPaste it?'**
  String connectInviteCodeDetectedBody(String code);

  /// No description provided for @connectCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get connectCancel;

  /// No description provided for @connectPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get connectPaste;

  /// No description provided for @connectNotice.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get connectNotice;

  /// No description provided for @connectAlreadyConnectedBody.
  ///
  /// In en, this message translates to:
  /// **'You already have a connected partner.\nMultiple partners will be supported later.'**
  String get connectAlreadyConnectedBody;

  /// No description provided for @connectOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get connectOk;

  /// No description provided for @connectSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connected!'**
  String get connectSuccess;

  /// No description provided for @allPlansTitleMine.
  ///
  /// In en, this message translates to:
  /// **'My promises'**
  String get allPlansTitleMine;

  /// No description provided for @allPlansTitlePartner.
  ///
  /// In en, this message translates to:
  /// **'Partner\'s promises'**
  String get allPlansTitlePartner;

  /// No description provided for @allPlansEmpty.
  ///
  /// In en, this message translates to:
  /// **'No promises yet'**
  String get allPlansEmpty;

  /// No description provided for @allPlansDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this promise?'**
  String get allPlansDeleteTitle;

  /// No description provided for @allPlansDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone.'**
  String get allPlansDeleteBody;

  /// No description provided for @allPlansDeleted.
  ///
  /// In en, this message translates to:
  /// **'Promise deleted.'**
  String get allPlansDeleted;

  /// No description provided for @allPlansDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String allPlansDeleteFailed(String error);

  /// No description provided for @allPlansDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get allPlansDelete;

  /// No description provided for @allPlansCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get allPlansCancel;

  /// No description provided for @historyErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred.'**
  String get historyErrorUnknown;

  /// No description provided for @historyErrorIndexMissing.
  ///
  /// In en, this message translates to:
  /// **'Database index missing for this query.\nPlease screenshot this and send it to the developer.'**
  String get historyErrorIndexMissing;

  /// No description provided for @historyErrorAlreadyDeleted.
  ///
  /// In en, this message translates to:
  /// **'This record or promise was already deleted,\nso a reaction can\'t be left.'**
  String get historyErrorAlreadyDeleted;

  /// No description provided for @historyErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get historyErrorTitle;

  /// No description provided for @historyErrorCreationLink.
  ///
  /// In en, this message translates to:
  /// **'Creation link:'**
  String get historyErrorCreationLink;

  /// No description provided for @historyOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get historyOk;

  /// No description provided for @historySectionActive.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get historySectionActive;

  /// No description provided for @historySectionFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get historySectionFinished;

  /// No description provided for @historyToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get historyToday;

  /// No description provided for @historyYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get historyYesterday;

  /// No description provided for @historyDatePattern.
  ///
  /// In en, this message translates to:
  /// **'MMM d (EEE)'**
  String get historyDatePattern;

  /// No description provided for @historyCardDatePattern.
  ///
  /// In en, this message translates to:
  /// **'M/d (EEE)'**
  String get historyCardDatePattern;

  /// No description provided for @historyWeeklyPulseTitle.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get historyWeeklyPulseTitle;

  /// No description provided for @historyWeeklyMeLabel.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get historyWeeklyMeLabel;

  /// No description provided for @historyWeeklyPartnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get historyWeeklyPartnerLabel;

  /// No description provided for @historyReconcileTitle.
  ///
  /// In en, this message translates to:
  /// **'Reconcile past record'**
  String get historyReconcileTitle;

  /// No description provided for @historyReconcileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What actually happened on this day?'**
  String get historyReconcileSubtitle;

  /// No description provided for @historyReconcileHold.
  ///
  /// In en, this message translates to:
  /// **'Leave it'**
  String get historyReconcileHold;

  /// No description provided for @usNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get usNoticeTitle;

  /// No description provided for @usOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get usOk;

  /// No description provided for @usProfileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Profile save failed: {error}'**
  String usProfileSaveFailed(String error);

  /// No description provided for @usEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get usEditProfile;

  /// No description provided for @usNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get usNameLabel;

  /// No description provided for @usStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status message'**
  String get usStatusLabel;

  /// No description provided for @usCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get usCancel;

  /// No description provided for @usSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get usSave;

  /// No description provided for @usSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all >'**
  String get usSeeAll;

  /// No description provided for @usEmptyMine.
  ///
  /// In en, this message translates to:
  /// **'No promises yet'**
  String get usEmptyMine;

  /// No description provided for @usEmptyPartner.
  ///
  /// In en, this message translates to:
  /// **'Partner has no active promises'**
  String get usEmptyPartner;

  /// No description provided for @usCreatePlanShort.
  ///
  /// In en, this message translates to:
  /// **'+ New promise'**
  String get usCreatePlanShort;

  /// No description provided for @usCreatePlan.
  ///
  /// In en, this message translates to:
  /// **'New promise'**
  String get usCreatePlan;

  /// No description provided for @usDeletePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this promise?'**
  String get usDeletePlanTitle;

  /// No description provided for @usDeletePlanBody.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone.'**
  String get usDeletePlanBody;

  /// No description provided for @usPlanDeleted.
  ///
  /// In en, this message translates to:
  /// **'Promise deleted.'**
  String get usPlanDeleted;

  /// No description provided for @usDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String usDeleteFailed(String error);

  /// No description provided for @usDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get usDelete;

  /// No description provided for @planDetailPracticeHistory.
  ///
  /// In en, this message translates to:
  /// **'Practice log'**
  String get planDetailPracticeHistory;

  /// No description provided for @planDetailLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load records.\n{error}'**
  String planDetailLoadFailed(String error);

  /// No description provided for @planDetailNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No records yet.'**
  String get planDetailNoRecords;

  /// No description provided for @planDetailNotSavedPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan not saved.'**
  String get planDetailNotSavedPlan;

  /// No description provided for @planDetailRecordDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get planDetailRecordDone;

  /// No description provided for @planDetailRecordSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get planDetailRecordSkipped;

  /// No description provided for @planDetailRecordRested.
  ///
  /// In en, this message translates to:
  /// **'Rested'**
  String get planDetailRecordRested;

  /// No description provided for @planDetailRecordRescued.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get planDetailRecordRescued;

  /// No description provided for @planDetailPokeSent.
  ///
  /// In en, this message translates to:
  /// **'Knock knock — door tapped!'**
  String get planDetailPokeSent;

  /// No description provided for @planDetailPokeFailed.
  ///
  /// In en, this message translates to:
  /// **'Send failed: {error}'**
  String planDetailPokeFailed(String error);

  /// No description provided for @planDetailPokeDoneToday.
  ///
  /// In en, this message translates to:
  /// **'Knock sent for today'**
  String get planDetailPokeDoneToday;

  /// No description provided for @planDetailPokeSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get planDetailPokeSending;

  /// No description provided for @planDetailPokeAsk.
  ///
  /// In en, this message translates to:
  /// **'Knock knock… are you forgetting?'**
  String get planDetailPokeAsk;

  /// No description provided for @planDetailPokeAlreadyDone.
  ///
  /// In en, this message translates to:
  /// **'Already done today'**
  String get planDetailPokeAlreadyDone;

  /// No description provided for @planDetailDayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get planDetailDayMon;

  /// No description provided for @planDetailDayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get planDetailDayTue;

  /// No description provided for @planDetailDayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get planDetailDayWed;

  /// No description provided for @planDetailDayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get planDetailDayThu;

  /// No description provided for @planDetailDayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get planDetailDayFri;

  /// No description provided for @planDetailDaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get planDetailDaySat;

  /// No description provided for @planDetailDaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get planDetailDaySun;

  /// No description provided for @planDetailEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get planDetailEveryDay;

  /// No description provided for @planDetailTimeUnset.
  ///
  /// In en, this message translates to:
  /// **'Time not set'**
  String get planDetailTimeUnset;

  /// No description provided for @planDetailNotificationSaved.
  ///
  /// In en, this message translates to:
  /// **'Notification settings saved.'**
  String get planDetailNotificationSaved;

  /// No description provided for @planDetailNotificationSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save notification setting. Reverted to the previous one.'**
  String get planDetailNotificationSaveFailed;

  /// No description provided for @planDetailSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get planDetailSave;

  /// No description provided for @planDetailStopTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop this promise?'**
  String get planDetailStopTitle;

  /// No description provided for @planDetailStopBody.
  ///
  /// In en, this message translates to:
  /// **'Even if you stop, your record so far is kept.'**
  String get planDetailStopBody;

  /// No description provided for @planDetailCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get planDetailCancel;

  /// No description provided for @planDetailStopped.
  ///
  /// In en, this message translates to:
  /// **'Promise stopped.'**
  String get planDetailStopped;

  /// No description provided for @planDetailActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed: {error}'**
  String planDetailActionFailed(String error);

  /// No description provided for @planDetailStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get planDetailStop;

  /// No description provided for @planDetailRestartTitle.
  ///
  /// In en, this message translates to:
  /// **'Restart with the same promise?'**
  String get planDetailRestartTitle;

  /// No description provided for @planDetailRestartBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll copy the previous promise as-is.\nYou can edit it before starting.'**
  String get planDetailRestartBody;

  /// No description provided for @planDetailRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get planDetailRestart;

  /// No description provided for @planDetailReplaceBody.
  ///
  /// In en, this message translates to:
  /// **'Your current promise will be stopped and you\'ll move to create a new one.\nExisting records are kept safe.'**
  String get planDetailReplaceBody;

  /// No description provided for @planDetailReport.
  ///
  /// In en, this message translates to:
  /// **'Practice report'**
  String get planDetailReport;

  /// No description provided for @planDetailReportPeriod.
  ///
  /// In en, this message translates to:
  /// **'Total period'**
  String get planDetailReportPeriod;

  /// No description provided for @planDetailReportDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String planDetailReportDays(int count);

  /// No description provided for @planDetailReportCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completions'**
  String get planDetailReportCompleted;

  /// No description provided for @planDetailReportCount.
  ///
  /// In en, this message translates to:
  /// **'{count} times'**
  String planDetailReportCount(int count);

  /// No description provided for @planDetailReportRate.
  ///
  /// In en, this message translates to:
  /// **'Achievement rate'**
  String get planDetailReportRate;

  /// No description provided for @planDetailRestartWithScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Restart with a new schedule?'**
  String get planDetailRestartWithScheduleTitle;

  /// No description provided for @nowFocusNoteDoneJustNow.
  ///
  /// In en, this message translates to:
  /// **'Focused and completed!'**
  String get nowFocusNoteDoneJustNow;

  /// No description provided for @nowFocusNoteDoneFor.
  ///
  /// In en, this message translates to:
  /// **'Focused for {duration} and completed!'**
  String nowFocusNoteDoneFor(String duration);

  /// No description provided for @nowFocusDurationMinSec.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min {seconds} sec'**
  String nowFocusDurationMinSec(int minutes, int seconds);

  /// No description provided for @nowFocusDurationMin.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String nowFocusDurationMin(int minutes);

  /// No description provided for @nowFocusDurationSec.
  ///
  /// In en, this message translates to:
  /// **'{seconds} sec'**
  String nowFocusDurationSec(int seconds);

  /// No description provided for @nowTodayPromiseFallback.
  ///
  /// In en, this message translates to:
  /// **'Today\'s promise'**
  String get nowTodayPromiseFallback;

  /// No description provided for @nowSkipDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Skip today?'**
  String get nowSkipDialogTitle;

  /// No description provided for @nowSkipDialogBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll mark {title} as skipped for today.'**
  String nowSkipDialogBody(String title);

  /// No description provided for @nowCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get nowCancel;

  /// No description provided for @nowSkipToday.
  ///
  /// In en, this message translates to:
  /// **'Skip today'**
  String get nowSkipToday;

  /// No description provided for @nowSkippedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Skipped today\'s promise.'**
  String get nowSkippedSnackbar;

  /// No description provided for @nowApproveCheering.
  ///
  /// In en, this message translates to:
  /// **'Cheering you on!'**
  String get nowApproveCheering;

  /// No description provided for @nowApproveFailed.
  ///
  /// In en, this message translates to:
  /// **'Approval failed.'**
  String get nowApproveFailed;

  /// No description provided for @nowVerifyDone.
  ///
  /// In en, this message translates to:
  /// **'Practice verified!'**
  String get nowVerifyDone;

  /// No description provided for @nowVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed.'**
  String get nowVerifyFailed;

  /// No description provided for @nowRejectDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Want to adjust a bit more?'**
  String get nowRejectDialogTitle;

  /// No description provided for @nowRejectLessFrequent.
  ///
  /// In en, this message translates to:
  /// **'Lower the frequency'**
  String get nowRejectLessFrequent;

  /// No description provided for @nowRejectDifferentTime.
  ///
  /// In en, this message translates to:
  /// **'Try a different time slot'**
  String get nowRejectDifferentTime;

  /// No description provided for @nowRejectCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom message'**
  String get nowRejectCustom;

  /// No description provided for @nowRejectRequested.
  ///
  /// In en, this message translates to:
  /// **'Adjustment requested'**
  String get nowRejectRequested;

  /// No description provided for @nowRejectCustomDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'What would you like to adjust?'**
  String get nowRejectCustomDialogTitle;

  /// No description provided for @nowRejectCustomHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. How about starting with 3 times a week?'**
  String get nowRejectCustomHint;

  /// No description provided for @nowSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get nowSend;

  /// No description provided for @nowCheerExcited.
  ///
  /// In en, this message translates to:
  /// **'Sent excited support! 🔥'**
  String get nowCheerExcited;

  /// No description provided for @nowCheerLove.
  ///
  /// In en, this message translates to:
  /// **'Sent your love! ❤️'**
  String get nowCheerLove;

  /// No description provided for @nowCheerProud.
  ///
  /// In en, this message translates to:
  /// **'Said you\'re awesome! 👍'**
  String get nowCheerProud;

  /// No description provided for @nowCheerStrength.
  ///
  /// In en, this message translates to:
  /// **'Said hang in there! 💪'**
  String get nowCheerStrength;

  /// No description provided for @nowCheerFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send cheer.'**
  String get nowCheerFailed;

  /// No description provided for @nowPokeNoActivityMessage.
  ///
  /// In en, this message translates to:
  /// **'Knock knock! Someone\'s waiting for a promise. Want to make today\'s?'**
  String get nowPokeNoActivityMessage;

  /// No description provided for @nowPokeSent.
  ///
  /// In en, this message translates to:
  /// **'Sent a knock signal.'**
  String get nowPokeSent;

  /// No description provided for @nowPokeFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the knock.'**
  String get nowPokeFailed;

  /// No description provided for @nowPokeAgainMessage.
  ///
  /// In en, this message translates to:
  /// **'Knock knock! Your partner is waiting. Want to firm up today\'s promise?'**
  String get nowPokeAgainMessage;

  /// No description provided for @nowPokeAgainSent.
  ///
  /// In en, this message translates to:
  /// **'Knock knock — pulled the promise again.'**
  String get nowPokeAgainSent;

  /// No description provided for @nowSettlementSaved.
  ///
  /// In en, this message translates to:
  /// **'4-week settlement saved.'**
  String get nowSettlementSaved;

  /// No description provided for @nowExitDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop here for this 4-week round?'**
  String get nowExitDialogTitle;

  /// No description provided for @nowExitReasonWeakPoke.
  ///
  /// In en, this message translates to:
  /// **'The knock pressure was weak'**
  String get nowExitReasonWeakPoke;

  /// No description provided for @nowExitReasonTooBig.
  ///
  /// In en, this message translates to:
  /// **'The goal was too big'**
  String get nowExitReasonTooBig;

  /// No description provided for @nowExitReasonPartnerBurden.
  ///
  /// In en, this message translates to:
  /// **'Partner verification felt heavy'**
  String get nowExitReasonPartnerBurden;

  /// No description provided for @nowExitReasonCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get nowExitReasonCustomLabel;

  /// No description provided for @nowExitReasonCustomHint.
  ///
  /// In en, this message translates to:
  /// **'Briefly say why you\'re stopping'**
  String get nowExitReasonCustomHint;

  /// No description provided for @nowExitReasonNoCustom.
  ///
  /// In en, this message translates to:
  /// **'No custom reason'**
  String get nowExitReasonNoCustom;

  /// No description provided for @nowExitSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get nowExitSubmit;

  /// No description provided for @nowRestPassTitle.
  ///
  /// In en, this message translates to:
  /// **'Use rest pass'**
  String get nowRestPassTitle;

  /// No description provided for @nowRestPassBody.
  ///
  /// In en, this message translates to:
  /// **'Use one rest pass this week.\nYour streak stays intact.'**
  String get nowRestPassBody;

  /// No description provided for @nowRestPassConfirm.
  ///
  /// In en, this message translates to:
  /// **'Use it'**
  String get nowRestPassConfirm;

  /// No description provided for @nowRestPassUsed.
  ///
  /// In en, this message translates to:
  /// **'Rest well today. Your streak is safe!'**
  String get nowRestPassUsed;

  /// No description provided for @nowRestPassAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'You already used this week\'s rest pass.'**
  String get nowRestPassAlreadyUsed;

  /// No description provided for @nowRestPassError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred.'**
  String get nowRestPassError;

  /// No description provided for @nowRescuedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged the practice! Streak preserved.'**
  String get nowRescuedSnackbar;

  /// No description provided for @nowRescueFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t acknowledge practice.'**
  String get nowRescueFailed;

  /// No description provided for @nowPromiseAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted the promise!'**
  String get nowPromiseAccepted;

  /// No description provided for @nowPromiseDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined the promise.'**
  String get nowPromiseDeclined;

  /// No description provided for @nowPromiseResponseFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send promise response.'**
  String get nowPromiseResponseFailed;

  /// No description provided for @nowPromiseProposed.
  ///
  /// In en, this message translates to:
  /// **'Proposed the promise!'**
  String get nowPromiseProposed;

  /// No description provided for @nowPromiseProposeFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t propose the promise.'**
  String get nowPromiseProposeFailed;

  /// No description provided for @nowTimeMinBeforeAlert.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m before alert'**
  String nowTimeMinBeforeAlert(int minutes);

  /// No description provided for @nowTimeHourBeforeAlert.
  ///
  /// In en, this message translates to:
  /// **'{hours}h before alert'**
  String nowTimeHourBeforeAlert(int hours);

  /// No description provided for @nowTimeMinAfterAlert.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m after alert'**
  String nowTimeMinAfterAlert(int minutes);

  /// No description provided for @nowTimeHourAfterAlert.
  ///
  /// In en, this message translates to:
  /// **'{hours}h after alert'**
  String nowTimeHourAfterAlert(int hours);

  /// No description provided for @nowKeepFlowing.
  ///
  /// In en, this message translates to:
  /// **'Great! Keep this flow going'**
  String get nowKeepFlowing;

  /// No description provided for @nowGuideWhen.
  ///
  /// In en, this message translates to:
  /// **'Setting \"when to do it\" raises your follow-through'**
  String get nowGuideWhen;

  /// No description provided for @nowGuideSmallStart.
  ///
  /// In en, this message translates to:
  /// **'Starting small is fine. Consistency wins'**
  String get nowGuideSmallStart;

  /// No description provided for @nowGuideBetterToday.
  ///
  /// In en, this message translates to:
  /// **'Better than yesterday is enough'**
  String get nowGuideBetterToday;

  /// No description provided for @nowErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get nowErrorTitle;

  /// No description provided for @nowErrorCreationLink.
  ///
  /// In en, this message translates to:
  /// **'Creation link:'**
  String get nowErrorCreationLink;

  /// No description provided for @nowOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get nowOk;

  /// No description provided for @nowRetryLater.
  ///
  /// In en, this message translates to:
  /// **'Please try again later'**
  String get nowRetryLater;

  /// No description provided for @nowPartnerActionFallback.
  ///
  /// In en, this message translates to:
  /// **'Partner\'s practice'**
  String get nowPartnerActionFallback;

  /// No description provided for @nowActionNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Leave a warm note (optional)'**
  String get nowActionNoteHint;

  /// No description provided for @nowVerifyAndSend.
  ///
  /// In en, this message translates to:
  /// **'Verify and send'**
  String get nowVerifyAndSend;

  /// No description provided for @nowStreakCount.
  ///
  /// In en, this message translates to:
  /// **'{count} days in a row!'**
  String nowStreakCount(int count);

  /// No description provided for @nowHeaderAdjustNeeded.
  ///
  /// In en, this message translates to:
  /// **'Adjustment needed'**
  String get nowHeaderAdjustNeeded;

  /// No description provided for @nowHeaderPromiseProposed.
  ///
  /// In en, this message translates to:
  /// **'Promise proposal arrived'**
  String get nowHeaderPromiseProposed;

  /// No description provided for @nowHeaderPromiseSettled.
  ///
  /// In en, this message translates to:
  /// **'Promise result is out'**
  String get nowHeaderPromiseSettled;

  /// No description provided for @nowPromiseAckButton.
  ///
  /// In en, this message translates to:
  /// **'See the result'**
  String get nowPromiseAckButton;

  /// No description provided for @nowPromiseAckWithNote.
  ///
  /// In en, this message translates to:
  /// **'Leave a word and close'**
  String get nowPromiseAckWithNote;

  /// No description provided for @nowPromiseAckDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Promise result'**
  String get nowPromiseAckDialogTitle;

  /// No description provided for @nowPromiseAckDialogHint.
  ///
  /// In en, this message translates to:
  /// **'Drop a quick word for your partner (optional)'**
  String get nowPromiseAckDialogHint;

  /// No description provided for @nowPromiseAckDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get nowPromiseAckDialogConfirm;

  /// No description provided for @nowPromiseAckSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Result acknowledged'**
  String get nowPromiseAckSnackbar;

  /// No description provided for @nowPromiseAckFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not acknowledge the result'**
  String get nowPromiseAckFailed;

  /// No description provided for @planDetailViewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get planDetailViewList;

  /// No description provided for @planDetailViewCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get planDetailViewCalendar;

  /// No description provided for @planDetailViewGraph.
  ///
  /// In en, this message translates to:
  /// **'Graph'**
  String get planDetailViewGraph;

  /// No description provided for @planDetailLegendDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get planDetailLegendDone;

  /// No description provided for @planDetailLegendRested.
  ///
  /// In en, this message translates to:
  /// **'Rested'**
  String get planDetailLegendRested;

  /// No description provided for @planDetailLegendRescued.
  ///
  /// In en, this message translates to:
  /// **'Rescued'**
  String get planDetailLegendRescued;

  /// No description provided for @planDetailLegendSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get planDetailLegendSkipped;

  /// No description provided for @planDetailLegendMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get planDetailLegendMissed;

  /// No description provided for @planDetailLegendScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get planDetailLegendScheduled;

  /// No description provided for @planDetailWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'Week {week}'**
  String planDetailWeekLabel(int week);

  /// No description provided for @planDetailGraphCompletionRate.
  ///
  /// In en, this message translates to:
  /// **'Weekly completion rate'**
  String get planDetailGraphCompletionRate;

  /// No description provided for @planDetailGraphEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to plot yet.'**
  String get planDetailGraphEmpty;

  /// No description provided for @planDetailProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get planDetailProgressTitle;

  /// No description provided for @planDetailProgressSuccessRate.
  ///
  /// In en, this message translates to:
  /// **'Success rate'**
  String get planDetailProgressSuccessRate;

  /// No description provided for @planDetailProgressFractionDays.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} days'**
  String planDetailProgressFractionDays(int done, int total);

  /// No description provided for @planDetailProgressStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get planDetailProgressStreakLabel;

  /// No description provided for @planDetailProgressDoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get planDetailProgressDoneLabel;

  /// No description provided for @planDetailProgressRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get planDetailProgressRemainingLabel;

  /// No description provided for @planDetailProgressMissedLabel.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get planDetailProgressMissedLabel;

  /// No description provided for @planDetailProgressDayUnit.
  ///
  /// In en, this message translates to:
  /// **'{n}d'**
  String planDetailProgressDayUnit(int n);

  /// No description provided for @planDetailProgressCountUnit.
  ///
  /// In en, this message translates to:
  /// **'{n}x'**
  String planDetailProgressCountUnit(int n);

  /// No description provided for @planDetailProgressNoVerdictYet.
  ///
  /// In en, this message translates to:
  /// **'No verdicts in yet'**
  String get planDetailProgressNoVerdictYet;

  /// No description provided for @planDetailPromiseProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Promise progress'**
  String get planDetailPromiseProgressTitle;

  /// No description provided for @planDetailPromiseRewardLabel.
  ///
  /// In en, this message translates to:
  /// **'🏆 Reward'**
  String get planDetailPromiseRewardLabel;

  /// No description provided for @planDetailPromisePenaltyLabel.
  ///
  /// In en, this message translates to:
  /// **'⚡ Penalty'**
  String get planDetailPromisePenaltyLabel;

  /// No description provided for @planDetailPromiseRewardNeed.
  ///
  /// In en, this message translates to:
  /// **'{days} more day(s) to reward'**
  String planDetailPromiseRewardNeed(int days);

  /// No description provided for @planDetailPromiseRewardAchieved.
  ///
  /// In en, this message translates to:
  /// **'🎉 Reward achieved!'**
  String get planDetailPromiseRewardAchieved;

  /// No description provided for @planDetailPromisePenaltyBuffer.
  ///
  /// In en, this message translates to:
  /// **'{buffer} miss(es) of room'**
  String planDetailPromisePenaltyBuffer(int buffer);

  /// No description provided for @planDetailPromisePenaltyImminent.
  ///
  /// In en, this message translates to:
  /// **'One more miss triggers penalty'**
  String get planDetailPromisePenaltyImminent;

  /// No description provided for @planDetailPromisePenaltyTriggered.
  ///
  /// In en, this message translates to:
  /// **'⚡ Penalty triggered'**
  String get planDetailPromisePenaltyTriggered;

  /// No description provided for @planDetailMoreMenu.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get planDetailMoreMenu;

  /// No description provided for @planDetailMenuRestartCompleted.
  ///
  /// In en, this message translates to:
  /// **'Make a new plan from this'**
  String get planDetailMenuRestartCompleted;

  /// No description provided for @planDetailMenuRestartActive.
  ///
  /// In en, this message translates to:
  /// **'Restart with new schedule'**
  String get planDetailMenuRestartActive;

  /// No description provided for @planDetailMenuStop.
  ///
  /// In en, this message translates to:
  /// **'Stop plan'**
  String get planDetailMenuStop;

  /// No description provided for @planDetailPromiseSuccessFailBreakdown.
  ///
  /// In en, this message translates to:
  /// **'{success} done · {fail} missed'**
  String planDetailPromiseSuccessFailBreakdown(int success, int fail);

  /// No description provided for @nowHeaderSettlementNeeded.
  ///
  /// In en, this message translates to:
  /// **'4-week settlement needed'**
  String get nowHeaderSettlementNeeded;

  /// No description provided for @nowHeaderSettlementSub.
  ///
  /// In en, this message translates to:
  /// **'Confirm whether the knock really pulled the promise and pick the next 4 weeks.'**
  String get nowHeaderSettlementSub;

  /// No description provided for @nowMetricCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get nowMetricCompleted;

  /// No description provided for @nowMetricPartnerReact.
  ///
  /// In en, this message translates to:
  /// **'Partner reactions'**
  String get nowMetricPartnerReact;

  /// No description provided for @nowMetricMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed days'**
  String get nowMetricMissed;

  /// No description provided for @nowMetricDaysSuffix.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String nowMetricDaysSuffix(int count);

  /// No description provided for @nowMetricCountSuffix.
  ///
  /// In en, this message translates to:
  /// **'{count} times'**
  String nowMetricCountSuffix(int count);

  /// No description provided for @nowSettlementWinMessage.
  ///
  /// In en, this message translates to:
  /// **'You passed the meaningful 12-day mark. Time to decide on the next 4 weeks.'**
  String get nowSettlementWinMessage;

  /// No description provided for @nowSettlementLoseMessage.
  ///
  /// In en, this message translates to:
  /// **'More important than finishing is noting where you stopped. Leave a reason to make the next attempt easier.'**
  String get nowSettlementLoseMessage;

  /// No description provided for @nowRewardCondition.
  ///
  /// In en, this message translates to:
  /// **'{days} successful days: {description}'**
  String nowRewardCondition(int days, String description);

  /// No description provided for @nowPenaltyCondition.
  ///
  /// In en, this message translates to:
  /// **'{days} failed days: {description}'**
  String nowPenaltyCondition(int days, String description);

  /// No description provided for @nowPromiseResult.
  ///
  /// In en, this message translates to:
  /// **'Successes {success} / Failures {fail}'**
  String nowPromiseResult(int success, int fail);

  /// No description provided for @nowAchieved.
  ///
  /// In en, this message translates to:
  /// **'Achieved!'**
  String get nowAchieved;

  /// No description provided for @nowTriggered.
  ///
  /// In en, this message translates to:
  /// **'Triggered!'**
  String get nowTriggered;

  /// No description provided for @nowNotMet.
  ///
  /// In en, this message translates to:
  /// **'Not met'**
  String get nowNotMet;

  /// No description provided for @nowDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get nowDecline;

  /// No description provided for @nowAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get nowAccept;

  /// No description provided for @nowContinueNext4Weeks.
  ///
  /// In en, this message translates to:
  /// **'Start the next 4 weeks'**
  String get nowContinueNext4Weeks;

  /// No description provided for @nowStopHere.
  ///
  /// In en, this message translates to:
  /// **'Stop this 4-week round here'**
  String get nowStopHere;

  /// No description provided for @nowModify.
  ///
  /// In en, this message translates to:
  /// **'Modify'**
  String get nowModify;

  /// No description provided for @nowStartFocusTimer.
  ///
  /// In en, this message translates to:
  /// **'Start now! (Focus timer)'**
  String get nowStartFocusTimer;

  /// No description provided for @nowRestToday.
  ///
  /// In en, this message translates to:
  /// **'Rest today (rest pass)'**
  String get nowRestToday;

  /// No description provided for @nowMissedPlanFallback.
  ///
  /// In en, this message translates to:
  /// **'Past promise'**
  String get nowMissedPlanFallback;

  /// No description provided for @nowVerifyingDeadline.
  ///
  /// In en, this message translates to:
  /// **'Waiting for verification · cheer needed'**
  String get nowVerifyingDeadline;

  /// No description provided for @nowHeaderTodayAllDone.
  ///
  /// In en, this message translates to:
  /// **'All today\'s promises kept'**
  String get nowHeaderTodayAllDone;

  /// No description provided for @nowHeaderConfirmAndPull.
  ///
  /// In en, this message translates to:
  /// **'Time to verify and pull'**
  String get nowHeaderConfirmAndPull;

  /// No description provided for @nowHeaderWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get nowHeaderWaiting;

  /// No description provided for @nowHeaderWaitingAccept.
  ///
  /// In en, this message translates to:
  /// **'Waiting for promise approval'**
  String get nowHeaderWaitingAccept;

  /// No description provided for @nowHeaderPromiseResult.
  ///
  /// In en, this message translates to:
  /// **'Promise result is out'**
  String get nowHeaderPromiseResult;

  /// No description provided for @nowAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get nowAdjust;

  /// No description provided for @nowApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get nowApprove;

  /// No description provided for @nowPartnerNoNewPlanGuide.
  ///
  /// In en, this message translates to:
  /// **'The other person hasn\'t made a new promise. Want to knock before it gets buried?'**
  String get nowPartnerNoNewPlanGuide;

  /// No description provided for @nowKnockMakePlan.
  ///
  /// In en, this message translates to:
  /// **'Knock! Ask to make a promise'**
  String get nowKnockMakePlan;

  /// No description provided for @nowPartnerMissedPokeBody.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s promise is now a missed promise. Knock to pull it again.'**
  String nowPartnerMissedPokeBody(String name);

  /// No description provided for @nowPartnerQuietPokeBody.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s promise is still quiet. Knock before it gets buried.'**
  String nowPartnerQuietPokeBody(String name);

  /// No description provided for @nowKnockPull.
  ///
  /// In en, this message translates to:
  /// **'Knock! Pull'**
  String get nowKnockPull;

  /// No description provided for @nowRescueYesterday.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge yesterday'**
  String get nowRescueYesterday;

  /// No description provided for @nowVerifyAndCheer.
  ///
  /// In en, this message translates to:
  /// **'Verify and cheer'**
  String get nowVerifyAndCheer;

  /// No description provided for @nowMakePromise.
  ///
  /// In en, this message translates to:
  /// **'Make a promise'**
  String get nowMakePromise;

  /// No description provided for @nowPartnerFallback2.
  ///
  /// In en, this message translates to:
  /// **'partner'**
  String get nowPartnerFallback2;

  /// No description provided for @nowPartnerAllDone.
  ///
  /// In en, this message translates to:
  /// **'{name} kept all today\'s promises.'**
  String nowPartnerAllDone(String name);

  /// No description provided for @nowQuickCheckHelp.
  ///
  /// In en, this message translates to:
  /// **'A quick verification makes tomorrow easier too.'**
  String get nowQuickCheckHelp;

  /// No description provided for @nowLastAction.
  ///
  /// In en, this message translates to:
  /// **'Last action: {title}'**
  String nowLastAction(String title);

  /// No description provided for @nowRewardLine.
  ///
  /// In en, this message translates to:
  /// **'🏆 {days} successful days: {description}'**
  String nowRewardLine(int days, String description);

  /// No description provided for @nowPenaltyLine.
  ///
  /// In en, this message translates to:
  /// **'⚡ {days} failed days: {description}'**
  String nowPenaltyLine(int days, String description);

  /// No description provided for @nowResultLine.
  ///
  /// In en, this message translates to:
  /// **'Result: Successes {success} / Failures {fail}'**
  String nowResultLine(int success, int fail);

  /// No description provided for @nowWaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval…'**
  String get nowWaitingApproval;

  /// No description provided for @nowRewardAchievedTitle.
  ///
  /// In en, this message translates to:
  /// **'🎉 Reward earned!'**
  String get nowRewardAchievedTitle;

  /// No description provided for @nowPenaltyTriggeredTitle.
  ///
  /// In en, this message translates to:
  /// **'⚡ Penalty triggered!'**
  String get nowPenaltyTriggeredTitle;

  /// No description provided for @nowBothTitle.
  ///
  /// In en, this message translates to:
  /// **'🎉 Reward earned! + ⚡ Penalty triggered!'**
  String get nowBothTitle;

  /// No description provided for @nowConditionNotMet.
  ///
  /// In en, this message translates to:
  /// **'Conditions not met'**
  String get nowConditionNotMet;

  /// No description provided for @nowTotalDaysOnly.
  ///
  /// In en, this message translates to:
  /// **'A {days}-day promise'**
  String nowTotalDaysOnly(int days);

  /// No description provided for @nowTotalDaysScheduled.
  ///
  /// In en, this message translates to:
  /// **'A {days}-day promise · {scheduled} practice days planned'**
  String nowTotalDaysScheduled(int days, int scheduled);

  /// No description provided for @nowMakePromiseTitle.
  ///
  /// In en, this message translates to:
  /// **'Make a promise'**
  String get nowMakePromiseTitle;

  /// No description provided for @nowMakePromiseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'It starts once your partner accepts'**
  String get nowMakePromiseSubtitle;

  /// No description provided for @nowProgressLine.
  ///
  /// In en, this message translates to:
  /// **'Currently {success} successes · {failed} failures · {remaining} days remaining'**
  String nowProgressLine(int success, int failed, int remaining);

  /// No description provided for @nowMaxLimitsLine.
  ///
  /// In en, this message translates to:
  /// **'Reward up to {reward} days, penalty up to {penalty} days.'**
  String nowMaxLimitsLine(int reward, int penalty);

  /// No description provided for @nowRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'🏆 Reward (carrot)'**
  String get nowRewardTitle;

  /// No description provided for @nowRewardHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. treat to chicken, fancy dinner'**
  String get nowRewardHint;

  /// No description provided for @nowRewardTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Success target'**
  String get nowRewardTargetLabel;

  /// No description provided for @nowPenaltyTitle.
  ///
  /// In en, this message translates to:
  /// **'⚡ Penalty (stick)'**
  String get nowPenaltyTitle;

  /// No description provided for @nowPenaltyHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. dishes for a week, buy coffee'**
  String get nowPenaltyHint;

  /// No description provided for @nowPenaltyTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Failure limit'**
  String get nowPenaltyTargetLabel;

  /// No description provided for @nowProposePromise.
  ///
  /// In en, this message translates to:
  /// **'Propose promise'**
  String get nowProposePromise;

  /// No description provided for @nowDaysSuffix.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String nowDaysSuffix(int count);

  /// No description provided for @nowMaxDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Max {days} days'**
  String nowMaxDaysLabel(int days);

  /// No description provided for @nowPokeReceived.
  ///
  /// In en, this message translates to:
  /// **'Your partner sent a knock'**
  String get nowPokeReceived;

  /// No description provided for @nowPokeReceivedFromName.
  ///
  /// In en, this message translates to:
  /// **'{name} sent a knock'**
  String nowPokeReceivedFromName(String name);

  /// No description provided for @nowYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get nowYesterday;

  /// No description provided for @nowNoteDateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get nowNoteDateToday;
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
