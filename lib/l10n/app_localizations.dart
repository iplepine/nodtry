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
  /// **'DuoDone'**
  String get appTitle;

  /// Tagline shown on splash screen
  ///
  /// In en, this message translates to:
  /// **'When your partner sees it, you actually do it.'**
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
  /// **'You both agree to connect.\nProof photos are seen only by your partner.'**
  String get privacyMessage;

  /// Headline on connect screen
  ///
  /// In en, this message translates to:
  /// **'Invite your partner'**
  String get connectHeadline;

  /// Subtitle on connect screen
  ///
  /// In en, this message translates to:
  /// **'Send your code so you can back each other\'s workout promises.'**
  String get connectSubtitle;

  /// Button to enter invite code
  ///
  /// In en, this message translates to:
  /// **'Enter your partner\'s code'**
  String get enterInviteCode;

  /// Button to start without connecting to a partner
  ///
  /// In en, this message translates to:
  /// **'I\'ll connect later'**
  String get startSolo;

  /// Message when code is copied
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get codeCopied;

  /// Instruction to enter code
  ///
  /// In en, this message translates to:
  /// **'Enter the code below'**
  String get enterCodeBelow;

  /// Button to send connection request
  ///
  /// In en, this message translates to:
  /// **'Connect as partners'**
  String get sendConnectionRequest;

  /// Button to report completion
  ///
  /// In en, this message translates to:
  /// **'Did it'**
  String get homeDidIt;

  /// Message when there's a verification needed
  ///
  /// In en, this message translates to:
  /// **'News from your partner'**
  String get homeReceivedMessage;

  /// Message when report is checked
  ///
  /// In en, this message translates to:
  /// **'Props'**
  String get homeChecked;

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
  /// **'Backing each other\'s workouts'**
  String get usHeroSubtitle;

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

  /// Us tab - My invite code button
  ///
  /// In en, this message translates to:
  /// **'My Invite Code'**
  String get usMyInviteCode;

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

  /// No description provided for @usLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your connection.'**
  String get usLoadError;

  /// No description provided for @usNoInviteCode.
  ///
  /// In en, this message translates to:
  /// **'No Code'**
  String get usNoInviteCode;

  /// No description provided for @usUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
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
  /// **'You\'re no longer connected.'**
  String get usDisconnectSuccess;

  /// No description provided for @usDisconnectError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t disconnect. Please try again.'**
  String get usDisconnectError;

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
  /// **'Connect your partner'**
  String get usAddConnectionLabel;

  /// Us tab - Badge: Mutual support
  ///
  /// In en, this message translates to:
  /// **'Together'**
  String get usBadgeMutual;

  /// Us tab - Empty state title
  ///
  /// In en, this message translates to:
  /// **'No partner yet'**
  String get usEmptyMatesTitle;

  /// Us tab - Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Invite your partner and back each other\'s workout promises'**
  String get usEmptyMatesSubtitle;

  /// Message when there's no active plan
  ///
  /// In en, this message translates to:
  /// **'No workout promise yet'**
  String get nowNoPlan;

  /// Button to create a new plan
  ///
  /// In en, this message translates to:
  /// **'+ Make a workout promise'**
  String get nowCreatePlan;

  /// Quiet state message - rest
  ///
  /// In en, this message translates to:
  /// **'Today\'s a rest day'**
  String get nowQuietRest;

  /// Subtitle when there's no plan
  ///
  /// In en, this message translates to:
  /// **'Pick one workout and make it a promise'**
  String get nowNoPlanSubtitle;

  /// Message when all tasks are done
  ///
  /// In en, this message translates to:
  /// **'All of today\'s promises kept 🙌'**
  String get nowTodayDone;

  /// Headline when multiple plans were completed today
  ///
  /// In en, this message translates to:
  /// **'Kept all {count} promises today 🙌'**
  String nowTodayAllDone(int count);

  /// Partner plan share - proposed
  ///
  /// In en, this message translates to:
  /// **'{name} sent a new promise'**
  String nowPartnerProposed(String name);

  /// Partner plan share - adjusting
  ///
  /// In en, this message translates to:
  /// **'Your partner tweaked a promise'**
  String get nowPartnerAdjusting;

  /// Action to skip today's task
  ///
  /// In en, this message translates to:
  /// **'Skip today'**
  String get nowActionSkipToday;

  /// No description provided for @nowDeferMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Set aside'**
  String get nowDeferMenuTooltip;

  /// No description provided for @nowDeferLaterTitle.
  ///
  /// In en, this message translates to:
  /// **'I\'ll do it later'**
  String get nowDeferLaterTitle;

  /// No description provided for @nowDeferLaterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll show your next promise now and nudge you again later'**
  String get nowDeferLaterSubtitle;

  /// No description provided for @nowSkipTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Skip today'**
  String get nowSkipTodayTitle;

  /// No description provided for @nowSkipTodaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Counts as missed — your streak may reset'**
  String get nowSkipTodaySubtitle;

  /// Defer sheet: rest-pass option subtitle
  ///
  /// In en, this message translates to:
  /// **'Use a rest pass — your streak stays'**
  String get nowDeferRestSubtitle;

  /// No description provided for @nowSkipTodayDone.
  ///
  /// In en, this message translates to:
  /// **'Skipped for today'**
  String get nowSkipTodayDone;

  /// No description provided for @nowDeferLaterDone.
  ///
  /// In en, this message translates to:
  /// **'We\'ll nudge you again a bit later'**
  String get nowDeferLaterDone;

  /// No description provided for @nowDeferReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Here\'s your nudge'**
  String get nowDeferReminderTitle;

  /// No description provided for @nowDeferReminderBody.
  ///
  /// In en, this message translates to:
  /// **'You set a promise aside for later'**
  String get nowDeferReminderBody;

  /// Button to add more plans in TodayComplete/TodayEmpty state
  ///
  /// In en, this message translates to:
  /// **'Add another workout promise?'**
  String get nowAddMorePlan;

  /// Title asking what to promise
  ///
  /// In en, this message translates to:
  /// **'Which workout will you promise?'**
  String get planWhatToPromise;

  /// Hint about what kind of promise to make
  ///
  /// In en, this message translates to:
  /// **'Something you think you can keep'**
  String get planPromiseHint;

  /// Hint text for action input field
  ///
  /// In en, this message translates to:
  /// **'e.g., 30 min at the gym, a 10k-step walk after dinner'**
  String get planActionHint;

  /// Hint text for description input field
  ///
  /// In en, this message translates to:
  /// **'e.g., Squats and stretching at home, leg workout at gym...'**
  String get planDescriptionHint;

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

  /// Connect screen description
  ///
  /// In en, this message translates to:
  /// **'Partner connection screen'**
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

  /// Action selection screen description
  ///
  /// In en, this message translates to:
  /// **'Screen 1: Action selection'**
  String get developerScreenActionSelectionDesc;

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
  /// **'Together with {name}'**
  String headerWithPartner(String name);

  /// No description provided for @usLinkEmailSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email account linked!'**
  String get usLinkEmailSuccess;

  /// History card label when partner verified
  ///
  /// In en, this message translates to:
  /// **'Your partner gave props'**
  String get historyPartnerVerified;

  /// History card label when I verified
  ///
  /// In en, this message translates to:
  /// **'You gave props'**
  String get historyMeVerified;

  /// Frequency label for everyday
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get frequencyEveryday;

  /// Title for my plan section
  ///
  /// In en, this message translates to:
  /// **'My promises'**
  String get usMyPlanTitle;

  /// Title for partner plan section
  ///
  /// In en, this message translates to:
  /// **'{name}\'s promises'**
  String usPartnerPlanTitle(String name);

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
  /// **'Log out of your current account'**
  String get settingsLogoutDesc;

  /// Title for logout confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogoutDialogTitle;

  /// Content for logout confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Log out now?'**
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
  /// **'Permanently delete your account and records'**
  String get settingsDeleteAccountDesc;

  /// Title for delete account confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get settingsDeleteAccountDialogTitle;

  /// Content for delete account confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete your account? Your account, records and proof photos will be erased, and this can\'t be undone. You may be asked to sign in once more to confirm.'**
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

  /// Error message for user not found
  ///
  /// In en, this message translates to:
  /// **'No account found for that email.'**
  String get userNotFound;

  /// Success message after account deletion
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get settingsAccountDeletedSuccess;

  /// No description provided for @settingsDeleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t delete your account. Please try again.'**
  String get settingsDeleteAccountFailed;

  /// Account deletion: the re-sign-in was cancelled
  ///
  /// In en, this message translates to:
  /// **'You need to sign in again to delete your account. Nothing was deleted.'**
  String get settingsDeleteAccountReauthCancelled;

  /// Account deletion: wrong password
  ///
  /// In en, this message translates to:
  /// **'That password isn\'t right. Please try again.'**
  String get settingsDeleteAccountWrongPassword;

  /// Account deletion: password prompt title (email accounts)
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get settingsDeleteAccountPasswordTitle;

  /// No description provided for @settingsDeleteAccountPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get settingsDeleteAccountPasswordHint;

  /// No description provided for @reconcileTookRest.
  ///
  /// In en, this message translates to:
  /// **'Took a rest'**
  String get reconcileTookRest;

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

  /// No description provided for @nowDoEarly.
  ///
  /// In en, this message translates to:
  /// **'Do it now'**
  String get nowDoEarly;

  /// No description provided for @nowDoAnytime.
  ///
  /// In en, this message translates to:
  /// **'Do it today'**
  String get nowDoAnytime;

  /// No description provided for @timeChipAnytime.
  ///
  /// In en, this message translates to:
  /// **'Anytime today'**
  String get timeChipAnytime;

  /// No description provided for @nowNextActionLater.
  ///
  /// In en, this message translates to:
  /// **'Not time yet — you can do this later today.'**
  String get nowNextActionLater;

  /// No description provided for @nowNextActionAnytime.
  ///
  /// In en, this message translates to:
  /// **'Do this anytime today.'**
  String get nowNextActionAnytime;

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

  /// No description provided for @planMine.
  ///
  /// In en, this message translates to:
  /// **'Your promise in one line'**
  String get planMine;

  /// No description provided for @planClearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get planClearAction;

  /// No description provided for @planPartnerPreviewWithout.
  ///
  /// In en, this message translates to:
  /// **'You can start solo. Connect your partner to give each other props and knocks.'**
  String get planPartnerPreviewWithout;

  /// No description provided for @planConnectPartner.
  ///
  /// In en, this message translates to:
  /// **'Connect your partner'**
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
  /// **'{count, plural, =1{1 day/week} other{{count} days/week}}'**
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
  /// **'{hour} {period}'**
  String planTimeFormatNoMinute(String period, int hour);

  /// No description provided for @planTimeFormatWithMinute.
  ///
  /// In en, this message translates to:
  /// **'{hour}:{minute} {period}'**
  String planTimeFormatWithMinute(String period, int hour, String minute);

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

  /// No description provided for @planTellUsActionFirst.
  ///
  /// In en, this message translates to:
  /// **'Tell us which workout you\'ll do!'**
  String get planTellUsActionFirst;

  /// No description provided for @planSaveError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save your promise. Please try again.'**
  String get planSaveError;

  /// No description provided for @planCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New workout promise'**
  String get planCreateTitle;

  /// No description provided for @planEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit promise'**
  String get planEditTitle;

  /// No description provided for @planCreateHeaderWithPartner.
  ///
  /// In en, this message translates to:
  /// **'Which workout will you promise {name}?'**
  String planCreateHeaderWithPartner(String name);

  /// No description provided for @planCreateDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Which days?'**
  String get planCreateDaysTitle;

  /// No description provided for @planCreateDaysRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one day'**
  String get planCreateDaysRequired;

  /// No description provided for @planCreateDaysFromPartner.
  ///
  /// In en, this message translates to:
  /// **'Matched to {name}\'s workout days'**
  String planCreateDaysFromPartner(String name);

  /// No description provided for @planCreateDeadlineTitle.
  ///
  /// In en, this message translates to:
  /// **'Done by when?'**
  String get planCreateDeadlineTitle;

  /// No description provided for @planCreateDeadlineHint.
  ///
  /// In en, this message translates to:
  /// **'We\'ll remind you at this time'**
  String get planCreateDeadlineHint;

  /// No description provided for @planCreateDeadlineRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick a deadline'**
  String get planCreateDeadlineRequired;

  /// No description provided for @planDeadlineMorning.
  ///
  /// In en, this message translates to:
  /// **'7 AM'**
  String get planDeadlineMorning;

  /// No description provided for @planDeadlineNoon.
  ///
  /// In en, this message translates to:
  /// **'Noon'**
  String get planDeadlineNoon;

  /// No description provided for @planDeadlineEvening.
  ///
  /// In en, this message translates to:
  /// **'7 PM'**
  String get planDeadlineEvening;

  /// No description provided for @planDeadlineNight.
  ///
  /// In en, this message translates to:
  /// **'9 PM'**
  String get planDeadlineNight;

  /// No description provided for @planDeadlineLateNight.
  ///
  /// In en, this message translates to:
  /// **'10 PM'**
  String get planDeadlineLateNight;

  /// No description provided for @planDeadlineCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get planDeadlineCustom;

  /// No description provided for @planCreateMemoToggle.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get planCreateMemoToggle;

  /// No description provided for @planCreatePartnerNotice.
  ///
  /// In en, this message translates to:
  /// **'Miss it and {name} will know'**
  String planCreatePartnerNotice(String name);

  /// Main button when a partner is connected. ko uses nameWithParticle (the name + 이랑/랑, built with withJosa); en uses name.
  ///
  /// In en, this message translates to:
  /// **'🤙 Pinky promise with {name}'**
  String planCreateCtaWithPartner(String name, String nameWithParticle);

  /// No description provided for @planCreateCtaSolo.
  ///
  /// In en, this message translates to:
  /// **'Start my promise'**
  String get planCreateCtaSolo;

  /// No description provided for @planEditCta.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get planEditCta;

  /// No description provided for @planSavedWithPartner.
  ///
  /// In en, this message translates to:
  /// **'Workout promise made with {name} 🤙'**
  String planSavedWithPartner(String name);

  /// No description provided for @planSavedSolo.
  ///
  /// In en, this message translates to:
  /// **'Your workout promise has started 💪'**
  String get planSavedSolo;

  /// No description provided for @planEditSaved.
  ///
  /// In en, this message translates to:
  /// **'Promise updated'**
  String get planEditSaved;

  /// No description provided for @planDayPresetTwoDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'2 days/wk'**
  String get planDayPresetTwoDaysLabel;

  /// No description provided for @workoutTypeGymLabel.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get workoutTypeGymLabel;

  /// No description provided for @workoutTypeGymAction.
  ///
  /// In en, this message translates to:
  /// **'Hit the gym'**
  String get workoutTypeGymAction;

  /// No description provided for @workoutTypeRunningLabel.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get workoutTypeRunningLabel;

  /// No description provided for @workoutTypeRunningAction.
  ///
  /// In en, this message translates to:
  /// **'Run for 30 minutes'**
  String get workoutTypeRunningAction;

  /// No description provided for @workoutTypeHomeTrainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Home workout'**
  String get workoutTypeHomeTrainingLabel;

  /// No description provided for @workoutTypeHomeTrainingAction.
  ///
  /// In en, this message translates to:
  /// **'20-minute home workout'**
  String get workoutTypeHomeTrainingAction;

  /// No description provided for @workoutTypeWalkingLabel.
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get workoutTypeWalkingLabel;

  /// No description provided for @workoutTypeWalkingAction.
  ///
  /// In en, this message translates to:
  /// **'Walk for 30 minutes'**
  String get workoutTypeWalkingAction;

  /// No description provided for @workoutTypePilatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Pilates'**
  String get workoutTypePilatesLabel;

  /// No description provided for @workoutTypePilatesAction.
  ///
  /// In en, this message translates to:
  /// **'Go to Pilates class'**
  String get workoutTypePilatesAction;

  /// No description provided for @workoutTypeYogaLabel.
  ///
  /// In en, this message translates to:
  /// **'Yoga'**
  String get workoutTypeYogaLabel;

  /// No description provided for @workoutTypeYogaAction.
  ///
  /// In en, this message translates to:
  /// **'30 minutes of yoga'**
  String get workoutTypeYogaAction;

  /// No description provided for @workoutTypeStretchingLabel.
  ///
  /// In en, this message translates to:
  /// **'Stretching'**
  String get workoutTypeStretchingLabel;

  /// No description provided for @workoutTypeStretchingAction.
  ///
  /// In en, this message translates to:
  /// **'Stretch for 10 minutes before bed'**
  String get workoutTypeStretchingAction;

  /// No description provided for @workoutTypeSwimmingLabel.
  ///
  /// In en, this message translates to:
  /// **'Swimming'**
  String get workoutTypeSwimmingLabel;

  /// No description provided for @workoutTypeSwimmingAction.
  ///
  /// In en, this message translates to:
  /// **'Go for a swim'**
  String get workoutTypeSwimmingAction;

  /// No description provided for @workoutTypeClimbingLabel.
  ///
  /// In en, this message translates to:
  /// **'Climbing'**
  String get workoutTypeClimbingLabel;

  /// No description provided for @workoutTypeClimbingAction.
  ///
  /// In en, this message translates to:
  /// **'Go climbing'**
  String get workoutTypeClimbingAction;

  /// No description provided for @workoutTypeCyclingLabel.
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get workoutTypeCyclingLabel;

  /// No description provided for @workoutTypeCyclingAction.
  ///
  /// In en, this message translates to:
  /// **'Ride a bike for 40 minutes'**
  String get workoutTypeCyclingAction;

  /// No description provided for @workoutTypeHikingLabel.
  ///
  /// In en, this message translates to:
  /// **'Hiking'**
  String get workoutTypeHikingLabel;

  /// No description provided for @workoutTypeHikingAction.
  ///
  /// In en, this message translates to:
  /// **'Go hiking'**
  String get workoutTypeHikingAction;

  /// No description provided for @workoutTypeStrengthLabel.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get workoutTypeStrengthLabel;

  /// No description provided for @workoutTypeStrengthAction.
  ///
  /// In en, this message translates to:
  /// **'30 minutes of strength training'**
  String get workoutTypeStrengthAction;

  /// No description provided for @workoutTypeDietLabel.
  ///
  /// In en, this message translates to:
  /// **'Diet · no late snacks'**
  String get workoutTypeDietLabel;

  /// No description provided for @workoutTypeDietAction.
  ///
  /// In en, this message translates to:
  /// **'No late-night snacks'**
  String get workoutTypeDietAction;

  /// No description provided for @workoutTypeDietName.
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get workoutTypeDietName;

  /// No description provided for @workoutTypeOtherLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get workoutTypeOtherLabel;

  /// No description provided for @workoutTypeOtherName.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workoutTypeOtherName;

  /// Cycling inside a sentence: 오늘 🚴 {name} 했어?
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get workoutTypeCyclingName;

  /// Strength inside a sentence: Strength training done today?
  ///
  /// In en, this message translates to:
  /// **'Strength training'**
  String get workoutTypeStrengthName;

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
  /// **'How did it go? (optional)'**
  String get actionNoteHintDefault;

  /// No description provided for @planTimeUnset.
  ///
  /// In en, this message translates to:
  /// **'Time not set'**
  String get planTimeUnset;

  /// No description provided for @planDaysEveryday.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
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

  /// No description provided for @planCardMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Promise options'**
  String get planCardMenuTooltip;

  /// No description provided for @planCardEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get planCardEdit;

  /// No description provided for @planCardDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get planCardDelete;

  /// No description provided for @notifyEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifyEditorTitle;

  /// No description provided for @notifyEditorSubtitleOn.
  ///
  /// In en, this message translates to:
  /// **'We\'ll remind you at your promise time.'**
  String get notifyEditorSubtitleOn;

  /// No description provided for @notifyEditorSubtitleOff.
  ///
  /// In en, this message translates to:
  /// **'Track without notifications.'**
  String get notifyEditorSubtitleOff;

  /// No description provided for @notifyEditorPromiseTime.
  ///
  /// In en, this message translates to:
  /// **'Promise time your partner sees'**
  String get notifyEditorPromiseTime;

  /// No description provided for @notifyEditorDefaultTimeHint.
  ///
  /// In en, this message translates to:
  /// **'9 PM is a good default — there\'s still time to give each other props before the day ends.'**
  String get notifyEditorDefaultTimeHint;

  /// No description provided for @notifyEditorOffWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn off the reminder?'**
  String get notifyEditorOffWarningTitle;

  /// No description provided for @notifyEditorOffWarningBody.
  ///
  /// In en, this message translates to:
  /// **'Without a reminder there\'s no deadline, so {name} won\'t hear about a missed day.'**
  String notifyEditorOffWarningBody(String name);

  /// No description provided for @notifyEditorOffWarningConfirm.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get notifyEditorOffWarningConfirm;

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

  /// No description provided for @notifyEditorRepeatModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get notifyEditorRepeatModeLabel;

  /// No description provided for @notifyEditorRepeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Once a day'**
  String get notifyEditorRepeatDaily;

  /// No description provided for @notifyEditorRepeatHourly.
  ///
  /// In en, this message translates to:
  /// **'Every few hours'**
  String get notifyEditorRepeatHourly;

  /// No description provided for @notifyEditorIntervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get notifyEditorIntervalLabel;

  /// No description provided for @notifyEditorIntervalHours.
  ///
  /// In en, this message translates to:
  /// **'Every {count}h'**
  String notifyEditorIntervalHours(int count);

  /// No description provided for @notifyEditorWindowStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get notifyEditorWindowStart;

  /// No description provided for @notifyEditorWindowEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get notifyEditorWindowEnd;

  /// No description provided for @notifyEditorHourlyHint.
  ///
  /// In en, this message translates to:
  /// **'We\'ll remind you every {interval}h from {start}:00 to {end}:00.'**
  String notifyEditorHourlyHint(int interval, int start, int end);

  /// No description provided for @planTimeHourlyRange.
  ///
  /// In en, this message translates to:
  /// **'{start}:00–{end}:00 · every {interval}h'**
  String planTimeHourlyRange(int start, int end, int interval);

  /// No description provided for @promiseChipPenaltyTriggered.
  ///
  /// In en, this message translates to:
  /// **'Missed it — {description}'**
  String promiseChipPenaltyTriggered(String description);

  /// No description provided for @promiseChipPenaltyImminentOne.
  ///
  /// In en, this message translates to:
  /// **'One more miss and it\'s {description}'**
  String promiseChipPenaltyImminentOne(String description);

  /// No description provided for @promiseChipRewardAchieved.
  ///
  /// In en, this message translates to:
  /// **'Kept it! — {description}'**
  String promiseChipRewardAchieved(String description);

  /// No description provided for @promiseChipRewardImminent.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 more day} other{{days} more days}} to win — {description}'**
  String promiseChipRewardImminent(int days, String description);

  /// No description provided for @promiseChipSafeBoth.
  ///
  /// In en, this message translates to:
  /// **'{rewardDays, plural, =1{1 day} other{{rewardDays} days}} to win · {penaltyBuffer} more misses and the bet\'s on'**
  String promiseChipSafeBoth(int rewardDays, int penaltyBuffer);

  /// No description provided for @promiseChipSafeRewardOnly.
  ///
  /// In en, this message translates to:
  /// **'{days} days to win — {description}'**
  String promiseChipSafeRewardOnly(int days, String description);

  /// Chip: how many more missed days set off the bet (2 or more)
  ///
  /// In en, this message translates to:
  /// **'{buffer, plural, =1{One more miss} other{{buffer} more misses}} and it\'s {description}'**
  String promiseChipSafePenaltyOnly(int buffer, String description);

  /// No description provided for @promiseSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'The bet'**
  String get promiseSheetTitle;

  /// No description provided for @promiseSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Settled when the promise ends. So far {success} kept · {failed} missed · {remaining} to go.'**
  String promiseSheetSubtitle(int success, int failed, int remaining);

  /// No description provided for @promiseSheetRewardLabel.
  ///
  /// In en, this message translates to:
  /// **'If kept'**
  String get promiseSheetRewardLabel;

  /// No description provided for @promiseSheetPenaltyLabel.
  ///
  /// In en, this message translates to:
  /// **'If missed'**
  String get promiseSheetPenaltyLabel;

  /// No description provided for @promiseSheetRewardTarget.
  ///
  /// In en, this message translates to:
  /// **'Keep {target} days to win — {success} so far'**
  String promiseSheetRewardTarget(int target, int success);

  /// No description provided for @promiseSheetPenaltyImpossible.
  ///
  /// In en, this message translates to:
  /// **'{target, plural, =1{1 day} other{{target} days}} missed — the bet\'s on'**
  String promiseSheetPenaltyImpossible(int target);

  /// No description provided for @promiseSheetPenaltyJustOne.
  ///
  /// In en, this message translates to:
  /// **'On at {target} missed days — one more miss and it\'s on'**
  String promiseSheetPenaltyJustOne(int target);

  /// No description provided for @promiseSheetPenaltyBuffer.
  ///
  /// In en, this message translates to:
  /// **'On at {target} missed days — {buffer} more misses and it\'s on'**
  String promiseSheetPenaltyBuffer(int target, int buffer);

  /// No description provided for @promiseSheetClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get promiseSheetClose;

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
  /// **'Add a word (optional)'**
  String get historyCardFeedbackHint;

  /// No description provided for @historyCardFeedbackButton.
  ///
  /// In en, this message translates to:
  /// **'Props!'**
  String get historyCardFeedbackButton;

  /// No description provided for @historyCardAcknowledgePractice.
  ///
  /// In en, this message translates to:
  /// **'Partner props'**
  String get historyCardAcknowledgePractice;

  /// No description provided for @planSummaryMyDone.
  ///
  /// In en, this message translates to:
  /// **'Days I did it'**
  String get planSummaryMyDone;

  /// No description provided for @planSummaryPartnerVerified.
  ///
  /// In en, this message translates to:
  /// **'Partner props'**
  String get planSummaryPartnerVerified;

  /// No description provided for @planSummaryCount.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String planSummaryCount(int count);

  /// No description provided for @connectInviteCodeDetectedTitle.
  ///
  /// In en, this message translates to:
  /// **'We found an invite code you copied'**
  String get connectInviteCodeDetectedTitle;

  /// No description provided for @connectCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get connectCancel;

  /// No description provided for @connectNotice.
  ///
  /// In en, this message translates to:
  /// **'Heads up'**
  String get connectNotice;

  /// No description provided for @connectAlreadyConnectedBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re already connected with a partner.\nDuoDone connects you with one person at a time.'**
  String get connectAlreadyConnectedBody;

  /// No description provided for @connectOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get connectOk;

  /// No description provided for @allPlansTitleMine.
  ///
  /// In en, this message translates to:
  /// **'My promises'**
  String get allPlansTitleMine;

  /// No description provided for @allPlansTitlePartner.
  ///
  /// In en, this message translates to:
  /// **'Your partner\'s promises'**
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
  /// **'We couldn\'t delete that. Please try again.'**
  String get allPlansDeleteFailed;

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
  /// **'Something unexpected went wrong.'**
  String get historyErrorUnknown;

  /// No description provided for @historyErrorIndexMissing.
  ///
  /// In en, this message translates to:
  /// **'A database index is missing for this query.\nPlease screenshot this and send it to the developer.'**
  String get historyErrorIndexMissing;

  /// No description provided for @historyErrorAlreadyDeleted.
  ///
  /// In en, this message translates to:
  /// **'This record or promise was already deleted,\nso a reaction can\'t be left.'**
  String get historyErrorAlreadyDeleted;

  /// No description provided for @historyErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
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
  /// **'Fix a past record'**
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
  /// **'We couldn\'t save your profile. Please try again.'**
  String get usProfileSaveFailed;

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
  /// **'Your partner has no active promises'**
  String get usEmptyPartner;

  /// No description provided for @usCreatePlanShort.
  ///
  /// In en, this message translates to:
  /// **'+ Workout promise'**
  String get usCreatePlanShort;

  /// No description provided for @usCreatePlan.
  ///
  /// In en, this message translates to:
  /// **'Make a workout promise'**
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
  /// **'We couldn\'t delete that. Please try again.'**
  String get usDeleteFailed;

  /// No description provided for @usDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get usDelete;

  /// No description provided for @planDetailPracticeHistory.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get planDetailPracticeHistory;

  /// No description provided for @planDetailLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load records. Please try again.'**
  String get planDetailLoadFailed;

  /// No description provided for @planDetailNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No records yet.'**
  String get planDetailNoRecords;

  /// No description provided for @planDetailNotSavedPlan.
  ///
  /// In en, this message translates to:
  /// **'This promise isn\'t saved yet.'**
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
  /// **'Rest pass'**
  String get planDetailRecordRested;

  /// No description provided for @planDetailRecordRescued.
  ///
  /// In en, this message translates to:
  /// **'Partner props'**
  String get planDetailRecordRescued;

  /// No description provided for @planDetailPokeSent.
  ///
  /// In en, this message translates to:
  /// **'Knock sent to your partner.'**
  String get planDetailPokeSent;

  /// No description provided for @planDetailPokeFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send that. Please try again.'**
  String get planDetailPokeFailed;

  /// No description provided for @planDetailPokeDoneToday.
  ///
  /// In en, this message translates to:
  /// **'Knocked today'**
  String get planDetailPokeDoneToday;

  /// No description provided for @planDetailPokeSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get planDetailPokeSending;

  /// No description provided for @planDetailPokeAsk.
  ///
  /// In en, this message translates to:
  /// **'Send a knock'**
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
  /// **'Something went wrong. Please try again.'**
  String get planDetailActionFailed;

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
  /// **'\'{title}\' will count as missed today, and your partner will be told. Your streak together may reset.'**
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
  /// **'Great — it\'s on!'**
  String get nowApproveCheering;

  /// No description provided for @nowApproveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t accept.'**
  String get nowApproveFailed;

  /// No description provided for @nowRejectDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Want to tweak it a bit?'**
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
  /// **'I\'ll write my own'**
  String get nowRejectCustom;

  /// No description provided for @nowRejectRequested.
  ///
  /// In en, this message translates to:
  /// **'Sent your suggestion'**
  String get nowRejectRequested;

  /// No description provided for @nowRejectCustomDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'What would you change?'**
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

  /// No description provided for @nowCheerFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send cheer.'**
  String get nowCheerFailed;

  /// No description provided for @nowPokeNoActivityMessage.
  ///
  /// In en, this message translates to:
  /// **'Knock knock! Make a workout promise — I\'ve got your back 🙂'**
  String get nowPokeNoActivityMessage;

  /// No description provided for @nowPokeSent.
  ///
  /// In en, this message translates to:
  /// **'Knock sent.'**
  String get nowPokeSent;

  /// No description provided for @nowPokeFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the knock.'**
  String get nowPokeFailed;

  /// No description provided for @nowPokeAgainMessage.
  ///
  /// In en, this message translates to:
  /// **'Knock knock! Waiting on today\'s promise 🙂'**
  String get nowPokeAgainMessage;

  /// No description provided for @nowPokeAgainSent.
  ///
  /// In en, this message translates to:
  /// **'Knock sent to your partner.'**
  String get nowPokeAgainSent;

  /// No description provided for @nowSettlementSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved your 4-week wrap-up.'**
  String get nowSettlementSaved;

  /// No description provided for @nowExitDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Wrap up this 4-week round here?'**
  String get nowExitDialogTitle;

  /// No description provided for @nowExitReasonWeakPoke.
  ///
  /// In en, this message translates to:
  /// **'Knocks didn\'t really help'**
  String get nowExitReasonWeakPoke;

  /// No description provided for @nowExitReasonTooBig.
  ///
  /// In en, this message translates to:
  /// **'The goal was too big'**
  String get nowExitReasonTooBig;

  /// No description provided for @nowExitReasonPartnerBurden.
  ///
  /// In en, this message translates to:
  /// **'Backing each other felt like a lot'**
  String get nowExitReasonPartnerBurden;

  /// No description provided for @nowExitReasonCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get nowExitReasonCustomLabel;

  /// No description provided for @nowExitReasonCustomHint.
  ///
  /// In en, this message translates to:
  /// **'Optionally, a brief note on wrapping up'**
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
  /// **'Use this week\'s rest pass.\nYour streak stays intact.'**
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
  /// **'Something went wrong.'**
  String get nowRestPassError;

  /// No description provided for @nowRescuedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Props given! Their streak lives on.'**
  String get nowRescuedSnackbar;

  /// No description provided for @nowRescueFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t give props.'**
  String get nowRescueFailed;

  /// No description provided for @nowPromiseAccepted.
  ///
  /// In en, this message translates to:
  /// **'Bet\'s on! 🤝'**
  String get nowPromiseAccepted;

  /// No description provided for @nowPromiseDeclined.
  ///
  /// In en, this message translates to:
  /// **'Passed on this bet.'**
  String get nowPromiseDeclined;

  /// No description provided for @nowPromiseResponseFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t answer the bet.'**
  String get nowPromiseResponseFailed;

  /// No description provided for @nowPromiseProposed.
  ///
  /// In en, this message translates to:
  /// **'Bet proposed!'**
  String get nowPromiseProposed;

  /// No description provided for @nowPromiseProposeFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t propose the bet.'**
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

  /// No description provided for @nowErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
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
  /// **'Your partner\'s promise'**
  String get nowPartnerActionFallback;

  /// No description provided for @nowActionNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a word (optional)'**
  String get nowActionNoteHint;

  /// No description provided for @nowVerifyAndSend.
  ///
  /// In en, this message translates to:
  /// **'Give props & send'**
  String get nowVerifyAndSend;

  /// No description provided for @nowStreakCount.
  ///
  /// In en, this message translates to:
  /// **'{count} in a row!'**
  String nowStreakCount(int count);

  /// No description provided for @nowHeaderAdjustNeeded.
  ///
  /// In en, this message translates to:
  /// **'Adjustment needed'**
  String get nowHeaderAdjustNeeded;

  /// No description provided for @nowHeaderPromiseProposed.
  ///
  /// In en, this message translates to:
  /// **'A bet proposal arrived'**
  String get nowHeaderPromiseProposed;

  /// No description provided for @nowHeaderPromiseSettled.
  ///
  /// In en, this message translates to:
  /// **'The bet result is in'**
  String get nowHeaderPromiseSettled;

  /// No description provided for @nowPromiseAckButton.
  ///
  /// In en, this message translates to:
  /// **'See the result'**
  String get nowPromiseAckButton;

  /// No description provided for @nowPromiseAckDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Bet result'**
  String get nowPromiseAckDialogTitle;

  /// No description provided for @nowPromiseAckDialogHint.
  ///
  /// In en, this message translates to:
  /// **'A word for your partner (optional)'**
  String get nowPromiseAckDialogHint;

  /// No description provided for @nowPromiseAckDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get nowPromiseAckDialogConfirm;

  /// No description provided for @nowPromiseAckSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Result checked'**
  String get nowPromiseAckSnackbar;

  /// No description provided for @nowPromiseAckFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t confirm the result'**
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
  /// **'Rest pass'**
  String get planDetailLegendRested;

  /// No description provided for @planDetailLegendRescued.
  ///
  /// In en, this message translates to:
  /// **'Props'**
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
  /// **'Weekly completion'**
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
  /// **'Bet progress'**
  String get planDetailPromiseProgressTitle;

  /// No description provided for @planDetailPromiseRewardLabel.
  ///
  /// In en, this message translates to:
  /// **'🏆 If kept'**
  String get planDetailPromiseRewardLabel;

  /// No description provided for @planDetailPromisePenaltyLabel.
  ///
  /// In en, this message translates to:
  /// **'⚡ If missed'**
  String get planDetailPromisePenaltyLabel;

  /// No description provided for @planDetailPromiseRewardNeed.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 more day} other{{days} more days}} to win'**
  String planDetailPromiseRewardNeed(int days);

  /// No description provided for @planDetailPromiseRewardAchieved.
  ///
  /// In en, this message translates to:
  /// **'🎉 Kept it!'**
  String get planDetailPromiseRewardAchieved;

  /// No description provided for @planDetailPromisePenaltyBuffer.
  ///
  /// In en, this message translates to:
  /// **'{buffer} more misses and the bet\'s on'**
  String planDetailPromisePenaltyBuffer(int buffer);

  /// No description provided for @planDetailPromisePenaltyImminent.
  ///
  /// In en, this message translates to:
  /// **'One more miss and the bet\'s on'**
  String get planDetailPromisePenaltyImminent;

  /// No description provided for @planDetailPromisePenaltyTriggered.
  ///
  /// In en, this message translates to:
  /// **'⚡ Missed · the bet\'s on'**
  String get planDetailPromisePenaltyTriggered;

  /// No description provided for @planDetailMoreMenu.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get planDetailMoreMenu;

  /// No description provided for @planDetailMenuRestartCompleted.
  ///
  /// In en, this message translates to:
  /// **'New promise from this one'**
  String get planDetailMenuRestartCompleted;

  /// No description provided for @planDetailMenuRestartActive.
  ///
  /// In en, this message translates to:
  /// **'Restart with new schedule'**
  String get planDetailMenuRestartActive;

  /// No description provided for @planDetailMenuStop.
  ///
  /// In en, this message translates to:
  /// **'Stop promise'**
  String get planDetailMenuStop;

  /// No description provided for @planDetailPromiseSuccessFailBreakdown.
  ///
  /// In en, this message translates to:
  /// **'{success} kept · {fail} missed'**
  String planDetailPromiseSuccessFailBreakdown(int success, int fail);

  /// No description provided for @nowHeaderSettlementNeeded.
  ///
  /// In en, this message translates to:
  /// **'Your 4 weeks are up'**
  String get nowHeaderSettlementNeeded;

  /// No description provided for @nowHeaderSettlementSub.
  ///
  /// In en, this message translates to:
  /// **'Look back on these 4 weeks and decide on the next round.'**
  String get nowHeaderSettlementSub;

  /// No description provided for @nowMetricCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get nowMetricCompleted;

  /// No description provided for @nowMetricPartnerReact.
  ///
  /// In en, this message translates to:
  /// **'Partner props'**
  String get nowMetricPartnerReact;

  /// No description provided for @nowMetricMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed days'**
  String get nowMetricMissed;

  /// No description provided for @nowMetricDaysSuffix.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String nowMetricDaysSuffix(int count);

  /// No description provided for @nowMetricCountSuffix.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 time} other{{count} times}}'**
  String nowMetricCountSuffix(int count);

  /// No description provided for @nowSettlementWinMessage.
  ///
  /// In en, this message translates to:
  /// **'You hit the goal you set. Nicely done! Decide whether to keep going for another 4 weeks.'**
  String get nowSettlementWinMessage;

  /// No description provided for @nowSettlementLoseMessage.
  ///
  /// In en, this message translates to:
  /// **'You didn\'t quite reach the goal this time, but the 4 weeks you shared still count. Decide what to adjust for the next round.'**
  String get nowSettlementLoseMessage;

  /// No description provided for @nowSettlementNeutralMessage.
  ///
  /// In en, this message translates to:
  /// **'You made it through the whole 4 weeks together. Decide whether to go another round.'**
  String get nowSettlementNeutralMessage;

  /// No description provided for @nowRewardCondition.
  ///
  /// In en, this message translates to:
  /// **'Keep {days} days: {description}'**
  String nowRewardCondition(int days, String description);

  /// No description provided for @nowPenaltyCondition.
  ///
  /// In en, this message translates to:
  /// **'Miss {days} days: {description}'**
  String nowPenaltyCondition(int days, String description);

  /// No description provided for @nowPromiseResult.
  ///
  /// In en, this message translates to:
  /// **'{success} kept / {fail} missed'**
  String nowPromiseResult(int success, int fail);

  /// No description provided for @nowAchieved.
  ///
  /// In en, this message translates to:
  /// **'Achieved!'**
  String get nowAchieved;

  /// No description provided for @nowTriggered.
  ///
  /// In en, this message translates to:
  /// **'It\'s on!'**
  String get nowTriggered;

  /// No description provided for @nowNotMet.
  ///
  /// In en, this message translates to:
  /// **'Not met'**
  String get nowNotMet;

  /// No description provided for @nowDecline.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get nowDecline;

  /// No description provided for @nowAccept.
  ///
  /// In en, this message translates to:
  /// **'I\'m in!'**
  String get nowAccept;

  /// No description provided for @nowContinueNext4Weeks.
  ///
  /// In en, this message translates to:
  /// **'Start the next 4 weeks'**
  String get nowContinueNext4Weeks;

  /// No description provided for @nowStopHere.
  ///
  /// In en, this message translates to:
  /// **'Wrap up this 4-week round here'**
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

  /// No description provided for @nowHeaderTodayAllDone.
  ///
  /// In en, this message translates to:
  /// **'All done for today 🎉'**
  String get nowHeaderTodayAllDone;

  /// Partner card header: the partner recorded today. name: nickname ?? display name ?? Your partner
  ///
  /// In en, this message translates to:
  /// **'{name} did it! Give them props?'**
  String nowHeaderConfirmAndPull(String name);

  /// No description provided for @nowHeaderWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name}\'s promise'**
  String nowHeaderWaiting(String name);

  /// No description provided for @nowHeaderWaitingAccept.
  ///
  /// In en, this message translates to:
  /// **'Waiting for them to accept the bet'**
  String get nowHeaderWaitingAccept;

  /// No description provided for @nowHeaderPromiseResult.
  ///
  /// In en, this message translates to:
  /// **'The bet result is in'**
  String get nowHeaderPromiseResult;

  /// No description provided for @nowAdjust.
  ///
  /// In en, this message translates to:
  /// **'Let\'s tweak it'**
  String get nowAdjust;

  /// No description provided for @nowApprove.
  ///
  /// In en, this message translates to:
  /// **'Sounds good!'**
  String get nowApprove;

  /// No description provided for @nowPartnerNoNewPlanGuide.
  ///
  /// In en, this message translates to:
  /// **'Your partner hasn\'t made a workout promise yet. Send a knock to start together?'**
  String get nowPartnerNoNewPlanGuide;

  /// No description provided for @nowKnockMakePlan.
  ///
  /// In en, this message translates to:
  /// **'Knock! Let\'s do this together'**
  String get nowKnockMakePlan;

  /// No description provided for @nowPartnerMissedPokeBody.
  ///
  /// In en, this message translates to:
  /// **'{name} hasn\'t done today\'s promise yet. Send a cheer?'**
  String nowPartnerMissedPokeBody(String name);

  /// No description provided for @nowPartnerQuietPokeBody.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s promise is still quiet. Send a knock to say you\'re waiting?'**
  String nowPartnerQuietPokeBody(String name);

  /// No description provided for @nowKnockPull.
  ///
  /// In en, this message translates to:
  /// **'Send a knock'**
  String get nowKnockPull;

  /// No description provided for @nowRescueYesterday.
  ///
  /// In en, this message translates to:
  /// **'Give props for yesterday'**
  String get nowRescueYesterday;

  /// No description provided for @nowVerifyAndCheer.
  ///
  /// In en, this message translates to:
  /// **'Give props'**
  String get nowVerifyAndCheer;

  /// No description provided for @nowMakePromise.
  ///
  /// In en, this message translates to:
  /// **'Make a bet'**
  String get nowMakePromise;

  /// No description provided for @nowPartnerFallback2.
  ///
  /// In en, this message translates to:
  /// **'Your partner'**
  String get nowPartnerFallback2;

  /// No description provided for @nowPartnerAllDone.
  ///
  /// In en, this message translates to:
  /// **'{name} kept every promise today 🎉'**
  String nowPartnerAllDone(String name);

  /// No description provided for @nowQuickCheckHelp.
  ///
  /// In en, this message translates to:
  /// **'Giving props keeps them going tomorrow.'**
  String get nowQuickCheckHelp;

  /// No description provided for @nowLastAction.
  ///
  /// In en, this message translates to:
  /// **'Last check-in: {title}'**
  String nowLastAction(String title);

  /// No description provided for @nowRewardLine.
  ///
  /// In en, this message translates to:
  /// **'🏆 Keep {days} days: {description}'**
  String nowRewardLine(int days, String description);

  /// No description provided for @nowPenaltyLine.
  ///
  /// In en, this message translates to:
  /// **'⚡ Miss {days} days: {description}'**
  String nowPenaltyLine(int days, String description);

  /// No description provided for @nowResultLine.
  ///
  /// In en, this message translates to:
  /// **'Result: {success} kept / {fail} missed'**
  String nowResultLine(int success, int fail);

  /// No description provided for @nowWaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval…'**
  String get nowWaitingApproval;

  /// No description provided for @nowRewardAchievedTitle.
  ///
  /// In en, this message translates to:
  /// **'🎉 Kept it!'**
  String get nowRewardAchievedTitle;

  /// No description provided for @nowPenaltyTriggeredTitle.
  ///
  /// In en, this message translates to:
  /// **'⚡ The bet\'s on!'**
  String get nowPenaltyTriggeredTitle;

  /// No description provided for @nowBothTitle.
  ///
  /// In en, this message translates to:
  /// **'🎉 Kept it! + ⚡ The bet\'s on!'**
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
  /// **'A {days}-day promise · {scheduled} days scheduled'**
  String nowTotalDaysScheduled(int days, int scheduled);

  /// No description provided for @nowMakePromiseTitle.
  ///
  /// In en, this message translates to:
  /// **'Make a bet'**
  String get nowMakePromiseTitle;

  /// No description provided for @nowMakePromiseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The bet starts once your partner accepts. Bet treats and chores, not money.'**
  String get nowMakePromiseSubtitle;

  /// No description provided for @nowProgressLine.
  ///
  /// In en, this message translates to:
  /// **'So far {success} kept · {failed} missed · {remaining} to go'**
  String nowProgressLine(int success, int failed, int remaining);

  /// No description provided for @nowMaxLimitsLine.
  ///
  /// In en, this message translates to:
  /// **'Set up to {reward} days to keep and up to {penalty} misses.'**
  String nowMaxLimitsLine(int reward, int penalty);

  /// No description provided for @nowRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'🏆 If kept'**
  String get nowRewardTitle;

  /// No description provided for @nowRewardHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 🍣 sushi date, you pick the movie'**
  String get nowRewardHint;

  /// No description provided for @nowRewardTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Days to keep'**
  String get nowRewardTargetLabel;

  /// No description provided for @nowPenaltyTitle.
  ///
  /// In en, this message translates to:
  /// **'⚡ If missed'**
  String get nowPenaltyTitle;

  /// No description provided for @nowPenaltyHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 🍗 buy the chicken, dishes for a week'**
  String get nowPenaltyHint;

  /// No description provided for @nowPenaltyTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Miss limit'**
  String get nowPenaltyTargetLabel;

  /// No description provided for @nowProposePromise.
  ///
  /// In en, this message translates to:
  /// **'Propose the bet'**
  String get nowProposePromise;

  /// No description provided for @nowDaysSuffix.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
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

  /// No description provided for @nowNoteDateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get nowNoteDateToday;

  /// No description provided for @connectErrorSelfCode.
  ///
  /// In en, this message translates to:
  /// **'You can\'t use your own invite code.'**
  String get connectErrorSelfCode;

  /// No description provided for @connectErrorFailed.
  ///
  /// In en, this message translates to:
  /// **'That code is invalid, or the connection failed.'**
  String get connectErrorFailed;

  /// No description provided for @connectErrorDisconnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t disconnect. Please try again.'**
  String get connectErrorDisconnectFailed;

  /// No description provided for @accountLinkErrorAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This account is already linked to another user.'**
  String get accountLinkErrorAlreadyInUse;

  /// No description provided for @accountLinkErrorInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'The credentials are invalid.'**
  String get accountLinkErrorInvalidCredential;

  /// No description provided for @accountLinkErrorNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This operation isn\'t allowed.'**
  String get accountLinkErrorNotAllowed;

  /// No description provided for @accountLinkErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while linking your account.'**
  String get accountLinkErrorGeneric;

  /// No description provided for @planCreateErrorNoUser.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find your account. Please sign in again.'**
  String get planCreateErrorNoUser;

  /// No description provided for @notifyBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off'**
  String get notifyBannerTitle;

  /// No description provided for @notifyBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Turn them on so you don\'t miss your partner\'s props and knocks.'**
  String get notifyBannerBody;

  /// No description provided for @notifyBannerAction.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get notifyBannerAction;

  /// No description provided for @nowActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get nowActionFailed;

  /// No description provided for @usNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name.'**
  String get usNameRequired;

  /// No description provided for @usImagePickFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t use that image. Please try another one.'**
  String get usImagePickFailed;

  /// No description provided for @settingsLogoutFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t sign you out. Please try again.'**
  String get settingsLogoutFailed;

  /// No description provided for @settingsDeletingAccount.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account…'**
  String get settingsDeletingAccount;

  /// No description provided for @authErrorInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'That email or password isn\'t right.'**
  String get authErrorInvalidCredential;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find that account.'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'That email is already signed up.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That email address isn\'t valid.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Please use a password of at least 6 characters.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again in a moment.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Please try again.'**
  String get authErrorGeneric;

  /// No description provided for @tutorialSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tutorialSkip;

  /// No description provided for @tutorialClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get tutorialClose;

  /// No description provided for @tutorialNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tutorialNext;

  /// No description provided for @tutorialStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get tutorialStart;

  /// No description provided for @tutorialFooter.
  ///
  /// In en, this message translates to:
  /// **'One workout promise is all it takes to start.'**
  String get tutorialFooter;

  /// No description provided for @tutorialPage1Title.
  ///
  /// In en, this message translates to:
  /// **'Make a workout promise'**
  String get tutorialPage1Title;

  /// No description provided for @tutorialPage1Body.
  ///
  /// In en, this message translates to:
  /// **'Gym, running, home workouts — pick what and when, then promise it to your partner. It\'s much harder to skip than a promise to yourself.'**
  String get tutorialPage1Body;

  /// No description provided for @tutorialPage2Title.
  ///
  /// In en, this message translates to:
  /// **'Your partner sees it, and gives props'**
  String get tutorialPage2Title;

  /// No description provided for @tutorialPage2Body.
  ///
  /// In en, this message translates to:
  /// **'Snap a proof photo after your workout and your partner sees it right away. One tap from them is props — and they\'ll knock on the days you forget.'**
  String get tutorialPage2Body;

  /// No description provided for @tutorialPage3Title.
  ///
  /// In en, this message translates to:
  /// **'Both done? That\'s DuoDone'**
  String get tutorialPage3Title;

  /// No description provided for @tutorialPage3Body.
  ///
  /// In en, this message translates to:
  /// **'When you both work out, that\'s a DuoDone day. Watch the days you\'ve stacked up together.'**
  String get tutorialPage3Body;

  /// No description provided for @appUpdateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get appUpdateRequiredTitle;

  /// No description provided for @appUpdateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'This version is no longer supported. Update to the latest version to keep going.'**
  String get appUpdateRequiredBody;

  /// No description provided for @appUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get appUpdateButton;

  /// No description provided for @appUpdateSoftTitle.
  ///
  /// In en, this message translates to:
  /// **'A new version is here'**
  String get appUpdateSoftTitle;

  /// No description provided for @appUpdateSoftBody.
  ///
  /// In en, this message translates to:
  /// **'Update to get the latest features and fixes.'**
  String get appUpdateSoftBody;

  /// No description provided for @appUpdateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get appUpdateLater;

  /// No description provided for @appUpdateStoreOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the store. Please update from the store app.'**
  String get appUpdateStoreOpenFailed;

  /// Header on my rejected plan card: the partner asked to adjust it
  ///
  /// In en, this message translates to:
  /// **'Your partner suggested a tweak'**
  String get nowHeaderPartnerAskedAdjust;

  /// Header on my poked card when the knock carries no message
  ///
  /// In en, this message translates to:
  /// **'Knock knock! Your partner is waiting'**
  String get nowHeaderPokeWaiting;

  /// Header on my card after the missed-promise notice went to my partner
  ///
  /// In en, this message translates to:
  /// **'No check-in yet today, so {name} got a heads-up'**
  String nowHeaderMissedNotice(String name);

  /// Header on the partner card after their missed-promise notice
  ///
  /// In en, this message translates to:
  /// **'{name}\'s promise is still open today'**
  String nowHeaderPartnerMissed(String name);

  /// Header on the partner card when a knock would help
  ///
  /// In en, this message translates to:
  /// **'Your turn to send a knock'**
  String get nowHeaderPokeTurn;

  /// Neutral fallback title when a plan or record has no title (may be a legacy non-workout plan)
  ///
  /// In en, this message translates to:
  /// **'Promise'**
  String get promiseUntitledFallback;

  /// Length of a finished plan in weeks
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week} other{{count} weeks}}'**
  String planSummaryWeeks(int count);

  /// Settings row that replays the tutorial
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get settingsTutorialTitle;

  /// Subtitle of the settings row that replays the tutorial
  ///
  /// In en, this message translates to:
  /// **'See again how workout promises and props work'**
  String get settingsTutorialDesc;

  /// Notification action button: mark today's promise done
  ///
  /// In en, this message translates to:
  /// **'Did it'**
  String get notifActionDidIt;

  /// Notification action button: skip today's promise
  ///
  /// In en, this message translates to:
  /// **'Skip today'**
  String get notifActionSkipToday;

  /// Notification action button: snooze 10 minutes
  ///
  /// In en, this message translates to:
  /// **'Remind me in 10 min'**
  String get notifActionSnooze;

  /// Button on a partner's proof push: one-tap 인정 (opens the app and sends it)
  ///
  /// In en, this message translates to:
  /// **'❤️ Give props'**
  String get notifActionProps;

  /// Button on a partner's missed-workout push: send encouragement (opens the app and sends it)
  ///
  /// In en, this message translates to:
  /// **'💪 Send a cheer'**
  String get notifActionCheer;

  /// Body of the local promise reminder (title is the promise). Neutral: may be a legacy non-workout plan
  ///
  /// In en, this message translates to:
  /// **'One check-in and today is logged 📸'**
  String get notifReminderBody;

  /// Title for a push that arrives without one
  ///
  /// In en, this message translates to:
  /// **'DuoDone'**
  String get notifFallbackTitle;

  /// Android notification channel name
  ///
  /// In en, this message translates to:
  /// **'Promise reminders'**
  String get notifChannelRemindersName;

  /// Android notification channel description
  ///
  /// In en, this message translates to:
  /// **'Reminders at the times you set for your promises'**
  String get notifChannelRemindersDesc;

  /// Android notification channel name
  ///
  /// In en, this message translates to:
  /// **'Partner updates'**
  String get notifChannelGeneralName;

  /// Android notification channel description
  ///
  /// In en, this message translates to:
  /// **'Props, knocks, and cheers from your partner'**
  String get notifChannelGeneralDesc;

  /// Android notification channel name
  ///
  /// In en, this message translates to:
  /// **'Scheduled reminders'**
  String get notifChannelScheduledName;

  /// Android notification channel description
  ///
  /// In en, this message translates to:
  /// **'Notifications at a time you picked'**
  String get notifChannelScheduledDesc;

  /// Android notification channel name (debug tools)
  ///
  /// In en, this message translates to:
  /// **'Test notifications'**
  String get notifChannelDebugName;

  /// Android notification channel description (debug tools)
  ///
  /// In en, this message translates to:
  /// **'For testing notifications'**
  String get notifChannelDebugDesc;

  /// Now-tab hero question for a workout promise, e.g. 오늘 🏃 러닝 했어?
  ///
  /// In en, this message translates to:
  /// **'{emoji} {workout} done today?'**
  String nowHeroQuestion(String emoji, String workout);

  /// Now-tab hero question for a diet promise (not a workout)
  ///
  /// In en, this message translates to:
  /// **'{emoji} {workout} on track today?'**
  String nowHeroQuestionDiet(String emoji, String workout);

  /// Now-tab hero question for a promise from before the pivot (no workout type)
  ///
  /// In en, this message translates to:
  /// **'Did you do \'{title}\' today?'**
  String nowHeroQuestionLegacy(String title);

  /// Primary hero button: report with a proof photo
  ///
  /// In en, this message translates to:
  /// **'📸 Take a proof photo'**
  String get nowProofTakePhoto;

  /// Main check-in button for a promise from before the pivot (no workout type)
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get nowHeroVerifyLegacy;

  /// Secondary hero button: report without a photo (partner-to-partner tone)
  ///
  /// In en, this message translates to:
  /// **'Did it, no photo'**
  String get nowDidItNoPhoto;

  /// Title of the camera/album picker sheet
  ///
  /// In en, this message translates to:
  /// **'Add a proof photo'**
  String get proofSourceSheetTitle;

  /// Camera option in the proof photo picker (default)
  ///
  /// In en, this message translates to:
  /// **'📸 Take with camera'**
  String get proofSourceCamera;

  /// Subtitle under the camera option
  ///
  /// In en, this message translates to:
  /// **'Shows as just taken'**
  String get proofSourceCameraHint;

  /// Album option in the proof photo picker
  ///
  /// In en, this message translates to:
  /// **'🖼️ Choose from album'**
  String get proofSourceGallery;

  /// Subtitle under the album option
  ///
  /// In en, this message translates to:
  /// **'Shows as an album photo with its date'**
  String get proofSourceGalleryHint;

  /// One-time consent sheet title shown before the first proof photo
  ///
  /// In en, this message translates to:
  /// **'Before your first proof photo'**
  String get proofConsentTitle;

  /// Consent sheet line: who can see proof photos
  ///
  /// In en, this message translates to:
  /// **'Only your partner can see it.'**
  String get proofConsentOnlyPartner;

  /// Consent sheet line: EXIF/GPS is stripped
  ///
  /// In en, this message translates to:
  /// **'Location and other photo info are removed before upload.'**
  String get proofConsentLocationRemoved;

  /// Consent sheet line: what happens after disconnecting
  ///
  /// In en, this message translates to:
  /// **'If you disconnect, it can no longer be seen in the app.'**
  String get proofConsentAfterDisconnect;

  /// Consent sheet line: content rule
  ///
  /// In en, this message translates to:
  /// **'Please don\'t upload inappropriate photos.'**
  String get proofConsentNoInappropriate;

  /// Consent sheet confirm button
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get proofConsentAgree;

  /// Title of the preview sheet after picking a proof photo
  ///
  /// In en, this message translates to:
  /// **'Send this proof?'**
  String get proofPreviewTitle;

  /// Preview sheet button that reports with the photo
  ///
  /// In en, this message translates to:
  /// **'Send proof'**
  String get proofPreviewSubmit;

  /// Snackbar after a report with a photo
  ///
  /// In en, this message translates to:
  /// **'Proof photo sent 📸'**
  String get proofUploadDone;

  /// Snackbar when the photo upload failed or timed out but the record was saved
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload the photo, but today\'s record is saved.'**
  String get proofUploadFailed;

  /// Snackbar when a picked photo can't be decoded
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t use that photo. Please try another one.'**
  String get proofPhotoPrepareFailed;

  /// Snackbar when the image picker fails (e.g. permission denied)
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the camera or album.'**
  String get proofPickFailed;

  /// Badge on a proof photo taken with the in-app camera today
  ///
  /// In en, this message translates to:
  /// **'📸 Just taken · {time}'**
  String proofBadgeCamera(String time);

  /// Badge on a camera proof photo without a capture time
  ///
  /// In en, this message translates to:
  /// **'📸 Just taken'**
  String get proofBadgeCameraJustNow;

  /// Badge on a camera proof photo from an earlier day; when is like 9/28 19:42
  ///
  /// In en, this message translates to:
  /// **'📸 Camera · {when}'**
  String proofBadgeCameraOn(String when);

  /// Badge on an album proof photo with its original capture date (M/D)
  ///
  /// In en, this message translates to:
  /// **'🖼️ Album · taken {date}'**
  String proofBadgeGalleryTaken(String date);

  /// Badge on an album proof photo without a known capture date
  ///
  /// In en, this message translates to:
  /// **'🖼️ Album'**
  String get proofBadgeGallery;

  /// Proof photo error state
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the photo'**
  String get proofPhotoLoadFailed;

  /// Retry action on the proof photo error state
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get proofPhotoRetry;

  /// Accessibility label of a proof photo
  ///
  /// In en, this message translates to:
  /// **'Proof photo'**
  String get proofPhotoSemantics;

  /// Tooltip of the proof photo viewer menu
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get proofViewerMenu;

  /// Viewer menu: report the photo by email
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get proofViewerReport;

  /// Viewer menu (owner only): delete the proof photo
  ///
  /// In en, this message translates to:
  /// **'Delete photo'**
  String get proofViewerDelete;

  /// Delete confirmation title
  ///
  /// In en, this message translates to:
  /// **'Delete this proof photo?'**
  String get proofDeleteConfirmTitle;

  /// Delete confirmation body
  ///
  /// In en, this message translates to:
  /// **'Your partner won\'t see it anymore. The record itself stays.'**
  String get proofDeleteConfirmBody;

  /// Delete confirmation button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get proofDeleteConfirm;

  /// Snackbar after deleting a proof photo
  ///
  /// In en, this message translates to:
  /// **'Proof photo deleted.'**
  String get proofDeleted;

  /// Snackbar when deleting a proof photo failed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the photo. Please try again.'**
  String get proofDeleteFailed;

  /// Subject of the report email draft
  ///
  /// In en, this message translates to:
  /// **'[DuoDone] Report a proof photo'**
  String get proofReportSubject;

  /// Body of the report email draft
  ///
  /// In en, this message translates to:
  /// **'Please tell us what\'s wrong with this photo.\n\nRecord ID: {actionId}'**
  String proofReportBody(String actionId);

  /// Snackbar when no mail app could open the report draft
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open your mail app. Please email us at {email}.'**
  String proofReportMailFailed(String email);

  /// Hint above the one-tap reaction row on the partner card
  ///
  /// In en, this message translates to:
  /// **'One tap gives props'**
  String get nowReactHint;

  /// Link next to the reaction row that opens the note dialog
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get nowReactAddNote;

  /// Accessibility label of a one-tap reaction button
  ///
  /// In en, this message translates to:
  /// **'Give props with {emoji}'**
  String nowReactSemantics(String emoji);

  /// Snackbar after a one-tap reaction
  ///
  /// In en, this message translates to:
  /// **'Props sent {emoji}'**
  String nowReactedSnackbar(String emoji);

  /// What the partner is called when there is no nickname and no display name
  ///
  /// In en, this message translates to:
  /// **'your partner'**
  String get partnerFallbackLabel;

  /// The partner without a nickname or name, at the start of a line or sentence (en capitalized)
  ///
  /// In en, this message translates to:
  /// **'Your partner'**
  String get partnerFallbackLabelStart;

  /// Primary button: opens the system share sheet with the invite message
  ///
  /// In en, this message translates to:
  /// **'Send an invite'**
  String get connectShareInvite;

  /// Secondary button: copies my invite code
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get connectCopyCode;

  /// Heading above the code entry on the invite screen
  ///
  /// In en, this message translates to:
  /// **'Got a code from your partner?'**
  String get connectHaveCodeTitle;

  /// Snackbar after the invite was shared
  ///
  /// In en, this message translates to:
  /// **'Invite sent. We\'ll let you know when your partner joins.'**
  String get connectInviteSent;

  /// Snackbar when the share sheet could not open
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the share sheet. Copy the code and send it instead.'**
  String get connectShareFailed;

  /// Error when no user holds the entered invite code
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find anyone with that code. Please check it and try again.'**
  String get connectErrorCodeNotFound;

  /// Error when the entered code is not 8 letters/digits
  ///
  /// In en, this message translates to:
  /// **'Codes are 8 letters and numbers.'**
  String get connectErrorCodeFormat;

  /// The link was undone: the code's owner already has a partner
  ///
  /// In en, this message translates to:
  /// **'That code\'s owner is already connected to someone. Ask them for a new code.'**
  String get connectErrorOwnerTaken;

  /// The link was undone: I already have a partner
  ///
  /// In en, this message translates to:
  /// **'You\'re already connected to a partner. Disconnect first, then try again.'**
  String get connectErrorSelfTaken;

  /// The link was undone: the code was replaced
  ///
  /// In en, this message translates to:
  /// **'That code has changed. Ask your partner for the new one.'**
  String get connectErrorCodeChanged;

  /// The link went away right after it was made (reason unknown)
  ///
  /// In en, this message translates to:
  /// **'The connection didn\'t hold. The code may belong to someone who\'s already connected — ask for a new code.'**
  String get connectErrorLinkUndone;

  /// Invite message shared to the partner (couple tone) when I already have a workout promise. It comes from me, so it never names me.
  ///
  /// In en, this message translates to:
  /// **'I made a workout promise 🤙 Back me up! Get DuoDone and enter code {code} to connect → {link}'**
  String inviteShareMessage(String code, String link);

  /// Invite message when I have no workout promise yet.
  ///
  /// In en, this message translates to:
  /// **'I\'m making a workout promise 🤙 Back me up! Get DuoDone and enter code {code} to connect → {link}'**
  String inviteShareMessageNoPromise(String code, String link);

  /// Subject line used by share targets that support one (e.g. email)
  ///
  /// In en, this message translates to:
  /// **'DuoDone invite'**
  String get inviteShareSubject;

  /// Small link for invited users: skips ahead to code entry
  ///
  /// In en, this message translates to:
  /// **'I got an invite code'**
  String get inviteHaveCodeLink;

  /// Confirm sheet before connecting: name is the code owner
  ///
  /// In en, this message translates to:
  /// **'Back {name}\'s workout promises?'**
  String connectConfirmTitle(String name);

  /// Body of the connect confirm sheet
  ///
  /// In en, this message translates to:
  /// **'Once connected, you\'ll see each other\'s workout promises and proof photos.'**
  String get connectConfirmBody;

  /// Confirm button (partner-to-partner tone): connect with the code owner
  ///
  /// In en, this message translates to:
  /// **'I\'ve got you'**
  String get connectConfirmAccept;

  /// Success state after connecting
  ///
  /// In en, this message translates to:
  /// **'You\'re connected with {name} 🎉'**
  String connectSuccessTitle(String name);

  /// Body of the success state
  ///
  /// In en, this message translates to:
  /// **'Now you can back each other\'s workout promises.'**
  String get connectSuccessBody;

  /// Asks the newly connected invitee to make their own promise
  ///
  /// In en, this message translates to:
  /// **'Make one too?'**
  String get connectSuccessAskTitle;

  /// Body under connectSuccessAskTitle
  ///
  /// In en, this message translates to:
  /// **'When you both do it, that\'s DuoDone.'**
  String get connectSuccessAskBody;

  /// Button: open the workout promise screen
  ///
  /// In en, this message translates to:
  /// **'Make mine'**
  String get connectSuccessMakePromise;

  /// Button: go home without making a promise
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get connectSuccessLater;

  /// Button on the success state for the person who shared the code
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get connectSuccessDone;

  /// Heading of the three-step loop explainer on the connect success state (invitees skip the tutorial)
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get connectHowTitle;

  /// Loop step 1 on the connect success state
  ///
  /// In en, this message translates to:
  /// **'Work out, then post a proof photo'**
  String get connectHowProof;

  /// Loop step 2 on the connect success state: the one-tap acknowledgement (인정)
  ///
  /// In en, this message translates to:
  /// **'One tap on your partner\'s photo gives them props'**
  String get connectHowAck;

  /// Loop step 3 on the connect success state
  ///
  /// In en, this message translates to:
  /// **'A day you both work out is a DuoDone day'**
  String get connectHowDuo;

  /// Title of the nickname sheet
  ///
  /// In en, this message translates to:
  /// **'What do you call your partner?'**
  String get nicknameSheetTitle;

  /// Body of the nickname sheet; name is the partner display name
  ///
  /// In en, this message translates to:
  /// **'We\'ll show this instead of {name} in the app and notifications.'**
  String nicknameSheetBody(String name);

  /// Nickname preset (default)
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get nicknamePresetPartner;

  /// Nickname preset
  ///
  /// In en, this message translates to:
  /// **'Babe'**
  String get nicknamePresetJagi;

  /// Nickname preset
  ///
  /// In en, this message translates to:
  /// **'Honey'**
  String get nicknamePresetOppa;

  /// Nickname preset
  ///
  /// In en, this message translates to:
  /// **'Love'**
  String get nicknamePresetYeobo;

  /// Nickname preset
  ///
  /// In en, this message translates to:
  /// **'Baby'**
  String get nicknamePresetAegi;

  /// Nickname chip that opens a text field
  ///
  /// In en, this message translates to:
  /// **'Type my own'**
  String get nicknamePresetCustom;

  /// Hint of the custom nickname field
  ///
  /// In en, this message translates to:
  /// **'Nickname (up to 10 characters)'**
  String get nicknameCustomHint;

  /// Save the nickname
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get nicknameSave;

  /// Close the nickname sheet without saving
  ///
  /// In en, this message translates to:
  /// **'I\'ll decide later'**
  String get nicknameLater;

  /// Remove the current nickname
  ///
  /// In en, this message translates to:
  /// **'Remove nickname'**
  String get nicknameRemove;

  /// Snackbar after saving a nickname
  ///
  /// In en, this message translates to:
  /// **'Nickname saved.'**
  String get nicknameSaved;

  /// Snackbar after removing a nickname
  ///
  /// In en, this message translates to:
  /// **'Nickname removed.'**
  String get nicknameRemoved;

  /// Snackbar when saving the nickname failed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the nickname. Please try again.'**
  String get nicknameSaveFailed;

  /// Partner card action when no nickname is set
  ///
  /// In en, this message translates to:
  /// **'Set a nickname'**
  String get usSetNickname;

  /// Partner card action when a nickname is set
  ///
  /// In en, this message translates to:
  /// **'Change nickname'**
  String get usEditNickname;

  /// Skip link on the post-login invite step
  ///
  /// In en, this message translates to:
  /// **'I\'ll invite later'**
  String get onboardingInviteLater;

  /// Now tab card while there is no partner
  ///
  /// In en, this message translates to:
  /// **'You actually do it when your partner sees it'**
  String get nowInviteCardTitle;

  /// Body of the Now tab invite card
  ///
  /// In en, this message translates to:
  /// **'Send an invite so you can back each other\'s workout promises.'**
  String get nowInviteCardBody;

  /// Now tab invite card after an invite was shared
  ///
  /// In en, this message translates to:
  /// **'Waiting for your partner'**
  String get nowInviteCardWaitingTitle;

  /// Body of the waiting invite card
  ///
  /// In en, this message translates to:
  /// **'They haven\'t joined yet. Send it again?'**
  String get nowInviteCardWaitingBody;

  /// Resend button on the waiting invite card
  ///
  /// In en, this message translates to:
  /// **'Send it again'**
  String get nowInviteCardResend;

  /// One-time notice for existing users: the app was renamed. Must name the old app.
  ///
  /// In en, this message translates to:
  /// **'Nod&Try is now DuoDone'**
  String get pivotNoticeTitle;

  /// Body of the one-time rename notice
  ///
  /// In en, this message translates to:
  /// **'Your promises, history and partner connection are all still here.'**
  String get pivotNoticeBody;

  /// Dismiss button of the rename notice
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get pivotNoticeOk;

  /// Duo streak headline (Now header, Us hero)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Together for 1 day} other{Together for {count} days}}'**
  String duoStreakDays(int count);

  /// Duo headline while the streak is 0
  ///
  /// In en, this message translates to:
  /// **'Both check in today for day 1'**
  String get duoStreakStart;

  /// Shown when today is a duo day (both kept their promises)
  ///
  /// In en, this message translates to:
  /// **'You both did it today 🎉'**
  String get duoTodayDone;

  /// Label for myself in duo status rows
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get duoMeLabel;

  /// Duo status: done today
  ///
  /// In en, this message translates to:
  /// **'done ✓'**
  String get duoStatusDone;

  /// Duo status: done and the partner gave props (인정)
  ///
  /// In en, this message translates to:
  /// **'props ❤️'**
  String get duoStatusVerified;

  /// Duo status: done, partner's props (인정) still pending
  ///
  /// In en, this message translates to:
  /// **'awaiting props'**
  String get duoStatusWaiting;

  /// Duo status: scheduled today, not recorded yet
  ///
  /// In en, this message translates to:
  /// **'not yet'**
  String get duoStatusPending;

  /// Duo status: rest pass used
  ///
  /// In en, this message translates to:
  /// **'rest pass'**
  String get duoStatusRested;

  /// Duo status: nothing scheduled
  ///
  /// In en, this message translates to:
  /// **'day off'**
  String get duoStatusOff;

  /// Duo status: a past scheduled day without a record
  ///
  /// In en, this message translates to:
  /// **'missed'**
  String get duoStatusMissed;

  /// Duo status: a future scheduled day
  ///
  /// In en, this message translates to:
  /// **'coming up'**
  String get duoStatusUpcoming;

  /// One person's status chip: name (or Me) then the status word
  ///
  /// In en, this message translates to:
  /// **'{name} · {status}'**
  String duoPersonStatus(String name, String status);

  /// Duo days so far this week
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No duo days yet} =1{1 duo day} other{{count} duo days}}'**
  String duoWeekDuoDays(int count);

  /// Screen-reader label of one day in the weekly duo dots
  ///
  /// In en, this message translates to:
  /// **'{day}: me {me}, partner {partner}'**
  String duoDaySemantics(String day, String me, String partner);

  /// Us tab button that opens the share card
  ///
  /// In en, this message translates to:
  /// **'Make a share card'**
  String get duoShareButton;

  /// Share card headline
  ///
  /// In en, this message translates to:
  /// **'#DuoDone {count}-day streak'**
  String shareCardStreak(int count);

  /// Share card headline without a streak
  ///
  /// In en, this message translates to:
  /// **'#DuoDone'**
  String get shareCardNoStreak;

  /// Share card footer
  ///
  /// In en, this message translates to:
  /// **'Search \'DuoDone\' in your app store'**
  String get shareCardStores;

  /// Share card line: a person and the workout they did
  ///
  /// In en, this message translates to:
  /// **'{name} ✓ {workout}'**
  String shareCardPersonDone(String name, String workout);

  /// Share card line: nothing scheduled
  ///
  /// In en, this message translates to:
  /// **'{name} · day off'**
  String shareCardPersonOff(String name);

  /// Share card line: rest pass
  ///
  /// In en, this message translates to:
  /// **'{name} · rest pass'**
  String shareCardPersonRested(String name);

  /// Share card line: not recorded yet
  ///
  /// In en, this message translates to:
  /// **'{name} · not yet'**
  String shareCardPersonPending(String name);

  /// Share card sheet title when today became a duo day
  ///
  /// In en, this message translates to:
  /// **'You both did it today 🎉 Show it off?'**
  String get shareCardSheetTitleToday;

  /// Share card sheet title on a 3/7/30-day streak
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} days together 🎉 Show it off?}}'**
  String shareCardSheetTitleMilestone(int count);

  /// Share card sheet title from the Us tab
  ///
  /// In en, this message translates to:
  /// **'Share card'**
  String get shareCardSheetTitleManual;

  /// Share card sheet primary button
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareCardShare;

  /// Share card sheet dismiss button
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get shareCardLater;

  /// Share card capture or share failed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t make the share card.'**
  String get shareCardFailed;

  /// Share card sheet note: the partner's photo is never included
  ///
  /// In en, this message translates to:
  /// **'Only your own photo goes on the card.'**
  String get shareCardOnlyMyPhoto;

  /// Text sent along with the share card image
  ///
  /// In en, this message translates to:
  /// **'#DuoDone When your partner sees it, you actually do it.'**
  String get shareCardText;

  /// Screen-reader label of the share card
  ///
  /// In en, this message translates to:
  /// **'DuoDone share card'**
  String get shareCardSemantics;

  /// One-tap reply to a knock (partner-to-partner tone)
  ///
  /// In en, this message translates to:
  /// **'On my way 🏃'**
  String get nowPokeReplyComing;

  /// One-tap reply to a knock (partner-to-partner tone)
  ///
  /// In en, this message translates to:
  /// **'Go easy on me 🙏'**
  String get nowPokeReplyPass;

  /// Snackbar / label after replying to a knock
  ///
  /// In en, this message translates to:
  /// **'Reply sent'**
  String get nowPokeReplySent;

  /// Knock reply failed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the reply.'**
  String get nowPokeReplyFailed;

  /// Primary button on a partner's missed-workout card
  ///
  /// In en, this message translates to:
  /// **'Send a cheer'**
  String get nowSendCheer;

  /// Cheer text sent from the missed-workout card (partner-to-partner tone)
  ///
  /// In en, this message translates to:
  /// **'You\'ve got this! I\'m waiting 💪'**
  String get nowCheerDefaultMessage;

  /// Snackbar after sending a cheer
  ///
  /// In en, this message translates to:
  /// **'Cheer sent'**
  String get nowCheerSent;

  /// Disabled knock button: one knock per promise per day
  ///
  /// In en, this message translates to:
  /// **'Knocked today'**
  String get nowKnockSentToday;

  /// Bet chip (if missed)
  ///
  /// In en, this message translates to:
  /// **'🍗 Buy the chicken'**
  String get promisePenaltyChicken;

  /// Bet chip (if missed)
  ///
  /// In en, this message translates to:
  /// **'☕ Buy the iced coffee'**
  String get promisePenaltyCoffee;

  /// Bet chip (if missed)
  ///
  /// In en, this message translates to:
  /// **'🍽️ Dishes for a week'**
  String get promisePenaltyDishes;

  /// Bet chip (if missed)
  ///
  /// In en, this message translates to:
  /// **'💆 10-minute massage'**
  String get promisePenaltyMassage;

  /// Bet chip (if missed)
  ///
  /// In en, this message translates to:
  /// **'🎬 They pick the movie'**
  String get promisePenaltyMovie;

  /// Bet chip (if missed)
  ///
  /// In en, this message translates to:
  /// **'🚗 Pick-up duty'**
  String get promisePenaltyPickup;

  /// Bet chip (if kept)
  ///
  /// In en, this message translates to:
  /// **'🍣 Omakase together'**
  String get promiseRewardOmakase;

  /// Bet chip (if kept)
  ///
  /// In en, this message translates to:
  /// **'🍰 Dessert date'**
  String get promiseRewardDessert;

  /// Bet chip (if kept)
  ///
  /// In en, this message translates to:
  /// **'💆 A 10-minute massage'**
  String get promiseRewardMassage;

  /// Bet chip (if kept)
  ///
  /// In en, this message translates to:
  /// **'🎬 You pick the movie'**
  String get promiseRewardMovie;

  /// Shown under a bet that mentions money; saving is blocked
  ///
  /// In en, this message translates to:
  /// **'Money bets aren\'t supported. Bet something you can do together, like a meal, coffee or the dishes.'**
  String get promiseMoneyBlocked;

  /// Deadline reminder body for a promise with a partner. Never promise exact minutes.
  ///
  /// In en, this message translates to:
  /// **'No check-in yet? We\'ll let {name} know soon.'**
  String notifReminderBodyWithPartner(String name);

  /// Snackbar: the record was saved offline and will sync
  ///
  /// In en, this message translates to:
  /// **'Saved. It\'ll reach your partner once you\'re back online.'**
  String get nowRecordQueued;

  /// Settings section with the privacy policy, terms and support
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutSection;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsTermsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get settingsTermsOfUse;

  /// No description provided for @settingsContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get settingsContactSupport;

  /// Subject of the support email draft
  ///
  /// In en, this message translates to:
  /// **'[DuoDone] Support'**
  String get settingsContactSupportSubject;

  /// No description provided for @settingsLinkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open it. You can reach us at {email}.'**
  String settingsLinkOpenFailed(String email);

  /// Partner card menu: report the partner's content or behavior
  ///
  /// In en, this message translates to:
  /// **'Report partner'**
  String get usReportPartner;

  /// No description provided for @usReportPartnerSubject.
  ///
  /// In en, this message translates to:
  /// **'[DuoDone] Report a partner'**
  String get usReportPartnerSubject;

  /// No description provided for @usReportPartnerBody.
  ///
  /// In en, this message translates to:
  /// **'Tell us what\'s wrong (a photo, note or message). We\'ll review it and act.\n\nReported account ID: {uid}'**
  String usReportPartnerBody(String uid);

  /// No description provided for @termsViewLink.
  ///
  /// In en, this message translates to:
  /// **'View terms of use'**
  String get termsViewLink;

  /// Clickwrap on the invite confirm sheet (Guideline 1.2)
  ///
  /// In en, this message translates to:
  /// **'By connecting you agree to the Terms of Use. Objectionable content and abusive behavior aren\'t tolerated — reported content and accounts are removed.'**
  String get termsNoticeConnect;

  /// Clickwrap under the invite share button
  ///
  /// In en, this message translates to:
  /// **'Sending an invite means you agree to the Terms of Use. Objectionable content and abuse aren\'t tolerated.'**
  String get termsNoticeInvite;

  /// Clickwrap on the first-photo consent sheet
  ///
  /// In en, this message translates to:
  /// **'By posting you agree to the Terms of Use. Objectionable photos and abuse aren\'t tolerated.'**
  String get termsNoticePhoto;

  /// Sheet after the first solo promise is saved
  ///
  /// In en, this message translates to:
  /// **'Promise made! Ask your partner to back you up?'**
  String get planSavedInviteTitle;

  /// No description provided for @planSavedInviteBody.
  ///
  /// In en, this message translates to:
  /// **'With your partner watching, you\'ll actually do it. Send them your code and link.'**
  String get planSavedInviteBody;
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
