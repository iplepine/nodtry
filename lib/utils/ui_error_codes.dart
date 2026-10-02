/// Stable, locale-independent error codes that view models store in state and
/// widgets map to localized strings.
///
/// View models are Riverpod notifiers with no `BuildContext`, so they can't
/// reach `AppLocalizations`. Previously they stored hard-coded Korean sentences
/// directly in state, which then rendered as-is for English users. Storing a
/// code here and resolving it at the widget layer keeps all user-facing copy in
/// the ARB files.
class ConnectErrorCode {
  static const selfCode = 'connect_self_code';
  static const connectFailed = 'connect_failed';
  static const disconnectFailed = 'connect_disconnect_failed';

  /// No user holds the entered code.
  static const codeNotFound = 'connect_code_not_found';

  /// The entered text is not 8 letters/digits.
  static const codeFormat = 'connect_code_format';

  /// The server undid the link: the code's owner already has a partner.
  static const ownerTaken = 'connect_owner_taken';

  /// The server undid the link: I already have a partner.
  static const selfTaken = 'connect_self_taken';

  /// The server undid the link: the code was replaced since it was shared.
  static const codeChanged = 'connect_code_changed';

  /// The link went away right after it was made, reason unknown (most often
  /// the code's owner already has a partner).
  static const linkUndone = 'connect_link_undone';

  /// The error for a `partner_connect_failed` push's `data.reason`.
  static String forFailureReason(String? reason) {
    switch (reason) {
      case 'owner_taken':
        return ownerTaken;
      case 'self_taken':
        return selfTaken;
      case 'invalid_code':
        return codeChanged;
      default:
        return linkUndone;
    }
  }
}

class SettingsErrorCode {
  static const withdrawFailed = 'settings_withdraw_failed';
  static const logoutFailed = 'settings_logout_failed';

  /// The user backed out of signing in again; nothing was deleted.
  static const withdrawReauthCancelled = 'settings_withdraw_reauth_cancelled';

  /// The password entered to confirm the deletion was wrong.
  static const withdrawWrongPassword = 'settings_withdraw_wrong_password';
}

class AuthErrorCode {
  static const invalidCredential = 'auth_invalid_credential';
  static const userNotFound = 'auth_user_not_found';
  static const emailInUse = 'auth_email_in_use';
  static const invalidEmail = 'auth_invalid_email';
  static const weakPassword = 'auth_weak_password';
  static const tooManyRequests = 'auth_too_many_requests';
  static const network = 'auth_network';
  static const generic = 'auth_generic';
}

class AccountLinkErrorCode {
  static const alreadyInUse = 'link_already_in_use';
  static const invalidCredential = 'link_invalid_credential';
  static const notAllowed = 'link_not_allowed';
  static const generic = 'link_generic';
}
