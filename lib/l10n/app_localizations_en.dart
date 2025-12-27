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
      'We don\'t push. Your records are private between you two.';

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
}
