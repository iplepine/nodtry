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
  String get homeNowTask => 'You have something to do now';

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
}
