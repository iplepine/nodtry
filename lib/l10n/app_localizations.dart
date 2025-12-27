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
  /// **'You have something to do now'**
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
