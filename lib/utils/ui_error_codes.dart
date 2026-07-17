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
}

class SettingsErrorCode {
  static const withdrawFailed = 'settings_withdraw_failed';
  static const logoutFailed = 'settings_logout_failed';
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
