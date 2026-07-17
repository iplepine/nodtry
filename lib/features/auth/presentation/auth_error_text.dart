import '../../../l10n/app_localizations.dart';
import '../../../utils/ui_error_codes.dart';

/// Maps a locale-independent [AuthErrorCode] to a localized message.
///
/// Shared by the splash and email login screens so a sign-in failure reads the
/// same either way. Both used to render `e.toString()` straight from the view
/// model, which put Firebase internals in front of the user.
String authErrorText(AppLocalizations l10n, String code) {
  switch (code) {
    case AuthErrorCode.invalidCredential:
      return l10n.authErrorInvalidCredential;
    case AuthErrorCode.userNotFound:
      return l10n.authErrorUserNotFound;
    case AuthErrorCode.emailInUse:
      return l10n.authErrorEmailInUse;
    case AuthErrorCode.invalidEmail:
      return l10n.authErrorInvalidEmail;
    case AuthErrorCode.weakPassword:
      return l10n.authErrorWeakPassword;
    case AuthErrorCode.tooManyRequests:
      return l10n.authErrorTooManyRequests;
    case AuthErrorCode.network:
      return l10n.authErrorNetwork;
    case AuthErrorCode.generic:
    default:
      return l10n.authErrorGeneric;
  }
}
